#!/bin/bash
# sh [script].sh [project_home] [process_name] [java_opts]
# eg: ./restart_jar.sh /home/project/mama_config_server config-server "-Xms128m -Xmx768m"

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
    # sleep at most 5 seconds for waiting result
    for ((i = 0; i < 5; i++)); do
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
JAVA_OPTS=$3
PROCESS_NAME=$2

cd "${PROJECT_HOME}" || (
  echo "ERROR: project home ${PROJECT_HOME} not exists"
  exit
)
# TODO if new file exists
# backup
file_full_name=$(ls -l *.jar | awk '{print $NF}')
# TODO cp ${file_full_name} ${file_full_name}.$(date +%F)
# shutdown
get_process_id
if [ "${temp_process_id}" != "" ]; then
  kill_eventually
  # finally confirm
  get_process_id
  if [ "${temp_process_id}" != "" ]; then
    echo "ERROR: process ${PROCESS_NAME} with processId ${temp_process_id} shutdown failed, please check it manually"
    exit
  fi
fi
# deploy
# \ : not use alias
# TODO \cp -f jenkins/*.jar .
# startup
last_success_log_time=$(tail -n 20 log.out | grep 'Tomcat started on port' | awk '{print $2}')
# shellcheck disable=SC2086
nohup java ${JAVA_OPTS} -jar "${file_full_name}" 1>>log.out 2>errorlog.out &
# sleep 1 second to wait background errorlog is generated
sleep 1
[ "$(cat errorlog.out)" != "" ] && (
  echo "ERROR: Startup failed, error log: $(cat errorlog.out)"
  exit
)
echo "the background process is started, waiting for application startup..."
is_startup_success="false"
for ((i = 0; i < 30; i++)); do
  sleep 2
  success_log_time=$(tail -n 20 log.out | grep 'Tomcat started on port' | awk '{print $2}')
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
tail -n100 log.out
