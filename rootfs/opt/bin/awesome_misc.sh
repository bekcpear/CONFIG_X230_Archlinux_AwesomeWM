#!/usr/bin/bash
#

case "$1" in
  mousecorner)
    vdim=$(xdpyinfo | grep dimensions: | sed 's/^[ a-z:]\+[0-9]\+x\([0-9]\+\)[ 0-9a-z()]\+/\1/')
    eval "xdotool mousemove 0 $vdim"
    ;;
esac
