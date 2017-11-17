#!/usr/bin/bash
#

time=5

while true; do
  info=$(curl -sI 'www.163.com')
  if [ "${info}x" != x ]; then
    eval "dinfo=\$(systemctl is-active openconnect@${1})"
    if [ "${dinfo}x" != activex ]; then
      time=5
      eval "systemctl restart openconnect@${1}"
    else
      time=30
    fi
  fi
  sleep ${time}
done
