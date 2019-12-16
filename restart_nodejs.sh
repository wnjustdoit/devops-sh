#!/bin/bash
# usage: ./[script].sh [project_home] [process_port]
# eg: ./restart_nodejs.sh /data/project/mama_xiaodian_front/mall_front 3002

# receive commandline parameters
PROJECT_HOME=$1
PROCESS_PORT=$2

# to project home
cd "${PROJECT_HOME}" || if_failed "project home [${PROJECT_HOME}] not exists"

is_startup_success='false'

# get process id and kill it
get_process_id_eventually
kill_eventually

# start process
start_msg=$(pm2 start npm --name xiaodian-fe -i 2 -- run start)
echo start_msg

echo 'startup SUCCESS!!'
echo 'the process list are as follows:'
pm2 list
