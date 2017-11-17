#!/usr/bin/bash
#

export XMODIFIERS="@im=fcitx"
export QT_IM_MODULE=fcitx
export GTK_IM_MODULE=fcitx
export SDL_IM_MODULE=fcitx

xrdb -merge .Xresources

#xcompmgr &

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/u/s/local/lib64/ /home/u/s/local/bin/nextcloud &
fcitx &
redshift -t 5500K:4500K &
<<<<<<< HEAD
=======

sleep 5 && compton -b &
>>>>>>> 1b7b65618d30a631905d47b23646dcec56a19aed

sleep 5 && compton -b &

exec awesome > /tmp/awesome.log 2>&1
