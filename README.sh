#!/bin/bash

:<<EOF
当前文件执行权限（使可用./执行）
传入参数判断
每次都能CD到正确的目录
是否存在新的发布包
备份旧的发布包
停止应用
部署新的发布包
启动应用
查看启动日志
EOF

# 一般地，获取进程id的方式（当进程id唯一时；如果不唯一是合法的，那么取值temp_process_id_array即可）
function get_process_id() {
  temp_process_id=$(ps -ef | grep -w "${PROCESS_NAME}" | grep -v grep | awk '{print $2}')
  if [ "${temp_process_id}" != "" ]; then
    # 这里不可用引号，因为要转换为数组
    # shellcheck disable=SC2206
    temp_process_id_array=(${temp_process_id})
    if ((${#temp_process_id_array[@]} > 1)); then
      echo "ERROR: mulitiple processes, please check it manually"
      exit
    fi
  fi
}
# 排除当前脚本占用的进程，获取进程id的方式（当进程id唯一时）
function get_process_id() {
  # initialize
  temp_process_id=""
  temp_process_pid_ppid_strs=$(ps -ef | grep -w "${PROCESS_NAME}" | grep -v grep | awk '{pid_ppid=$2"-"$3; print pid_ppid}')
  if [ "${temp_process_pid_ppid_strs}" != "" ]; then
    # parse string to array, split with whitespace
    # shellcheck disable=SC2206
    temp_process_pid_ppid_array=(${temp_process_pid_ppid_strs})
    for ((i = 0; i < ${#temp_process_pid_ppid_array[@]}; i++)); do
      # parse string to array, split with '-'
      # shellcheck disable=SC2206
      each_process_pid_ppid_array=(${temp_process_pid_ppid_array[i]//-/ })
      # exclude current process whose pid or ppid equals $$
      if [ "${each_process_pid_ppid_array[0]}" != "$$" ] && [ "${each_process_pid_ppid_array[1]}" != "$$" ]; then
        if [ "${temp_process_id}" == "" ]; then
          temp_process_id=${each_process_pid_ppid_array[0]}
        else
          echo "ERROR: mulitiple processes, please check it manually"
          exit
        fi
      fi
    done
  fi
}
