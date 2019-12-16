#!/bin/bash

find_jar_result=$(find . -maxdepth 1 -name '*.jar'); if [ "${find_jar_result}" != "" ]; then echo "jar"; else echo "war"; fi

