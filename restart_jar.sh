#!/bin/bash
# usage: ./[script].sh [project_home] [process_name] [java_opts, optional]
# eg: ./restart_jar.sh /home/project/mama_config_server config-server "-Xms768m -Xmx768m"
#
# current running .jar file in directory: ${PROJECT_HOME}/
# new .jar file in directory: ${PROJECT_HOME}/web/
# backup directory: ${PROJECT_HOME}/backup/

# shellcheck disable=SC1090
source "$(dirname "${BASH_SOURCE[0]}")"/common.sh

# receive commandline parameters
PROJECT_HOME=$1
PROCESS_NAME=$2
JAVA_OPTS=$3

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

# kill the process
kill_process

# deploy
output_std "move new .jar file to project home"
\cp -f web/*.jar .

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
start_time=$(date +%s)
tail -f log.out | while read -r line; do
  echo "${line}"
  # shellcheck disable=SC2126
  num=$(echo "${line}" | grep -E 'Tomcat started on port|initialization completed in' | wc -l)
  end_time=$(date +%s)
  if [[ $num -ge 1 ]]; then
    output_std "Startup SUCCESS!!"
    if_new_process
    break
  # timeout of 100 seconds
  elif [[ ${end_time}-${start_time} -ge 100 ]]; then
    if_warn "Startup may be failed, please check it manually!"
    break
  fi
done
