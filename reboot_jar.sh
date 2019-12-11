#!/bin/bash
# usage: ./[script].sh [project_home] [process_name] [java_opts, optional]
# eg: ./reboot_jar.sh /home/project/mama_config_server config-server "-Xms768m -Xmx768m"

# shellcheck disable=SC1090
source "$(dirname "${BASH_SOURCE[0]}")"/common.sh

# receive commandline parameters
PROJECT_HOME=$1
PROCESS_NAME=$2
JAVA_OPTS=$3

# to project home
cd "${PROJECT_HOME}" || if_failed "project home [${PROJECT_HOME}] not exists"
# if deployed file exists or not
file_full_name=$(find . -maxdepth 1 -name "*.jar" | awk '{print $NF}')
(
  [[ "${file_full_name}" != "" ]] && (
    # shellcheck disable=SC2206
    file_full_name_array=(${file_full_name})
    ((${#file_full_name_array[@]} > 1)) && if_failed "mulitiple files to deploy, current file_full_name is: ${file_full_name}, please check it manually" || :
  )
) || if_failed "none file will be deployed"

# kill the process
kill_process

# mark last success log time
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

# check if the application logput is successful or not
is_startup_success="false"
for ((i = 0; i < 30; i++)); do
  sleep 2
  success_log_time=$(tail -n 20 log.out | grep 'Tomcat started on port' | awk '{print $2}')
  if [ "${success_log_time}" != "" ] && [ "${success_log_time}" != "${last_success_log_time}" ]; then
    output_std "Startup SUCCESS!!"
    if_new_process
    is_startup_success="true"
    break
  fi
done
[[ "${is_startup_success}" != "true" ]] && (
  if_warn "Startup may be failed, please check it manually!"
)

# show last 100 lines of logfile
output_std "the last 100 lines of logfile are as follows:"
tail -n100 log.out
