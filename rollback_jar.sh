#!/bin/bash
# usage: ./[script].sh [project_home] [process_name] [java_opts] [backup_filename]
# eg: ./rollback_jar.sh /home/project/mama_config_server config-server "-Xms768m -Xmx768m" config-server-0.0.1-SNAPSHOT.jar.2019-11-01

# shellcheck disable=SC1090
source "$(dirname "${BASH_SOURCE[0]}")"/common.sh

# receive commandline parameters
PROJECT_HOME=$1
JAVA_OPTS=$3
PROCESS_NAME=$2
BACKUP_FILENAME=$4

# to be continued, this file may be desprecated, see README.md
