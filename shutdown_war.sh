#!/bin/bash
# usage: ./[script].sh [project_home] [process_name] [tomcat_dir_name, optional]
# eg: ./restart_war.sh /data/project/mama_www_cms mama_www_cms apache-tomcat-8.5.23

# shellcheck disable=SC1090
source "$(dirname "${BASH_SOURCE[0]}")"/common.sh

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
