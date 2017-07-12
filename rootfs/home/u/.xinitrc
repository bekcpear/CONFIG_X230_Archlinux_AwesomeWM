#!/usr/bin/bash
#

export XMODIFIERS="@im=fcitx"
export QT_IM_MODULE=fcitx
export GTK_IM_MODULE=fcitx
export SDL_IM_MODULE=fcitx

xrdb -merge .Xresources

xcompmgr &
fcitx &
redshift -t 5500K:4500K &
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/u/s/local/lib64/ /home/u/s/local/bin/nextcloud &

exec awesome
