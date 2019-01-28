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
      while [ "$?"x == 0x ]; do
        xautolock -exit
      done
      xautolock -time 10 -locker 'i3lock -c002b36 -e' -notify 30 -notifier 'notify-send -u normal -a xautolock -i /home/u/.config/awesome/themes/my/icons/lock_icon.png "Screen Locking" "WM will be locked after 30 seconds if no further operation."' -detectsleep > /dev/null 2>&1 &
      ;;
    acoff)
      xset s 600 600
      xset dpms 600 600 600
      true
      while [ "$?"x == 0x ]; do
        xautolock -exit
      done
      xautolock -time 10 -locker 'systemctl suspend' -notify 30 -notifier 'notify-send -u normal -a xautolock -i /home/u/.config/awesome/themes/my/icons/suspend_icon.png "Sys sleeping" "System will be suspended after 30 seconds if no further operation."' -detectsleep > /dev/null 2>&1 &
      ;;
    *)
      ;;
  esac
fi
