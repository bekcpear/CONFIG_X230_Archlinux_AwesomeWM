#!/usr/bin/bash
#

RTBOOL=0

# check someone tool is existed or not
# Argument: $1 -> tool command
function testBin(){
  eval "local path=\$(which $1)"
  [ -f "$path" ] && \
    RTBOOL=1 || \
    RTBOOL=0
}

# handle vol
# Argument: $1 -> control
#           $2 -> step (unit is percent)
function hanVol(){
  testBin pactl
  if [ $RTBOOL -eq 1 ]; then
    local n=$(pactl info | grep 'Default Sink' | awk -F' ' '{printf $3}')
  fi
  local l=$(ps -e | grep pulseaudio | wc -l)
  if [[ $RTBOOL == 1 && $l =~ ^[0-9]+$ && $l > 0 ]]; then
    case "$1" in
      vol)
        eval "pactl set-sink-volume ${n} ${2}%"
        ;;
      inc)
        local v=$(pactl list sinks | egrep '^\s+Vol' | head -1 | awk -F '/' '{printf $2}' | sed 's/\s\+\([0-9]\{1,3\}\)%\s\+/\1/')
        if [[ $v =~ ^[0-9]+$ ]]; then
          eval "v=\$(($v + $2))"
          if [ $v -ge 100 ]; then
            eval "pactl set-sink-volume ${n} 100%"
          else
            eval "pactl set-sink-volume ${n} +${2}%"
          fi
        fi
        ;;
      dec)
        eval "pactl set-sink-volume ${n} -${2}%"
        ;;
      mut)
        case "$2" in
          1)
            eval "pactl set-sink-mute ${n} 1"
            ;;
          0)
            eval "pactl set-sink-mute ${n} 0"
            ;;
        esac
        ;;
      mutt)
        local mstat=$(pactl list sinks | egrep '^\s+Mute:' | head -1 | awk '{printf $NF}')
        case "$mstat" in
          no)
            eval "pactl set-sink-mute ${n} 1"
            ;;
          yes)
            eval "pactl set-sink-mute ${n} 0"
            ;;
          *)
            eval "pactl set-sink-mute ${n} 0"
            ;;
        esac
        ;;
    esac
  else
    testBin amixer
    if [ $RTBOOL -eq 1 ];then
      case "$1" in
        inc)
          eval "amixer sset Master ${2}%+"
          ;;
        dec)
          eval "amixer sset Master ${2}%-"
          ;;
        mutt)
          local mstat=$(amixer sget Master | tail -1 | awk '{printf $NF}')
          case "$mstat" in
            [on])
              amixer sset Master mute
              ;;
            [off])
              amixer sset Master unmute
              ;;
            *)
              amixer sset Master unmute
              ;;
          esac
          ;;
      esac
    else
      echo 'no pactl or amixer command'
    fi
  fi
}

eval "hanVol $1 $2"
