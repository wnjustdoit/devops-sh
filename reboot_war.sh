#!/bin/bash
# usage: ./[script].sh [project_home] [process_name] [tomcat_dir_name, optional]
# eg: ./reboot_war.sh /data/project/mama_www_cms mama_www_cms apache-tomcat-8.5.23

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
