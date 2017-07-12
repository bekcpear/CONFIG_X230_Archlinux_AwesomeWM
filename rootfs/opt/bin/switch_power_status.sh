#!/usr/bin/bash
#
# TODO
#
# $1 -> user
# $2 -> stat

readonly cu='u'
echo $(id)

if [ "$1"x == "$cu"x ]; then
  case "$2" in
    acon)
      xset s 1200 1200
      xset dpms 1200 1200 1200
      true
      s=$?
      while [ "$s"x == 0x ]; do
        xautolock -exit
        s=$?
      done
      xautolock -time 10 -locker 'i3lock -c002b36 -e' -notify 30 -notifier 'notify-send -u normal -a xautolock -i /home/u/.config/awesome/themes/my/icons/lock_icon.png "Screen Lock" "Locking in 30 seconds if no further action."' > /dev/null 2>&1 &
      ;;
    acoff)
      xset s 600 600
      xset dpms 600 600 600
      true
      s=$?
      while [ "$s"x == 0x ]; do
        xautolock -exit
        s=$?
      done
      xautolock -time 10 -locker 'systemctl suspend' -notify 30 -notifier 'notify-send -u normal -a xautolock -i /home/u/.config/awesome/themes/my/icons/suspend_icon.png "Screen Lock" "Locking and suspending in 30 seconds if no further action."' > /dev/null 2>&1 &
      ;;
    *)
      ;;
  esac
fi
