#!/bin/bash

# @Deprecated
find_jar_result=$(find . -maxdepth 1 -name '*.jar')
if [ "${find_jar_result}" != "" ]; then echo "jar"; else echo "war"; fi

tail -f 1.txt | grep --line-buffered 5 | kill -9 $(ps -ef | grep 'tail -f 1.txt' | awk '{print $2}') >/dev/null 2>&1

start_time=$(date +%s)
tail -f log.out | while read -r line; do
  echo "${line}"
  # shellcheck disable=SC2126
  num=$(echo "${line}" | grep -E 'Tomcat started on port|initialization completed in' | wc -l)
  end_time=$(date +%s)
  echo $end_time
  if [[ $num -ge 1 ]]; then
    echo "Found."
    break
  elif [[ ${end_time}-${start_time} -ge 20 ]]; then
    echo "Timeout.."
    break
  fi
done
