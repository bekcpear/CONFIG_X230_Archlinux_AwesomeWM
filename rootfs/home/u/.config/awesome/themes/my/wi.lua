--[[
-- @author Bekcpear <i@ume.ink>
-- @module mywi
--]]

local gears     = require("gears")
local awful     = require("awful")
local wibox     = require("wibox")
local naughty   = require("naughty")
local beautiful = require("beautiful")
local smoothwp  = require("themes.my.smoothwp")
local mytl      = require("themes.my.tl")
local root      = root

local mywi      = {}

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

-- {{{ popup Widget to select right voice Card Start
local volLeftMousePressed = false
mywi.volicon:connect_signal("button::press", function()
  if mouse.coords().buttons[1] then
    volLeftMousePressed = true
  end
end)

local function myplacementforvolpopup(p, sg)
  local sw = sg['bounding_rect'].width
  local sx = sg['bounding_rect'].x
  local sy = sg['bounding_rect'].y
  local pw = p:geometry().width
  local ph = p:geometry().height
  p:geometry({x=sx + sw - pw - 10, y=21, width=pw, height=ph})
end

mytl.popVol         = {}
mytl.popVol_visible = false
local voldess       = {}
local volnames      = {}
local volsselws     = {}
local volsselwsl    = {}
local volssel       = {}
local volsseld      = {}

local function volpopMouseEnter(w)
  if not volsselwsl[w.volsselid] then
    volsselws[w.volsselid].checked = true
    volsselws[w.volsselid].opacity = 1
  end
end

local function volpopMouseLeave(w)
  if not volsselwsl[w.volsselid] then
    volsselws[w.volsselid].checked = false
  end
  volsselws[w.volsselid].opacity = 0.7
end

local function volpopMouseClick(w)
  if not volsselwsl[w.volsselid] then
    awful.spawn.easy_async_with_shell('pactl set-default-sink ' .. volnames[w.volsselid], function(stdout, stderr, reason, exit_code)
      if exit_code ~= 0 then
          naughty.notify({title = "Change default sound device err", text = string.format("Exec: pactl set-default-sink %d error, status: %s, %s, stderr: %s", w.volsselid, exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
        return
      end
      for k, _ in pairs(volsselws) do
        if k ~= w.volsselid then
          volsselws[k].opacity = 1
          volsselws[k].checked = false
          volsselwsl[k] = false
        else
          volsselws[k].opacity = 0.7
          volsselws[k].checked = true
          volsselwsl[k] = true
        end
      end
    end)
  end
end

mywi.volicon:connect_signal("button::release", function()
  if volLeftMousePressed then volLeftMousePressed = false else return end
  if not mytl.popVol_visible then
    awful.spawn.easy_async_with_shell('pactl info', function(stdout, stderr, reason, exit_code)
      if exit_code == 0 then
        local voldefaults = string.match(stdout, 'Default%sSink:%s+([%a%d%.%-_]+)')
        awful.spawn.easy_async_with_shell('pactl list sinks', function(stdout, stderr, reason, exit_code)
          if exit_code == 0 then
            voldess   = {}
            volsselws = {}
            for volid, volstat, voldes, volclass in string.gmatch(stdout, '[\n\r]*Sink%s+#(%d+).-%s+Name:%s+([%a%d%.%-_]+).-%s+Description:%s+([%s%a%d%.%-_]-)[\n\r].-%s+device%.class%s+=%s+"(%a+)') do
              if volclass == "sound" then
                volsselws[volid] = wibox.widget {
                    checked  = volstat == voldefaults and true or false,
                    color    = beautiful.bg_icon,
                    paddings = 2,
                    shape    = gears.shape.circle,
                    widget   = wibox.widget.checkbox,
                    forced_width = 12,
                    forced_height = 12,
                    opacity  = 0.7,
                }
                volsselwsl[volid] = volsselws[volid]["checked"]
                voldess[volid] = voldes
                volnames[volid] = volstat
              end
              --naughty.notify({text=tostring(volid) .. ' ' .. volstat .. ' ' .. voldes .. ' ' .. volclass, timeout=0})
            end
            volssel = {}
            for k, v in pairs(volsselws) do
              volsseld[k] = wibox.widget {
                v,
                {
                  {
                    text   = voldess[k],
                    align  = left,
                    valign = center,
                    forced_height = 12,
                    widget = wibox.widget.textbox
                  },
                  left     = 10,
                  bottom   = 17,
                  layout   = wibox.container.margin,
                },
                volsselid  = k,
                forced_height = 30,
                layout   = wibox.layout.fixed.horizontal
              }
              --very worry about CG
              volsseld[k]:connect_signal("mouse::enter", function(w) volpopMouseEnter(w) end)
              volsseld[k]:connect_signal("mouse::leave", function(w) volpopMouseLeave(w) end)
              volsseld[k]:connect_signal("button::release", function(w) volpopMouseClick(w) end)
              table.insert(volssel, volsseld[k])
            end
            volssel["layout"]  = wibox.layout.fixed.vertical
            mytl.popVol = awful.popup {
              widget = {
                volssel,
                top     = 19,
                left    = 20,
                right   = 20,
                bottom  = 3,
                layout  = wibox.container.margin,
              },
              placement    = myplacementforvolpopup,
              visible      = true,
              ontop        = true,
              opacity      = beautiful.opacity,
            }
            mytl.popVol_visible = true
          else
            naughty.notify({title = "List sound device err", text = string.format("Exec: pactl list sinks error, status: %s, %s, stderr: %s", exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
          end
        end)
      else
        naughty.notify({title = "Check default sound device err", text = string.format("Exec: pactl info error, status: %s, %s, stderr: %s", exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
      end
    end)
  end
end)
-- popup Widget to select right voice Card End}}}

-- loop to check volume and is_muted
local vol_v, vol_mute
function getVolStat()
  awful.spawn.easy_async_with_shell('pactl info', function(stdout, stderr, reason, exit_code)
    if exit_code ~= 0 then
      naughty.notify({title = "Check default sound device err", text = string.format("Exec: pactl info error, status: %s, %s, stderr: %s", exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
      return
    end
    local voldefault = string.match(stdout, 'Default%sSink:%s+([%a%d%.%-_]+)')
    awful.spawn.easy_async_with_shell('pactl list sinks', function(stdout, stderr, reason, exit_code)
      if exit_code == 0 then
        for vol_name_i, vol_mute_i, vol_v_i in string.gmatch(stdout, 'Name:%s+([%a%d%.%-_]+).-%s+Mute:%s*(%a+)%s*[\r\n]*%s*Volume:[%s%a%d:-]+/%s+(%d+)') do
          if vol_name_i == voldefault then
            vol_v    = vol_v_i
            vol_mute = vol_mute_i
          end
        end
        mywi.sliderbar.value = tonumber(vol_v)
        if vol_mute == "yes" then mywi.sliderbar.handle_color = beautiful.bg_urgent
        else mywi.sliderbar.handle_color = beautiful.fg_normal end
      else
        naughty.notify({title = "Get initial volume err.", text = tostring(stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
      end
    end)
  end)
end

local vol_timer = gears.timer({ timeout = 2 })
vol_timer:start()
vol_timer:connect_signal("timeout", function()
    getVolStat()
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
  mytl.s_easy_async(string.format("/opt/bin/volume-control.sh vol %s", w.value))
  if w.value == 0 then mywi.volicon:set_image(beautiful.vol_no_ico)
  elseif w.value <= 50 then mywi.volicon:set_image(beautiful.vol_low_ico)
  else mywi.volicon:set_image(beautiful.vol_ico) end
  if mywi.sliderbar.handle_color == beautiful.bg_urgent then
    mytl.s_easy_async("/opt/bin/volume-control.sh mut 1")
    muted = '[M]'
    mywi.volicon:set_image(beautiful.vol_mute_ico)
  else
    mytl.s_easy_async("/opt/bin/volume-control.sh mut 0")
  end
  if naughty.getById(mywi.sliderbar.notify_id) ~= nil then
    naughty.replace_text(naughty.getById(mywi.sliderbar.notify_id), nil, "Vol: " .. tostring(w.value) .. "% " .. muted)
    naughty.reset_timeout(naughty.getById(mywi.sliderbar.notify_id), 2)
  else
    mywi.sliderbar.notify_id = naughty.notify({text = "Vol: " .. tostring(w.value) .. "% " .. muted, timeout = 2, position = 'bottom_middle'}).id
  end
  vol_timer:start()
  return true
end)

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
  delay_show = beautiful.ttdelayshowtime
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
      naughty.notify({title = "Get wireless signle strength err.", text = string.format("Exec: which %s error, status: %s, %s, stderr: %s", toolname, exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
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
    naughty.notify({title = "Get NM connections err.", text = string.format("Exec: %s error, status: %s, %s, stderr: %s", getCmd, exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
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
  vul                     = mytl.file_read("/sys/class/net/" .. tostring(interface) .. "/carrier", false)
  if vul == false or tonumber(vul) ~= 1 or (conn_type ~= 'wifi' and conn_type ~='ethernet') then 
    netimage:set_image(beautiful.net_off_ico)
    netwidget_t.text      = 'offline'
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
            naughty.notify({title = "Get wireless signle strength err.", text = string.format("Exec: %s error, status: %s, %s, stderr: %s", iw .. ' dev ' .. interface .. ' link', exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
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
            naughty.notify({title = "Get wireless signle strength err.", text = string.format("Exec: %s error, status: %s, %s, stderr: %s", ethtool .. ' ' .. interface, exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
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
    now_tx          = tonumber(mytl.file_read("/sys/class/net/" .. tostring(interface) .. "/statistics/tx_bytes"))
    now_rx          = tonumber(mytl.file_read("/sys/class/net/" .. tostring(interface) .. "/statistics/rx_bytes"))
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
  delay_show        = beautiful.ttdelayshowtime
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
  ac_online             =  string.match(tostring(mytl.file_read('/sys/class/power_supply/AC/online')), '([^%s\n\r]+)')
  if ac_online == '1' then
    if ac_online_stat ~= 1 then
      if naughty.getById(mywi.batpbar.notify_id) ~= nil then
        naughty.destroy(naughty.getById(mywi.batpbar.notify_id))
      end
      ac_online_stat    = 1
      bat_s_img.visible = true
      bat_timer1:emit_signal('timeout')
      mytl.s_easy_async("/opt/bin/switch_power_status.sh u acon")
    end
  elseif ac_online == '0' then
    if ac_online_stat ~= 2 then
      ac_online_stat    = 2
      bat_s_img.visible = false
      bat_timer1:emit_signal('timeout')
      mytl.s_easy_async("/opt/bin/switch_power_status.sh u acoff")
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
local lowbatnum         = 0
local show_bat_status   = false
local power_status_ico  = ''
local power_status_title= ''
local power_status_text = ''
bat_timer1:connect_signal("timeout", function()
  min_unit              = ' minutes'
  hour_unit             = ' hours '
  power_status_text     = ''
  bat_uevent            = tostring(mytl.file_read('/sys/class/power_supply/BAT0/uevent', false, true))
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
    bat_text            = 'AC online ('
    power_status_title  = 'AC'
    power_status_ico    = beautiful.power_notify_ac_ico
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
    bat_text            = 'AC offline (' .. string.format("%.1f%%, %.1fW", bat_perc, bat_p / 1000000)
    power_status_title  = 'BAT (' .. string.format("%.1f%%, %.1fW", bat_perc, bat_p / 1000000) .. ')'
    power_status_ico    = beautiful.power_notify_dc_ico
    left_time           = bat_n / bat_p
    if left_time >= 1 then
      hour              = math.ceil(left_time)
      min               = math.ceil(left_time % 1 * 60)
      if min ~= 0 then
        hour            = hour - 1
      end
      if hour == 1 then
        hour_unit       = ' hour '
      end
      if min == 1 then
        min_unit        = ' minute'
      end
      power_status_text = "Approximately " .. tostring(hour) .. hour_unit .. tostring(min) .. min_unit .. ' left. '
      bat_text          = bat_text .. ", approx. " .. tostring(hour) .. hour_unit .. tostring(min) .. min_unit .. ' left)'
    else
      hour              = 0
      min               = math.ceil(left_time * 60)
      if min == 1 then
        min_unit        = ' minute'
      end
      power_status_text = "Approximately " .. tostring(min) .. min_unit .. ' left. '
      bat_text          = bat_text .. ", approx. " .. tostring(min) .. min_unit .. ' left)'
    end
    if bat_perc <= 20 then
      lowbatnum = lowbatnum + 1
      if lowbatnum == 1 and naughty.getById(mywi.batpbar.notify_id) == nil then
          mywi.batpbar.notify_id = naughty.notify({title = "Low battery warnning!", text = "init", timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent, position = 'top_right', icon = beautiful.warn_icon, icon_size = 24, margin = 3}).id
      elseif lowbatnum == 30 then
        lowbatnum = 0
      end
      if naughty.getById(mywi.batpbar.notify_id) ~= nil then
        local leftstr = tostring(min) .. min_unit
        if hour > 0 then
          leftstr = tostring(hour) .. hour_unit .. tostring(min) .. min_unit
        end
        naughty.replace_text(naughty.getById(mywi.batpbar.notify_id), "Low battery warnning!", string.format("%.1f%% only, approx. %s left.", bat_perc, leftstr))
      end
    end
  end
  batpbar_t.text        = bat_text
  if show_bat_status then
    mywi.batpbar.inter_notify_id = naughty.notify({title = "Power status - " .. power_status_title, text = power_status_text == '' and bat_text or power_status_text, timeout = 0, position = 'top_middle', icon = power_status_ico, icon_size = 24, margin = 3}).id
    show_bat_status     = false
  elseif naughty.getById(mywi.batpbar.inter_notify_id) ~= nil then
    naughty.replace_text(naughty.getById(mywi.batpbar.inter_notify_id), "Power status - " .. power_status_title, power_status_text == '' and bat_text or power_status_text)
  end
end)
if bat_timer_init == false then
  bat_timer_init        = true
  bat_timer0:emit_signal('timeout')
  bat_timer1:emit_signal('timeout')
end

mywi.showBatStat = function()
  if naughty.getById(mywi.batpbar.inter_notify_id) == nil then
    show_bat_status     = true
    bat_timer1:emit_signal('timeout')
  else
    naughty.destroy(naughty.getById(mywi.batpbar.inter_notify_id))
  end
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
  delay_show        = beautiful.ttdelayshowtime
})

-- loop to check temperature
local temp_timer  = gears.timer({timeout = 10})
local temper      = 0
local hwmon_num   = 1
local fans_c      = ''
local fans        = 0
local temp_flag   = 0
temp_timer:connect_signal('timeout', function()
  temper          = tonumber(mytl.file_read('/sys/bus/platform/devices/coretemp.0/hwmon/hwmon1/temp1_input'))
  fans_c          = ''
  hwmon_num       = 1
  while fans_c == '' or fans_c == false do
    fans_c        = mytl.file_read('/sys/bus/platform/devices/thinkpad_hwmon/hwmon/hwmon' .. hwmon_num .. '/fan1_input', false)
    hwmon_num     = hwmon_num + 1
    if hwmon_num >= 10 then
      naughty.notify({title = "Get fan speed error", text = 'Too many tries, assign fan speed variable to \'-1\'.', timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
      fans_c      = '-1'
    end
  end
  fans            = tonumber(fans_c)
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

-- {{{ Show whole system CPU usage Start
local cpuubarC = wibox.widget {
  paddings     = 0,
  border_width = 0,
  colors       = {beautiful.graph_0},
  bg           = beautiful.fg_normal, 
  min_value    = 0,
  max_value    = 400,
  values       = {10},
  start_angle  = 1.57,
  rounded_edge = false,
  thickness    = 3,
  forced_width = 13,
  forced_height= 13,
  widget = wibox.container.arcchart,
}
mywi.cpuubar = wibox.widget {
  {
    cpuubarC,
    reflection = {horizontal = true, vertical = false},
    widget = wibox.container.mirror
  },
  bottom = 1,
  left   = 1,
  widget = wibox.container.margin
}
local cpuubar_t = awful.tooltip({
  objects = {mywi.cpuubar},
  delay_show = beautiful.ttdelayshowtime
})
local wholecputi_ii    = true -- init time?
local wholecputi_w0    = 0    -- warning 0 stage counter
local wholecputi_w1    = 0    -- warning 1 stage counter
local wholecputi_l     = 0
local wholecputi_timer = gears.timer({ timeout = 3 })
wholecputi_timer:start()
wholecputi_timer:connect_signal("timeout", function()
  local wocti0, wocti1, wocti2, wocti3, wocti4, wocti5, wocti6, wocti7, wocti8 = string.match(mytl.file_read('/proc/stat'), '(%d+)%s(%d+)%s(%d+)%s%d+%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)')
  local wholecputi   = wocti0 + wocti1 + wocti2 + wocti3 + wocti4 + wocti5 + wocti6 + wocti7 + wocti8
  local wholecputi_d = wholecputi - wholecputi_l
  wholecputi_l       = wholecputi
  if wholecputi_ii then
    wholecputi_ii = false
    return
  end
  local usePerc      = wholecputi_d / 3.012 / mytl.clockTicks * 100
  cpuubarC.values    = {usePerc}
  cpuubarC.max_value = mytl.clockTicks * mytl.cpun
  if usePerc / mytl.clockTicks / mytl.cpun > 0.6 then
    if wholecputi_w1 > 3 then
      cpuubarC.colors    = {beautiful.bg_urgent1}
      cpuubarC.thickness = 6
    else
      wholecputi_w1      = wholecputi_w1 + 1
    end
  elseif usePerc / mytl.clockTicks / mytl.cpun > 0.4 then
    if wholecputi_w0 > 2 then
      cpuubarC.colors    = {beautiful.graph_1}
      cpuubarC.thickness = 4
    else
      wholecputi_w0      = wholecputi_w0 + 1
    end
  else
    if wholecputi_w0 <= 0 then
      cpuubarC.colors    = {beautiful.graph_0}
      cpuubarC.thickness = 3
      wholecputi_w1      = 0
      wholecputi_w0      = 0
    else
      wholecputi_w0      = wholecputi_w0 - 2
    end
  end
  cpuubar_t:set_text(string.format("CPU usage(%d cores): %.1f%%", mytl.cpun, usePerc))
end)
wholecputi_timer:emit_signal("timeout")
-- Show whole system CPU usage End }}}

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
  beautiful.wallpaper = function(s, noFade)
    if s == nil then
      naughty.notify({title = "Random wallpaper err.", text = 'nil screen', timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
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
          naughty.notify({title = "Random wallpaper err.", text = string.format("[%d] %s: %s", wall_exco, wall_reas, wall_errs), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
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
          if beautiful.wallpaper_fade == true and noFade ~= true then
            smoothwp.fade(wall_path, s)
          else
            gears.wallpaper.maximized(wall_path, s, false)
          end
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
