#!/bin/bash
# usage: ./[script].sh [filepath]
# eg: ./restart_jar.sh /home/project/mama_config_server config-server "-Xms768m -Xmx768m"
#
# current running .jar file in directory: ${PROJECT_HOME}/
# new .jar file in directory: ${PROJECT_HOME}/web/
# backup directory: ${PROJECT_HOME}/backup/

# functions
function get_process_id() {
  # shellcheck disable=SC2009
  temp_process_id=$(ps -ef | grep -w "${PROCESS_NAME}" | grep -v "grep" | grep -v "$0" | awk '{print $2}')
  [[ "${temp_process_id}" != "" ]] && (
    # shellcheck disable=SC2206
    temp_process_id_array=(${temp_process_id})
    ((${#temp_process_id_array[@]} > 1)) && if_failed "mulitiple processes, current temp_process_id is: ${temp_process_id}, please check it manually"
  )
}
function kill_normally() {
  get_process_id
  [[ "${temp_process_id}" != "" ]] && (
    output_std "kill normally, use [kill ${temp_process_id}] command"
    kill "${temp_process_id}"
    # sleep at most 5 seconds for waiting result back
    for ((i = 0; i < 5; i++)); do
      get_process_id
      [[ "${temp_process_id}" == "" ]] && break
      sleep 1
    done
  )
}
function kill_hardly() {
  get_process_id
  [[ "$temp_process_id" != "" ]] && (
    output_std "kill hardly, use [kill -9 ${temp_process_id}] command"
    kill -9 "${temp_process_id}"
  )
}
function kill_eventually() {
  kill_normally
  kill_hardly
}
function if_failed() {
  error_msg=$1
  [[ "${error_msg}" == "" ]] || echo "ERROR: ${error_msg}"
  exit
}
function if_warn() {
  warn_msg=$1
  [[ "${warn_msg}" == "" ]] || echo "WARN: ${warn_msg}"
}
function output_std() {
  msg=$1
  [[ "${msg}" == "" ]] || echo "INFO: ${msg}"
}

# receive commandline parameters
PROJECT_HOME=$1
JAVA_OPTS=$3
PROCESS_NAME=$2

# to project home
cd "${PROJECT_HOME}" || if_failed "project home [${PROJECT_HOME}] not exists"
# if new file exists or not
cd "${PROJECT_HOME}/web" || if_failed "folder [${PROJECT_HOME}/web] not exists"
file_full_name=$(find . -maxdepth 1 -name "*.jar" | awk '{print $NF}')
(
  [[ "${file_full_name}" != "" ]] && (
    # shellcheck disable=SC2206
    file_full_name_array=(${file_full_name})
    ((${#file_full_name_array[@]} > 1)) && if_failed "mulitiple files to deploy, current file_full_name is: ${file_full_name}, please check it manually" || :
  )
) || if_failed "none file will be deployed"

# backup
output_std ">>> starting backup..."
cd ../
\cp -f "${file_full_name}" "backup/${file_full_name}.$(date +%F)"
output_std ">>> backup ends"

# shutdown or kill
get_process_id
[[ "${temp_process_id}" != "" ]] && (
  kill_eventually
  # final confirmation
  get_process_id
  [[ "${temp_process_id}" != "" ]] && if_failed "process ${PROCESS_NAME} with processId ${temp_process_id} shutdown failed, please check it manually"
)

# deploy
output_std "move new .jar file to project home"
\cp -f web/*.jar .

if [ -f log.out ]; then
  last_success_log_time=$(tail -n 20 log.out | grep 'Tomcat started on port' | awk '{print $2}')
fi

# startup
output_std ">>> starting java process..."
# shellcheck disable=SC2086
nohup "${JAVA_HOME}"/bin/java ${JAVA_OPTS} -jar "${PROJECT_HOME}/${file_full_name}" 1>>log.out 2>errorlog.out &

# check if async subprocess execute sucessfully, at most 2 seconds
for ((i = 0; i < 2; i++)); do
  if [ "$(find . -maxdepth 1 -name "errorlog.out")" != "" ]; then
    [[ "$(cat errorlog.out)" != "" ]] && if_failed "Startup failed, error log: $(cat errorlog.out)"
    break
  fi
  sleep 1
done

output_std "<<< the background process is started, waiting for application startup..."

is_startup_success="false"
for ((i = 0; i < 30; i++)); do
  sleep 2
  success_log_time=$(tail -n 20 log.out | grep 'Tomcat started on port' | awk '{print $2}')
  if [ "${success_log_time}" != "" ] && [ "${success_log_time}" != "${last_success_log_time}" ]; then
    output_std "Startup SUCCESS!! The New Process Info is as follows:"
    # shellcheck disable=SC2009
    ps -ef | grep -w "${PROCESS_NAME}" | grep -v "grep" | grep -v "$0"
    is_startup_success="true"
    break
  fi
done
[[ "${is_startup_success}" != "true" ]] && (
  if_warn "Startup may be failed, please check it manually!"
)

# show last 100 lines log info
output_std "the last 100 lines log info are as follows:"
tail -n100 log.out
