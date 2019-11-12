#!/bin/bash
# common util
# functions
function output_std() {
  msg=$1
  [[ "${msg}" == "" ]] || echo -e "INFO: ${msg}"
}
function if_warn() {
  warn_msg=$1
  [[ "${warn_msg}" == "" ]] || echo -e "WARN: ${warn_msg}"
}
function if_error() {
  error_msg=$1
  [[ "${error_msg}" == "" ]] || echo -e "ERROR: ${error_msg}"
}
function if_failed() {
  error_msg=$1
  [[ "${error_msg}" == "" ]] || echo -e "ERROR: ${error_msg}"
  exit
}

function get_process_id() {
  # shellcheck disable=SC2009
  temp_process_id=$(ps -ef | grep -w "${PROCESS_NAME}" | grep -v "grep" | grep -v "$0" | awk '{print $2}')
  [[ "${temp_process_id}" != "" ]] && (
    # shellcheck disable=SC2206
    temp_process_id_array=(${temp_process_id})
    ((${#temp_process_id_array[@]} > 1)) && if_failed "mulitiple processes, current temp_process_id is: ${temp_process_id}, please check it manually"
  )
}
function show_process_info() {
  output_std "The Process Info:\n$(ps -ef | grep -w "${PROCESS_NAME}" | grep -v "grep" | grep -v "$0")"
}

function kill_normally() {
  get_process_id
  old_process_id=$temp_process_id
  if [ "${temp_process_id}" != "" ]; then
    output_std "kill normally, use [kill ${temp_process_id}] command"
    kill "${temp_process_id}"
    # sleep at most 5 seconds for waiting result back
    for ((i = 0; i < 5; i++)); do
      get_process_id
      [[ "${temp_process_id}" == "" ]] && break
      sleep 1
    done
  else
    if_warn "process id is not exists, ignore kill command"
  fi
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

function kill_process() {
  kill_eventually
  # final confirmation
  get_process_id
  [[ "${temp_process_id}" != "" ]] && if_failed "process ${PROCESS_NAME} with processId ${temp_process_id} shutdown failed, please check it manually"
}

function if_new_process() {
  get_process_id
  if [ "${temp_process_id}" != "" ]; then
    if [ "${old_process_id}" != "${temp_process_id}" ]; then
      output_std "The new process id is ${temp_process_id}, while the old one is ${old_process_id}"
    else
      if_error "The new process id ${temp_process_id} is the same to the old one!"
    fi
  else
    if_warn "The new process is not exists!"
  fi
}
