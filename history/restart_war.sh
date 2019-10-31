#!/bin/bash
# sh [script].sh [project_home] [tomcat_dir_name] [process_name]
# eg: ./restart_war.sh /data/project/mama_www_cms apache-tomcat-8.5.23 mama_www_cms

# functions
# the prefix of map's key
prefix="pid_"
function map_put() {
  eval "$prefix$1=\"$2\""
}
function map_get() {
  eval "echo \$$prefix$1"
}
function recursion_is_self() {
  temp_is_self="false"
  if [ "$1" == $$ ] || [ "$2" == $$ ]; then
    temp_is_self="true"
  elif [ "$2" != "" ]; then
    recursion_is_self "$2" "$(map_get "$2")"
  fi
}
function get_process_id() {
  # initialize
  temp_process_id=""
  temp_process_pid_ppid_strs=$(ps -ef | grep -w "${PROCESS_NAME}" | grep -v grep | awk '{pid_ppid=$2"-"$3; print pid_ppid}')
  #  echo current processId is: $$ temp_process_pid_ppid_strs is: $temp_process_pid_ppid_strs
  if [ "${temp_process_pid_ppid_strs}" != "" ]; then
    # parse string to array, split with whitespace
    # shellcheck disable=SC2206
    temp_process_pid_ppid_array=(${temp_process_pid_ppid_strs})
    for ((i = 0; i < ${#temp_process_pid_ppid_array[@]}; i++)); do
      # parse string to array, split with '-'
      # shellcheck disable=SC2206
      each_process_pid_ppid_array=(${temp_process_pid_ppid_array[i]//-/ })
      map_put "${each_process_pid_ppid_array[0]}" "${each_process_pid_ppid_array[1]}"
    done
    for ((i = 0; i < ${#temp_process_pid_ppid_array[@]}; i++)); do
      # parse string to array, split with '-'
      # shellcheck disable=SC2206
      each_process_pid_ppid_array=(${temp_process_pid_ppid_array[i]//-/ })
      # exclude current process or its descendants
      recursion_is_self "${each_process_pid_ppid_array[0]}" "${each_process_pid_ppid_array[1]}"
      if [ "${temp_is_self}" == "false" ]; then
        if [ "${temp_process_id}" == "" ]; then
          temp_process_id=${each_process_pid_ppid_array[0]}
        else
          echo "ERROR: mulitiple processes, please check it manually"
          echo "Found new processId: ${each_process_pid_ppid_array[0]} conflicts with the old one: ${temp_process_id}, and temp_process_pid_ppid_strs is: ${temp_process_pid_ppid_strs}"
          exit
        fi
      fi
    done
  fi
}
function kill_normally() {
  get_process_id
  if [ "${temp_process_id}" != "" ]; then
    echo "kill normally, use [kill ${temp_process_id}] command"
    kill "${temp_process_id}"
    # sleep at most 10 seconds for waiting result(sometimes application does something at the end of its lifetime)
    for ((i = 0; i < 10; i++)); do
      get_process_id
      if [ "${temp_process_id}" == "" ]; then
        break
      fi
      sleep 1
    done
  fi
}
function kill_hardly() {
  get_process_id
  if [ "$temp_process_id" != "" ]; then
    echo "kill hardly, use [kill -9 ${temp_process_id}] command"
    kill -9 "${temp_process_id}"
  fi
}
function kill_eventually() {
  kill_normally
  kill_hardly
}

PROJECT_HOME=$1
TOMCAT_DIR_NAME=$2
PROCESS_NAME=$3

cd "${PROJECT_HOME}/${TOMCAT_DIR_NAME}" || (
  echo "ERROR: project home ${PROJECT_HOME} or tomcat dir name ${TOMCAT_DIR_NAME} not exists"
  exit
)
# if new file exists
[ -e ROOT.war ] || (
  echo "ERROR: new file ROOT.war is not exists"
  exit
)
# backup
cp webapps/ROOT.war webapps/ROOT.war."$(date +%F)"
# shutdown
get_process_id
if [ "${temp_process_id}" != "" ]; then
  # shutdown normally
  shutdown_log=$(./bin/shutdown.sh 2>&1)
  match_jmx_error_log=$(echo "${shutdown_log}" | grep 'bind failed: Address already in use ERROR')
  # special handle
  if [ "${match_jmx_error_log}" != "" ]; then
    kill_hardly
  else
    get_process_id
    if [ "${temp_process_id}" != "" ]; then
      kill_eventually
    else
      echo "tomcat shutdown normally, the old processId is: ${temp_process_id}"
    fi
  fi
  # finally confirm, actually check if command [kill -9 [processId]] takes effects
  get_process_id
  if [ "${temp_process_id}" != "" ]; then
    echo "ERROR: process ${PROCESS_NAME} with processId ${temp_process_id} shutdown failed, please check it manually"
    exit
  fi
fi
# deploy
# \ : not use alias
\cp -f ROOT.war webapps/
rm -rf webapps/ROOT
# startup
last_success_log_time=$(tail -n 20 logs/catalina.out | grep 'Server startup in' | awk '{print $2}')
tomcat_started_log=$(./bin/startup.sh 2>&1)
([[ "${tomcat_started_log}" =~ "Tomcat started" ]] && echo "tomcat started, waiting for application startup...") || (
  echo "ERROR: tomcat started failed"
  exit
)
is_startup_success="false"
for ((i = 0; i < 30; i++)); do
  sleep 2
  success_log_time=$(tail -n 20 logs/catalina.out | grep 'Server startup in' | awk '{print $2}')
  if [ "${success_log_time}" != "" ] && [ "${success_log_time}" != "${last_success_log_time}" ]; then
    echo "Startup SUCCESS!! The New Process Info is as follows:"
    ps -ef | grep -w "${PROCESS_NAME}" | grep -v grep
    echo "项目已发布成功！"
    is_startup_success="true"
    break
  fi
done
if [ "${is_startup_success}" != "true" ]; then
  echo "ERROR: Startup may be failed, please check it manually!"
  echo "TIPS: 发布时间最大为60秒，请检查日志的最后几行，确认是否超出发布时间范围，导致可能的\"发布失败\"。"
fi
# show last 100 lines log
echo "截止当前脚本执行结束时，应用的最后100行日志如下："
tail -n100 logs/catalina.out
