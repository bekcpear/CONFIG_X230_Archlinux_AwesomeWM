--[[
-- written by Bekcpear <i@ume.ink>
--]]

local gears     = require("gears")
local awful     = require("awful")
local wibox     = require("wibox")
local naughty   = require("naughty")
local beautiful = require("beautiful")

local mywi      = {}

mywi.s_easy_async = function(cmd)
  awful.spawn.easy_async("/usr/bin/bash -c '" .. cmd .. "'", function(stdout, stderr, reason, exit_code)
    if exit_code ~= 0 then
      naughty.notify({title = "EXEC: " .. cmd .. " ERR.", text = string.format("[%s] %s, %s", exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
    end
  end)
end

--{{{ Volume widget Start
-- init
mywi.sliderbar = wibox.widget {
    bar_shape           = gears.shape.rounded_rect,
    bar_height          = 0.7,
    bar_color           = beautiful.border_color,
    forced_width        = 70,
    handle_color        = beautiful.fg_normal,
    handle_shape        = gears.shape.circle,
    handle_width        = 7,
    handle_border_width = 0,
    value               = 0,
    minimum             = 0,
    maximum             = 100,
    widget              = wibox.widget.slider,
}
mywi.sliderwidget = wibox.container.margin(mywi.sliderbar, 0, 2)
mywi.volicon = wibox.widget.imagebox(beautiful.vol_ico)

-- loop to check volume and is_muted
local vol_v, vol_mute
function getVolStat(stdout, stderr, reason, exit_code)
  if exit_code == 0 then
    vol_mute, vol_v = string.match(stdout, 'Mute:%s*(%a+)%s*[\r\n]*%s*Volume:[%s%a%d:-]+/%s+(%d+)')
    mywi.sliderbar.value = tonumber(vol_v)
    if vol_mute == "yes" then mywi.sliderbar.handle_color = beautiful.bg_urgent
    else mywi.sliderbar.handle_color = beautiful.fg_normal end
  else
    naughty.notify({title = "Get initial volume err.", text = tostring(stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
  end
end

local vol_timer = gears.timer({ timeout = 2 })
vol_timer:start()
vol_timer:connect_signal("timeout", function()
    awful.spawn.easy_async("pactl list sinks", getVolStat)
  end
)
vol_timer:emit_signal("timeout")

-- binding click event
mywi.sliderwidget:buttons(awful.util.table.join(
  awful.button({}, 3, function () 
    if mywi.sliderbar.handle_color == beautiful.fg_normal then mywi.sliderbar.handle_color = beautiful.bg_urgent
    else mywi.sliderbar.handle_color = beautiful.fg_normal end
  end),
  awful.button({}, 4, function ()
    mywi.sliderbar.value = mywi.sliderbar.value + 1
  end),
  awful.button({}, 5, function ()
    mywi.sliderbar.value = mywi.sliderbar.value - 1
  end)
  )
)

-- notify & change slider when volume changed
local muted = ''
mywi.sliderbar:connect_signal("widget::redraw_needed", function(w)
  vol_timer:stop()
  muted = ''
  mywi.s_easy_async(string.format("/opt/bin/volume-control.sh vol %s", w.value))
  if w.value == 0 then mywi.volicon:set_image(beautiful.vol_no_ico)
  elseif w.value <= 50 then mywi.volicon:set_image(beautiful.vol_low_ico)
  else mywi.volicon:set_image(beautiful.vol_ico) end
  if mywi.sliderbar.handle_color == beautiful.bg_urgent then
    mywi.s_easy_async("/opt/bin/volume-control.sh mut 1")
    muted = '[M]'
    mywi.volicon:set_image(beautiful.vol_mute_ico)
  else
    mywi.s_easy_async("/opt/bin/volume-control.sh mut 0")
  end
  naughty.destroy(naughty.getById(mywi.sliderbar.notify_id))
  mywi.sliderbar.notify_id = naughty.notify({text = "Vol: " .. tostring(w.value) .. "% " .. muted, timeout = 1, position = 'bottom_middle'}).id
  vol_timer:start()
  return true
end)

-- toggle MIC mute
mywi.micmutetoggle = function()
  awful.spawn.easy_async('pactl list sources', function(stdout, stderr, reason, exit_code)
    if exit_code == 0 then
      local i       = 0
      local mic_id, l_mic_id, l_mic_stat, l_mic_class
      for l_mic_id, l_mic_stat, l_mic_class in string.gmatch(stdout, '[\n\r]*Source%s+#(%d+).-%s+Mute:%s+(%a+).-%s+device%.class%s+=%s+"(%a+)') do
        if l_mic_class == 'sound' then
          mic_id    = l_mic_id
        end
      end
      mywi.s_easy_async("pactl set-source-mute " .. mic_id .. " toggle")
    else
      naughty.notify({title = "Toggle MIC mute err.", text = string.format("Exec: pactl list sources error, status: %s, %s, stderr: %s", exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
    end
  end)
end
-- Volume widget End }}}

-- read file
local file        = {}
local file_s      = {}
local file_err    = {}
local file_err_no = {}
local file_i      = 0
function file_read(name, notify_err, read_mode)
  if notify_err == nil then
    notify_err    = true
  end
  if read_mode == true then
    read_mode     = '*a'
  else
    read_mode     = '*l'
  end
  file_i          = file_i + 1
  if file_i > 20 then
    file_i        = 0
  end
  file[file_i], file_err[file_i], file_err_no[file_i] = io.open(name,"r")
  if file[file_i] ~= nil then
    file_s[file_i] = file[file_i]:read(read_mode)
    if file_s[file_i] ~= nil then
      file[file_i]:close()
      return file_s[file_i]
    end
    file[file_i]:close()
  end
  if (file[file_i] == nil or file_s[file_i] == nil) and notify_err then
    naughty.notify({title = "Read file err.", text = string.format("[%s] %s", tostring(file_err_no[file_i]), tostring(file_err[file_i])), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
  end
  return false
end

--{{{  Net traffic widget start
local netbar_up = wibox.widget {
  min_value         = 0,
  step_width        = 0.5,
  step_spacing      = 0.3,
  scale             = true,
  forced_width      = 80,
  color             = beautiful.graph_1,
  background_color  = beautiful.bg_normal,
  border_color      = beautiful.bg_normal,
  widget            = wibox.widget.graph
}
local netbar_do = wibox.widget {
  min_value         = 0,
  step_width        = 0.5,
  step_spacing      = 0.3,
  scale             = true,
  forced_width      = 80,
  color             = beautiful.graph_0,
  background_color  = beautiful.bg_normal,
  border_color      = beautiful.bg_normal,
  widget            = wibox.widget.graph
}
local netbar = wibox.widget {
  wibox.container.margin(wibox.container.mirror(netbar_do, {horizontal = true, vertical = true}), 0, 0, 2, 9),
  wibox.container.margin(wibox.container.mirror(netbar_up, {horizontal = true, vertical = false}), 0, 0, 9, 2),
  opacity = 0.7,
  layout  = wibox.layout.stack
}
local nettxt_unit = wibox.widget {
  text   = 'kBps',
  align  = 'center',
  valign = 'center',
  font   = 'DejaVu Sans Mono 6',
  widget = wibox.widget.textbox
}
local nettxt_sep = wibox.widget {
  text   = ' ',
  align  = 'center',
  valign = 'center',
  font   = 'DejaVu Sans Mono 6',
  widget = wibox.widget.textbox
}
local nettxt_symb_up = wibox.widget {
  text   = '↾',
  align  = 'left',
  valign = 'top',
  font   = 'DejaVu Sans Mono 6',
  widget = wibox.widget.textbox
}
local nettxt_up = wibox.widget {
  text   = '0.0',
  align  = 'left',
  valign = 'center',
  font   = 'DejaVu Sans Mono 8',
  widget = wibox.widget.textbox
}
local nettxtup = wibox.widget {
  nettxt_up,
  nettxt_symb_up,
  layout = wibox.layout.fixed.horizontal
}
local nettxt_symb_do = wibox.widget {
  text   = '⇃',
  align  = 'right',
  valign = 'bottom',
  font   = 'DejaVu Sans Mono 6',
  widget = wibox.widget.textbox
}
local nettxt_do = wibox.widget {
  text   = '0.0',
  align  = 'right',
  valign = 'center',
  font   = 'DejaVu Sans Mono 8',
  widget = wibox.widget.textbox
}
local nettxtdo = wibox.widget {
  nettxt_symb_do,
  nettxt_do,
  layout = wibox.layout.fixed.horizontal
}
local nettxt = wibox.widget {
  nettxtdo,
  nettxt_sep,
  nettxtup,
  forced_width = 80,
  layout = wibox.layout.align.horizontal
}
local netwithoutunit = wibox.widget {
  netbar,
  nettxt,
  layout  = wibox.layout.stack
}
local netimage = wibox.widget.imagebox(beautiful.net_ico)
mywi.netwidget = wibox.widget {
  netimage,
  netwithoutunit,
  nettxt_unit,
  layout = wibox.layout.fixed.horizontal
}

local netwidget_t = awful.tooltip({
  objects = {mywi.netwidget},
  delay_show = 1
})

-- loop to check speed
local iw              = nil
local ethtool         = nil
local tooldeterF      = false
function determineTool(toolname)
  awful.spawn.easy_async('which ' .. toolname, function(stdout, stderr, reason, exit_code)
    if exit_code == 0 then
      local cmd       = string.match(stdout, '[^\r\n]+')
      local f         = io.open(cmd,"r")
      if f ~= nil then
        if toolname == 'iw' then
          iw          = cmd
        elseif toolname == 'ethtool' then
          ethtool     = cmd
        end
        f:close()
      end
    else
      naughty.notify({title = "Get wireless signle strength err.", text = string.format("Exec: which %s error, status: %s, %s, stderr: %s", toolname, exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
    end
    tooldeterF        = true
  end)
end
determineTool('iw')
determineTool('ethtool')

local interface       = ''
local last_interface  = ''
local conn_type       = ''
local last_conn_type  = ''
local conn_name       = ''
local getCmd          = "/usr/bin/bash -c 'nmcli c show --active | sed -n 2p'"
local getCmdF         = false
local net_timer       = gears.timer({ timeout = 2 })
local net_timer_init  = true
function getNetConn(stdout, stderr, reason, exit_code)
  if exit_code == 0 then
    conn_name, conn_type, interface = string.match(stdout, '([%a%d:_]+)%s+[%a%d-]+%s+(%a+)%s+([%l%d]+)')
    if net_timer_init then
      net_timer_init = false
      net_timer:start()
      if tooldeterF then
        net_timer:emit_signal("timeout")
      end
    end
  else
    naughty.notify({title = "Get NM connections err.", text = string.format("Exec: %s error, status: %s, %s, stderr: %s", getCmd, exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
  end
  getCmdF                 = true
end

local last_tx             = 0
local last_rx             = 0
local now_tx              = 0
local now_rx              = 0
local up                  = 0
local dw                  = 0
local netwidgethover      = false
local netwidgethoverinit0 = false
local netwidgethoverinit1 = false
local netwidgethoverinit2 = false
mywi.netwidget:connect_signal('mouse::enter', function() 
  netwidgethover          = true
end)
mywi.netwidget:connect_signal('mouse::leave', function() 
  netwidgethover          = false
  netwidgethoverinit0     = false
  netwidgethoverinit1     = false
end)
local vul, signal, bitrate
net_timer:connect_signal("timeout", function()
  if (not netwidgethoverinit0 or netwidgethover) and not netwidgethoverinit1 and not netwidgethoverinit2 then
    netwidgethoverinit0   = true
    netwidget_t.text      = tostring(conn_name) .. ' (' .. tostring(conn_type) .. ', ' .. tostring(interface) .. ')'
  end
  vul                     = file_read("/sys/class/net/" .. tostring(interface) .. "/carrier", false)
  if vul == false or tonumber(vul) ~= 1 or (conn_type ~= 'wifi' and conn_type ~='ethernet') then 
    netimage:set_image(beautiful.net_off_ico)
    netwidget_t.text      = 'Offline'
    last_conn_type        = ''
    awful.spawn.easy_async(getCmd, getNetConn)
    return false
  else
    if conn_type == 'wifi' then
      if last_conn_type ~= conn_type then
        last_conn_type    = conn_type
        netimage:set_image(beautiful.net_wl_ico)
      end
      if iw and (not netwidgethoverinit1 or netwidgethover) then
        netwidgethoverinit1 = true
        awful.spawn.easy_async(iw .. ' dev ' .. interface .. ' link', function(stdout, stderr, reason, exit_code)
          if exit_code == 0 then
            signal, bitrate       = string.match(stdout, "signal:%s+([%d.-]+%s+%a+)[\r\n]*%s+tx%s+bitrate:%s+([%d.]+%s+[%a/]+)")
            netwidget_t.text      = tostring(conn_name) .. ' (' .. tostring(conn_type) .. ', ' .. tostring(interface) .. ')\nsignal: ' .. tostring(signal) ..', bitrate: ' .. tostring(bitrate)
          else
            naughty.notify({title = "Get wireless signle strength err.", text = string.format("Exec: %s error, status: %s, %s, stderr: %s", iw .. ' dev ' .. interface .. ' link', exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
          end
        end)
      end
    elseif conn_type == 'ethernet' then
      if last_conn_type ~= conn_type then
        last_conn_type = conn_type
        netimage:set_image(beautiful.net_ico)
      end
      if ethtool and (not netwidgethoverinit2 or netwidgethover) then
        netwidgethoverinit2 = true
        awful.spawn.easy_async(ethtool .. ' ' .. interface, function(stdout, stderr, reason, exit_code)
          if exit_code == 0 then
            bitrate               = string.match(stdout, "Speed:%s+(%d+)")
            netwidget_t.text      = tostring(conn_name) .. ' (' .. tostring(conn_type) .. ', ' .. tostring(interface) .. ')\nbitrate: ' .. tostring(bitrate) .. ' Mbps'
          else
            naughty.notify({title = "Get wireless signle strength err.", text = string.format("Exec: %s error, status: %s, %s, stderr: %s", ethtool .. ' ' .. interface, exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
          end
        end)
      end
    end
    if interface ~= last_interface then
      last_tx       = 0
      last_rx       = 0
      up            = 0
      dw            = 0
    end
    now_tx          = tonumber(file_read("/sys/class/net/" .. tostring(interface) .. "/statistics/tx_bytes"))
    now_rx          = tonumber(file_read("/sys/class/net/" .. tostring(interface) .. "/statistics/rx_bytes"))
    if now_rx >= 0 and now_tx >= 0 and last_rx > 0 and last_tx > 0  then
      up            = (now_tx - last_tx) / 2048
      dw            = (now_rx - last_rx) / 2048
      if up >= 1000 or dw >= 1000 then
        nettxt_up.text = string.format("%.1f", up / 1024)
        nettxt_do.text = string.format("%.1f", dw / 1024)
        nettxt_unit.text = 'mBps'
      else
        nettxt_up.text = string.format("%.1f", up)
        nettxt_do.text = string.format("%.1f", dw)
        nettxt_unit.text = 'kBps'
      end
      netbar_up:add_value(up)
      netbar_do:add_value(dw)
    end

    last_tx = now_tx
    last_rx = now_rx
    last_interface = interface
  end
end
)

awful.spawn.easy_async(getCmd, getNetConn)
-- Net traffic widget End }}}

--{{{ Battery widget Start
local bat_progress = wibox.widget {
  max_value         = 1,
  value             = 0.1,
  color             = beautiful.fg_normal,
  background_color  = beautiful.bg_normal,
  shape             = gears.shape.rectangle,
  border_width      = 0.7,
  border_color      = beautiful.fg_normal,
  widget            = wibox.widget.progressbar
}
local batpbar_bat = wibox.widget {
  wibox.container.margin(bat_progress, 4, 4, 4, 2),
  forced_width      = 14,
  direction         = 'east',
  layout            = wibox.container.rotate
}
local bat_p_head  = wibox.widget.imagebox(beautiful.bat_graph_head_normal)
local bat_s_img   = wibox.widget {
  image              = beautiful.bat_graph_charging_ico,
  opacity            = 0.8,
  widget            = wibox.widget.imagebox
}
mywi.batpbar = wibox.widget {
  batpbar_bat,
  wibox.container.margin(bat_s_img, 5.7, 2, 3, 3),
  wibox.container.margin(bat_p_head, 5.5, 0, 0.5, 0),
  layout            = wibox.layout.stack
}
local batpbar_t = awful.tooltip({
  objects           = {mywi.batpbar},
  delay_show        = 1
})

-- loop to check battery status
--    
local bat_timer_init    = false
local bat_timer0        = gears.timer({ timeout = 1 })
local bat_timer1        = gears.timer({ timeout = 10 })
local ac_online         = '0'
local ac_online_stat    = 0
bat_timer0:start()
bat_timer1:start()
bat_timer0:connect_signal("timeout", function()
  ac_online             =  string.match(tostring(file_read('/sys/class/power_supply/AC/online')), '([^%s\n\r]+)')
  if ac_online == '1' then
    if ac_online_stat ~= 1 then
      ac_online_stat    = 1
      bat_s_img.visible = true
      bat_timer1:emit_signal('timeout')
      mywi.s_easy_async("/opt/bin/switch_power_status.sh u acon")
    end
  elseif ac_online == '0' then
    if ac_online_stat ~= 2 then
      ac_online_stat    = 2
      bat_s_img.visible = false
      bat_timer1:emit_signal('timeout')
      mywi.s_easy_async("/opt/bin/switch_power_status.sh u acoff")
    end
  end
end)
local color             = 0
local ico               = 0
local bat_uevent        = ''
local bat_s             = ''
local bat_v             = 0
local bat_vm            = 0
local bat_p             = 0
local bat_f             = 0
local bat_n             = 0
local bat_perc          = 0
local bat_text          = ''
local min_unit          = ' minutes'
local hour_unit         = ' hours '
local hour              = 0
local min               = 0
local left_time         = 0
bat_timer1:connect_signal("timeout", function()
  min_unit              = ' minutes'
  hour_unit             = ' hours '
  bat_uevent            = tostring(file_read('/sys/class/power_supply/BAT0/uevent', false, true))
  bat_s                 = string.match(bat_uevent, 'POWER_SUPPLY_STATUS=(%a+)')
  bat_v                 = tonumber(string.match(bat_uevent, 'POWER_SUPPLY_VOLTAGE_NOW=(%d+)'))
  bat_vm                = tonumber(string.match(bat_uevent, 'POWER_SUPPLY_VOLTAGE_MIN_DESIGN=(%d+)'))
  bat_p                 = tonumber(string.match(bat_uevent, 'POWER_SUPPLY_POWER_NOW=(%d+)'))
  bat_f                 = tonumber(string.match(bat_uevent, 'POWER_SUPPLY_ENERGY_FULL=(%d+)'))
  bat_n                 = tonumber(string.match(bat_uevent, 'POWER_SUPPLY_ENERGY_NOW=(%d+)'))
  if bat_f == nil then bat_f = 1 end
  if bat_n == nil then bat_n = 0 end
  bat_perc              = bat_n / bat_f * 100

  bat_progress.value    = bat_perc / 100
  if bat_perc >= 80 and ac_online == '1' then
    if ico ~= 1 then
      bat_s_img.image   = beautiful.bat_graph_charging_black_ico
      ico               = 1
    end
  else
    if ico ~= 0 then
      bat_s_img.image   = beautiful.bat_graph_charging_ico
      ico               = 0
    end
  end
  if bat_s == 'Charging' then
    if color ~= 1 then
      bat_progress.color = beautiful.bg_green
      bat_progress.border_color = beautiful.bg_green
      bat_p_head.image  = beautiful.bat_graph_head_charging
      color             = 1
    end
  elseif bat_perc <= 20 then
    if color ~= 2 then
      bat_progress.color  = beautiful.bg_urgent
      bat_progress.border_color = beautiful.bg_urgent
      bat_p_head.image  = beautiful.bat_graph_head_low
      color             = 2
    end
  else
    if color ~= 0 then
      bat_progress.color  = beautiful.fg_normal
      bat_progress.border_color = beautiful.fg_normal
      bat_p_head.image  = beautiful.bat_graph_head_normal
      color             = 0
    end
  end

  if ac_online == '1' then
    bat_text            = 'AC Online ('
    if bat_s == 'Charging' then
      bat_text          = bat_text .. 'charging, ' .. string.format("%.1f%%, ", bat_perc)
      if bat_vm > 10000000 and bat_vm < 12000000 and bat_v >= 12870000 then
        bat_text        = bat_text .. 'constant-voltage charging)'
      else
        left_time       = (bat_f - bat_n) / bat_p * 1.2
        if left_time >= 1 then
          hour          = math.ceil(left_time)
          min           = math.ceil(left_time % 1 * 60)
          if min ~= 0 then
            hour        = hour - 1
          end
          if hour == 1 then
            hour_unit   = ' hour '
          end
          if min == 1 then
            min_unit    = ' minute'
          end
          bat_text      = bat_text .. 'approx. ' .. tostring(hour) .. hour_unit .. tostring(min) .. min_unit .. ' left)'
        else
          min           = math.ceil(left_time * 60)
          if min == 1 then
            min_unit    = ' minute'
          end
          bat_text      = bat_text .. 'approx. ' .. tostring(min) .. min_unit .. ' left)'
        end
      end
    elseif bat_s == 'Full' then
      bat_text          = bat_text .. 'full charged)'
    elseif bat_s == nil then
      bat_text          = bat_text .. 'no battery)'
    else
      bat_text          = bat_text .. 'discharging, ' .. string.format("%.1f%%)", bat_perc)
    end
  elseif ac_online == '0' then
    bat_text            = 'AC Offline (' .. string.format("%.1f%%, %.1fW, approx. ", bat_perc, bat_p / 1000000)
    left_time           = bat_n / bat_p
    if left_time >= 1 then
      hour              = math.ceil(left_time)
       min              = math.ceil(left_time % 1 * 60)
      if min ~= 0 then
        hour            = hour - 1
      end
      if hour == 1 then
        hour_unit       = ' hour '
      end
      if min == 1 then
        min_unit        = ' minute'
      end
      bat_text          = bat_text .. tostring(hour) .. hour_unit .. tostring(min) .. min_unit .. ' left)'
    else
      min               = math.ceil(left_time * 60)
      if min == 1 then
        min_unit        = ' minute'
      end
      bat_text          = bat_text .. tostring(min) .. min_unit .. ' left)'
    end
  end
  batpbar_t.text        = bat_text
  --naughty.notify({title = "Test", text = bat_s, timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
end)
if bat_timer_init == false then
  bat_timer_init        = true
  bat_timer0:emit_signal('timeout')
  bat_timer1:emit_signal('timeout')
end

-- Battery widget End }}}

--{{{ Temperature widget Start
local temp_graph_prog_c = wibox.widget {
  max_value         = 105,
  value             = 50,
  color             = beautiful.fg_normal,
  background_color  = beautiful.bg_normal,
  shape             = gears.shape.rounded_bar,
  border_width      = 0.5,
  border_color      = beautiful.fg_normal,
  widget            = wibox.widget.progressbar
}
local temp_graph_prog = wibox.widget {
  wibox.container.margin(temp_graph_prog_c, 6, 3, 4.2, 3.2),
  forced_width      = 10,
  direction         = 'east',
  layout            = wibox.container.rotate
}
local temp_graph_bot = wibox.widget.imagebox(beautiful.temp_graph_bot_normal)
mywi.tempgraph = wibox.widget {
  temp_graph_prog,
  wibox.container.margin(temp_graph_bot, 1.75, 0, 0, 2.5),
  layout            = wibox.layout.stack
}
local tempgraph_t = awful.tooltip({
  objects           = {mywi.tempgraph},
  delay_show        = 1
})

-- loop to check temperature
local temp_timer  = gears.timer({timeout = 10})
local temper      = 0
local fans        = 0
local temp_flag   = 0
temp_timer:connect_signal('timeout', function()
  temper          = tonumber(file_read('/sys/bus/platform/devices/coretemp.0/hwmon/hwmon0/temp1_input'))
  fans            = tonumber(file_read('/sys/bus/platform/devices/thinkpad_hwmon/hwmon/hwmon2/fan1_input'))
  tempgraph_t:set_text(string.format("%.1f °C (%d rpm)", temper / 1000, fans))
  temp_graph_prog_c.value = temper / 1000
  if temper >= 87000 and temp_flag ~= 1 then
    temp_flag = 1
    temp_graph_prog_c.color = beautiful.bg_urgent
    temp_graph_prog_c.border_color = beautiful.bg_urgent
    temp_graph_bot.image = beautiful.temp_graph_bot_high
  elseif temper > 68000 and temper < 87000 and temp_flag ~= 2 then
    temp_flag = 2
    temp_graph_prog_c.color = beautiful.bg_warn
    temp_graph_prog_c.border_color = beautiful.bg_warn
    temp_graph_bot.image = beautiful.temp_graph_bot_warn
  elseif temper <= 68000 and temp_flag ~= 3 then
    temp_flag = 3
    temp_graph_prog_c.color = beautiful.fg_normal
    temp_graph_prog_c.border_color = beautiful.fg_normal
    temp_graph_bot.image = beautiful.temp_graph_bot_normal
  end
end)
temp_timer:start()
temp_timer:emit_signal('timeout')
-- Temperature widget End }}}

-- {{{ Show brightness Start
mywi.showbrightness_notify_id = 0
local brightness              = 0
local brightness_max          = 0
brightness_max                = tonumber(file_read('/sys/class/backlight/acpi_video0/max_brightness'))
mywi.showBrightness = function(act)
  naughty.destroy(naughty.getById(mywi.showbrightness_notify_id))
  brightness                  = tonumber(file_read('/sys/class/backlight/acpi_video0/brightness')) + act
  if brightness > brightness_max then
    brightness                = brightness_max
  elseif brightness < 0 then
    brightness                = 0
  end
  mywi.showbrightness_notify_id = naughty.notify({text = string.format("Brightness: %d", brightness), timeout = 1, position = 'bottom_middle'}).id
end
-- Show brightness End }}}

-- {{{ Show rss Start
local rss = 0
mywi.showrss = function(pid)
  rss     = tonumber(string.match(file_read('/proc/' .. tostring(pid) .. '/statm'), '%d+%s+(%d+)')) * 4
  if rss < 1024 then -- KiB
    rss   = tostring(rss) .. ' KiB'
  elseif rss >= 1024 and rss / 1024 < 1024 then -- MiB
    rss   = string.format('%.2f MiB', rss / 1024)
  else -- GiB
    rss   = string.format('%.2f GiB', rss / 1024 / 1024)
  end
  return rss
end
-- Show rss End }}}

--{{{ Separator
mywi.separator  = wibox.widget {
  text          = '|',
  align         = 'center',
  font          = 'DejaVu Sans Mono 6',
  forced_width  = 10,
  opacity       = 0.3,
  widget        = wibox.widget.textbox
}
mywi.separator_empty  = wibox.widget {
  text          = '',
  align         = 'center',
  forced_width  = 3,
  widget        = wibox.widget.textbox
}
-- Separator }}}

-- {{{ Get wallpaper randomly Start
if beautiful.wallpaper_dir ~= nil or (beautiful.wallpaper_dir_day ~= nil and beautiful.wallpaper_dir_night ~= nil) then
  local wall_a      = {}
  local wall_errs   = ''
  local wall_exco   = 0
  local wall_reas   = ''
  local wall_index  = 0
  local wall_lindex = {}
  local wall_lindey = {}
  local wall_lscr   = {}
  local wall_lscr_i = 0
  local wall_lscr_f = false
  local wall_dir    = ''
  local wall_path   = ''
  local wall_hour   = 0

  math.randomseed(os.time())
  beautiful.wallpaper = function(s)
    if s == nil then
      naughty.notify({title = "Random wallpaper err.", text = 'nil screen', timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
      return nil
    end

    wall_a          = {}
    wall_errs       = ''

    if beautiful.wallpaper_day_h_s ~= nil and beautiful.wallpaper_night_h_s ~= nil and beautiful.wallpaper_dir_day ~= nil and beautiful.wallpaper_dir_night ~= nil then
      wall_hour     = os.date('*t')['hour']
      if  wall_hour >= beautiful.wallpaper_day_h_s and wall_hour < beautiful.wallpaper_night_h_s then
        wall_dir    = beautiful.wallpaper_dir_day
      elseif  wall_hour < beautiful.wallpaper_day_h_s or wall_hour >= beautiful.wallpaper_night_h_s then
        wall_dir    = beautiful.wallpaper_dir_night
      end
    else
      wall_dir      = beautiful.wallpaper_dir
    end
    awful.spawn.with_line_callback(string.format("/usr/bin/bash -c 'ls -1 %s | egrep \"\\.(png|jpg|jpeg)$\"'", wall_dir), {
      stdout = function(stdout)
        table.insert(wall_a, stdout)
      end,
      stderr = function(stderr)
        wall_errs   = wall_errs .. '\n' .. tostring(stderr)
      end,
      output_done = function()
        if wall_exco ~= 0 then
          naughty.notify({title = "Random wallpaper err.", text = string.format("[%d] %s: %s", wall_exco, wall_reas, wall_errs), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})
        elseif #wall_a > 0 then
          for i = 1, #wall_lscr, 1 do
            if wall_lscr[i] == s then
              wall_lscr_i = i
              wall_lscr_f = true
            end
          end
          if not wall_lscr_f then
            table.insert(wall_lscr, s)
            wall_lscr_i   = #wall_lscr
          end
          wall_lscr_f     = false

          if #wall_a == 1 then
            wall_index      = 1
          elseif #wall_a == 2 then
            if wall_index == 1 then
              wall_index    = 2
            else
              wall_index    = 1
            end
          else
            wall_index      = math.random(#wall_a)
            while wall_lindex[wall_lscr_i] == wall_index or wall_lindey[wall_lscr_i] == wall_index do
              wall_index    = math.random(#wall_a)
            end
            wall_lindey[wall_lscr_i] = wall_lindex[wall_lscr_i]
            wall_lindex[wall_lscr_i] = wall_index
          end
          if string.match(wall_dir, '(/)$') == nil then
            wall_path     = wall_dir .. '/' .. wall_a[wall_index]
          else
            wall_path     = wall_dir .. wall_a[wall_index]
          end
          gears.wallpaper.maximized(wall_path, s)
        end
      end,
      exit = function(reason, exit_code)
        wall_exco   = exit_code
        wall_reas   = reason
      end,
    })
  end
end
-- Get wallpaper randomly End }}}

return mywi
