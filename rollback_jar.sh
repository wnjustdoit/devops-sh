#!/bin/bash
# usage: ./[script].sh [project_home] [process_name] [backup_filename] [java_opts, optional]
# eg: ./rollback_jar.sh /home/project/mama_config_server config-server config-server-0.0.1-SNAPSHOT.jar.2019-11-01 "-Xms768m -Xmx768m"

# shellcheck disable=SC1090
source "$(dirname "${BASH_SOURCE[0]}")"/common.sh

# receive commandline parameters
PROJECT_HOME=$1
JAVA_OPTS=$3
PROCESS_NAME=$2
BACKUP_FILENAME=$4

# TODO/Deprecated to be continued, this file may be desprecated, see README.md
