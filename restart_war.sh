#!/bin/bash
# usage: ./[script].sh [project_home] [process_name] [tomcat_dir_name, optional]
# eg: ./restart_war.sh /data/project/mama_www_cms mama_www_cms apache-tomcat-8.5.23
#
# current running .war file in directory: ${PROJECT_HOME}/${TOMCAT_DIR_NAME}/webapps/
# new .war file in directory: ${PROJECT_HOME}/web/
# backup directory: ${PROJECT_HOME}/backup/

# shellcheck disable=SC1090
source "$(dirname "${BASH_SOURCE[0]}")"/common.sh

# receive commandline parameters
PROJECT_HOME=$1
PROCESS_NAME=$2
TOMCAT_DIR_NAME=$3

# check parameters
if [ "${TOMCAT_DIR_NAME}" == "" ]; then
  TOMCAT_DIR_NAME="apache-tomcat-8.5.23"
fi

# to project home
cd "${PROJECT_HOME}" || if_failed "project home [${PROJECT_HOME}] not exists"
# if new file exists or not
cd "${PROJECT_HOME}/web" || if_failed "folder [${PROJECT_HOME}/web] not exists"
file_full_name=$(find . -maxdepth 1 -name "*.war" | awk '{print $NF}')
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
\cp -f "${TOMCAT_DIR_NAME}/webapps/ROOT.war" "backup/${file_full_name}.$(date +%F)"
output_std ">>> backup ends"

# shutdown or kill the process
get_process_id
# shellcheck disable=SC2154
if [ "${temp_process_id}" != "" ]; then
  # shutdown normally
  shutdown_log=$(./${TOMCAT_DIR_NAME}/bin/shutdown.sh 2>&1)
  match_jmx_error_log=$(echo "${shutdown_log}" | grep 'bind failed: Address already in use ERROR')
  # special handle
  if [ "${match_jmx_error_log}" != "" ]; then
    kill_hardly
  else
    kill_process
  fi
fi

# deploy
output_std "move new .war file to tomcat webapps dir"
\cp -f web/*.war "${TOMCAT_DIR_NAME}/webapps/"
rm -rf "${TOMCAT_DIR_NAME}/webapps/ROOT"

# mark last success log time
if [ -f "${TOMCAT_DIR_NAME}/logs/catalina.out" ]; then
  last_success_log_time=$(tail -n 20 "${TOMCAT_DIR_NAME}/logs/catalina.out" | grep 'Server startup in' | awk '{print $2}')
fi

# startup
output_std ">>> Starting Tomcat..."
# check if sync execution sucessfully
tomcat_started_log=$(./${TOMCAT_DIR_NAME}/bin/startup.sh 2>&1)
([[ "${tomcat_started_log}" =~ "Tomcat started" ]] && output_std "tomcat started, waiting for application startup...") || if_error "tomcat started failed"

# check if the tomcat catalina log output is successful or not
is_startup_success="false"
for ((i = 0; i < 30; i++)); do
  sleep 2
  # same as above
  success_log_time=$(tail -n 20 "${TOMCAT_DIR_NAME}/logs/catalina.out" | grep 'Server startup in' | awk '{print $2}')
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
output_std "the last 100 lines of tomcat catalina logfile are as follows:"
tail -n100 "${TOMCAT_DIR_NAME}/logs/catalina.out"
