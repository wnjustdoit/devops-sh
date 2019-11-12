#!/bin/bash
# usage: ./[script].sh [process_name]
# eg: ./shutdown.sh config-server

# shellcheck disable=SC1090
source "$(dirname "${BASH_SOURCE[0]}")"/common.sh

# receive commandline parameters
PROCESS_NAME=$1

# kill the process
kill_process

# output the application shutdown log..
