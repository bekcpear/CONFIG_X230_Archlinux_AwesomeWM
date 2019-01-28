#!/usr/bin/bash
#

export XMODIFIERS="@im=fcitx"
export QT_IM_MODULE=fcitx
export GTK_IM_MODULE=fcitx
export SDL_IM_MODULE=fcitx

xrdb -merge .Xresources
compton -b &

#xcompmgr &

#LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/u/s/local/lib64/ /home/u/s/local/bin/nextcloud &
#fcitx &
#quiterss &
#redshift -t 6500K:5500K &

exec awesome > /tmp/awesome.log 2>&1
