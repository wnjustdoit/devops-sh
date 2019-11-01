#!/bin/bash
# usage: ./[script].sh [process_name]
# eg: ./shutdown.sh config-server

source common.sh

# receive commandline parameters
PROCESS_NAME=$1

# kill the process
kill_process

# output the application shutdown log..
