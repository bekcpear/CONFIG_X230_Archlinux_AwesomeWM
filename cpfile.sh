#!/usr/bin/bash
#

function fcp(){
  local path="$1"
  eval "local dpath=\$(echo '$path' | sed 's/^/.\\/rootfs/' | sed 's/\\/[^/]*$//')"
  if [ ! -e "$dpath" ]; then
    eval "mkdir -p '$dpath'"
    echo -e " \e[2;37mmkdir -p '$dpath'\e[0m"
  fi
  if [ -f "$path" ]; then
    eval "cp -f '$path' '$dpath'"
    echo -e "  \e[2;37mcp -f '$path' '$dpath'\e[0m"
  elif [ -d "$path" ]; then
    eval "cp -Rf '$path' '$dpath'"
    echo -e "  \e[2;37mcp -Rf '$path' '$dpath'\e[0m"
  elif [[ $path =~ [^/]*\*[^/]*$ ]]; then
    eval "local p=\$(echo '$path' | sed 's/.*\\/\([^/]*\)$/\1/' | sed 's/\\./\\\\./g' | sed 's/\\*/.*/g')"
    eval "local spath=\$(echo '$dpath' | sed 's/^\\.\\/rootfs//')"
    eval "local fs=\$(ls -1 '$spath' | egrep '$p' | tr '\n' ' ')"
    eval "local fa=($fs)"
    for f in ${fa[@]};do
      eval "cp -f '${spath}/${f}' '$dpath'"
      echo -e "  \e[2;37mcp -f '${spath}/${f}' '$dpath'\e[0m"
    done
  fi
}

eval "dir=\$(dirname $0)"
eval "cd $dir"
echo -e "  \e[2;37mcd $dir\e[0m"

rm -rf ./rootfs
mkdir ./rootfs

fcp /.cc.map
fcp /etc/acpi/events/vol-m
fcp /etc/default/grub
fcp /etc/default/tlp
fcp /etc/fstab
fcp /etc/hostname
fcp /etc/mkinitcpio.conf
fcp /etc/NetworkManager/NetworkManager.conf
fcp /etc/pam.d/login
fcp /etc/pam.d/passwd
fcp /etc/sysctl.d
fcp /etc/udev/rules.d
fcp /etc/X11/xorg.conf.d
fcp /home/u/.config/awesome
fcp /home/u/.config/fcitx/rime/default.yaml
fcp /home/u/.config/sakura
fcp /home/u/.vimrc
fcp /home/u/.Xresources
fcp /home/u/.xinitrc
fcp /home/u/.zshrc
fcp /home/u/.zprofile
fcp /opt/bin/\*.sh
fcp /root/.vimrc
fcp /root/.zshrc
fcp /lib/systemd/system/custom-startup.service
fcp /lib/systemd/system/i3lock@.service
fcp /home/u/.local/share/applications/netease-musicbox.desktop
