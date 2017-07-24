#!/usr/bin/bash
#
# Written by Bekcpear <i@ume.ink>
# 
# swap COMMAND and NAME of systemctl(1), and the NAME is necessary
# Usage:
#   ssystemctl.sh [OPTIONS...] NAME COMMAND
#

sctl='/usr/bin/systemctl'

function alert() {
  echo
  echo 'This script is aimed to swap the COMMAND and NAME arguments of systemctl(1).'
  echo "Usage: $0 [OPTIONS...] NAME COMMAND"
  echo
  exit 1
}

opts=''
name=''
comm=''

while [ ${1}x != x ]; do
  if [[ ${1} =~ ^\- ]]; then
    opts=${opts}" "${1}
  else
    if [ ${comm}x == x ];then
      comm=${1}
    elif [ ${name}x == x ];then
      name=${1}
    else
      alert
    fi
  fi
  shift
done

[ ${name}x == x -o ${comm}x == x ] && alert

eval "${sctl} ${opts} ${name} ${comm}"
