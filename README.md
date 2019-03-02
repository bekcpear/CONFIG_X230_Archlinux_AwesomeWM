## X230 + Archlinux + AwesomeWM 配置文件

我的配置和主题文件，目的是避免以后万一系统需要重装麻烦

* 60G SSD 单 BtrFS 格式分区 + LUKS 全盘加密
* 自写 AwesomeWM 4.3 主题（网络显示依赖 NetworkManager, 声音调节依赖 Pulseaudio 且不支持蓝牙），截图在最后

  * 功能：

    * 音量滑动调节 + 显示 + 默認聲卡切換（ALSA + Pulseaudio）
    * 调节亮度时显示
    * 有线/无线联网状态显示 + 信号/速率显示 + 條形图
    * 剩余电量/使用时间/充电状态显示
    * CPU 温度/风扇转速显示
    * Mod4 + W （或右上角按钮）显示关机/重启/睡眠等操作按钮
    * PrtSc 键利用 `gnome-screenshot` 捕获整个屏幕区域保存图像到家目录下
    * 使用 i3lock 锁屏，利用 xautolock 定时锁屏（接电源时）/睡眠（仅电池时）。 *但有一个问题是其无法判断当前是否正在播放视频，如果看视频的时候那就直接* `xautolock -disable` *来临时禁用就好*
    * 自动随机切换壁纸，可以单独设定日/夜壁纸目录，可設定壁紙過渡效果爲淡入淡出（CPU 消耗厲害），帶即時切換壁紙快捷鍵
    * 存在 PID 的窗口显示其 PID ，其 Resident Set Size 以及其 CPU 使用率（子進程未計算）
    * 每個標籤下使用快捷鍵打開的第一個終端窗口浮動，且靠右下方顯示，之後終端正常佈局；當對應標籤下第一個默認浮動的終端被關閉後，下次打開的第一個終端窗口默認浮動
    * 系統托盤區顯示整個系統的 CPU 使用率
    * 更多自定義快捷鍵，Mod + s 查看，支持 Mod + l/h 浮動窗口放大縮小

  * 注：文件 `/usr/share/awesome/lib/awful/widget/button.lua` 下有一个修改（調節按下按鈕後的偏移距離）

  ```diff
  @@ -40,7 +40,7 @@
           img_release = surface.load(image)
             img_press = img_release:create_similar(cairo.Content.COLOR_ALPHA, img_release.width, img_release.height)
                      local cr = cairo.Context(img_press)
  ---        cr:set_source_surface(img_release, 2, 2)
  +++        cr:set_source_surface(img_release, 0, 0.5)
             cr:paint()
                      orig_set_image(self, img_release)
         end
  ```

* <s>无 Display Manager, tty 下通过 shell 判断是否 startx</s> 因为 DBUS 参数的问题，最终还是用上了 SDDM 作为 DM，并使用了 [Starcraft](https://www.opendesktop.org/p/1231525/) 主题，依赖 `plasma-workspace` `plasma-workspace` 这两个包，去掉了主题中显示电池的部件，不然依赖更多的包；因为 熵 的问题，启动 sddm 有 43 秒的延迟，安装 `haveged` 可以解决，但是根据 [Archwiki](https://wiki.archlinux.org/index.php/Haveged) 的说明会导致生成的熵的质量下降，所以我没用，决定忍受 43 秒的等待。
* 利用 systemd 服务实现睡眠前如果未锁屏则自动锁屏后睡眠
* <s>Xterm 作为主 terminal, 透明已经在 awesome 下配置，需要启动 xcompmgr 以实现</s> 替换成了 compton 以实现窗口阴影/过渡，几个部件透明等效果
* URxvr 作爲主 Terminal，透明使用自帶參數配置在 `~/.Xresources` 文件內
* zsh 作为默认 shell
* tlp 来管理电源（需要 mask 掉 systemd-rfkill.service 和 systemd-rfkill.socket）
* fcitx 加了<s>一个</s>兩個皮肤, indigo 和 BiliBili 2233 娘
* musicbox 利用 Sakura 运行并自定义了图标， `cp _mic/netease-cloud-music.svg /usr/share/pixmaps/` ，自定义了颜色，直接修改 `ui.py` 大约 68 行：

```
            #info
            curses.init_pair(1, 231, curses.COLOR_BLACK)
            #hover
            curses.init_pair(2, 117, curses.COLOR_BLACK)
            #LRC
            curses.init_pair(3, 229, curses.COLOR_BLACK)
            #title
            curses.init_pair(4, 219, curses.COLOR_BLACK)
```

也可能有配置遗漏...

After 190201:

![screenshot0](screenshot2.png)

Before 180201:

![screenshot0](screenshot0.png)

![screenshot1](screenshot1.png)

