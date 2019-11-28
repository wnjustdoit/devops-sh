#!/bin/bash
# usage: sh [script].sh [filepath]
# eg(chmod 755 restart_jar.sh): ./restart_jar.sh mama_config_server

# use [source file] to declare parameters
# compatible with macOS, macOS: greadlink while linux: readlink
# shellcheck disable=SC1090
# shellcheck disable=SC2046
([[ "$(uname)" == "Darwin" ]] && source $(greadlink -f $(dirname "$0"))/configs/"$1") ||
  source $(readlink -f $(dirname "$0"))/configs/"$1"

# functions
function get_process_id() {
  # shellcheck disable=SC2009
  temp_process_id=$(ps -ef | grep -w "${PROCESS_NAME}" | grep -v grep | awk '{print $2}')
  [[ "${temp_process_id}" != "" ]] && (
    # transform to array
    # shellcheck disable=SC2206
    temp_process_id_array=(${temp_process_id})
    ((${#temp_process_id_array[@]} > 1)) && if_failed "ERROR: mulitiple processes, current temp_process_id is: ${temp_process_id}, please check it manually"
  )
}
function kill_normally() {
  get_process_id
  [[ "${temp_process_id}" != "" ]] && (
    echo "INFO: kill normally, use [kill ${temp_process_id}] command"
    kill "${temp_process_id}"
    # sleep at most 5 seconds for waiting result
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
    echo "INFO: kill hardly, use [kill -9 ${temp_process_id}] command"
    kill -9 "${temp_process_id}"
  )
}
function kill_eventually() {
  kill_normally
  kill_hardly
}
function if_failed() {
  error_msg=$1
  [[ "${error_msg}" == "" ]] || echo "${error_msg}"
  exit
}
function if_warn() {
  warn_msg=$1
  [[ "${warn_msg}" == "" ]] || echo "${warn_msg}"
}
function output_std() {
  msg=$1
  [[ "${msg}" != "" ]] || echo "${msg}"
}

cd "${PROJECT_HOME}" || if_failed "ERROR: project home [${PROJECT_HOME}] not exists"
# if new file exists
cd "${PROJECT_HOME}/web" || if_failed "ERROR: folder [${PROJECT_HOME}/web] not exists"
file_full_name=$(find . -maxdepth 1 -name "*.jar" | awk '{print $NF}')
(
  [[ "${file_full_name}" != "" ]] && (
    file_full_name_array=(file_full_name)
    ((${#file_full_name_array[@]} > 1)) && if_failed "ERROR: mulitiple files to deploy, current file_full_name is: ${file_full_name}, please check it manually"
  )
) || if_failed "WARN: none file will be deployed"
# backup
cd ../
\cp -f "${file_full_name}" "backup/${file_full_name}.$(date +%F)"
# shutdown or kill
get_process_id
[[ "${temp_process_id}" != "" ]] && (
  kill_eventually
  # final confirmation
  get_process_id
  [[ "${temp_process_id}" != "" ]] && if_failed "ERROR: process ${PROCESS_NAME} with processId ${temp_process_id} shutdown failed, please check it manually"
)
# deploy
\cp -f web/*.jar .
# startup
last_success_log_time=$(tail -n 20 log.out | grep 'Tomcat started on port' | awk '{print $2}')
# shellcheck disable=SC2086
nohup ${JAVA_HOME}/bin/java ${JAVA_OPTS} -jar "${file_full_name}" 1>>log.out 2>errorlog.out &
for ((i = 0; i < 2; i++)); do
  if [ "$(find . -maxdepth 1 -name "errorlog.out")" != "" ]; then
    [[ "$(cat errorlog.out)" != "" ]] && if_failed "ERROR: Startup failed, error log: $(cat errorlog.out)"
    break
  fi
  sleep 1
done
echo "INFO: the background process is started, waiting for application startup..."
is_startup_success="false"
for ((i = 0; i < 30; i++)); do
  sleep 2
  success_log_time=$(tail -n 20 log.out | grep 'Tomcat started on port' | awk '{print $2}')
  if [ "${success_log_time}" != "" ] && [ "${success_log_time}" != "${last_success_log_time}" ]; then
    echo "INFO: Startup SUCCESS!! The New Process Info is as follows:"
    # shellcheck disable=SC2009
    ps -ef | grep -w "${PROCESS_NAME}" | grep -v grep
    is_startup_success="true"
    break
  fi
done
[[ "${is_startup_success}" != "true" ]] && (
  echo "ERROR: Startup may be failed, please check it manually!"
)
# show last 100 lines log info
echo "INFO: the last 100 lines log info are as follows:"
tail -n100 log.out
