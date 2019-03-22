--[[
-- @author Bekcpear <i@ume.ink>
-- @module myhok
--]]

local awful     = require("awful")
local naughty   = require("naughty")
local beautiful = require("beautiful")
local mytl      = require("themes.my.tl")

local myhok = {}

-- {{{ Show brightness Start
myhok.showbrightness_notify_id = 0
local brightness              = 0
local brightness_max          = 0
brightness_max                = tonumber(mytl.file_read('/sys/class/backlight/acpi_video0/max_brightness'))
myhok.showBrightness = function(act)
  brightness                  = tonumber(mytl.file_read('/sys/class/backlight/acpi_video0/brightness')) + act
  if brightness > brightness_max then
    brightness                = brightness_max
  elseif brightness < 0 then
    brightness                = 0
  end
  if naughty.getById(myhok.showbrightness_notify_id) ~= nil then
    naughty.replace_text(naughty.getById(myhok.showbrightness_notify_id), nil, string.format("Brightness: %d", brightness))
    naughty.reset_timeout(naughty.getById(myhok.showbrightness_notify_id), 1)
  else
    myhok.showbrightness_notify_id = naughty.notify({text = string.format("Brightness: %d", brightness), timeout = 1, position = 'bottom_middle'}).id
  end
end
-- Show brightness End }}}

-- toggle MIC mute
local mic_id, mic_name, l_mic_id, l_mic_name, l_mic_stat, l_mic_class
myhok.micmutetoggle = function()
  awful.spawn.easy_async('pactl list sources', function(stdout, stderr, reason, exit_code)
    if exit_code == 0 then
      for l_mic_id, l_mic_name, l_mic_stat, l_mic_class in string.gmatch(stdout, '[\n\r]*Source%s+#(%d+).-%s+Name:%s+([%a%d%.%-_]+).-%s+Mute:%s+(%a+).-%s+device%.class%s+=%s+"(%a+)') do
        if l_mic_class == 'sound' then
          mic_id    = l_mic_id
          mic_name  = l_mic_name
        end
      end
      mytl.s_easy_async("pactl set-source-mute " .. mic_id .. " toggle")
      naughty.notify({text="Mic toggle: " .. mic_name, timeout = 1})
    else
      naughty.notify({title = "Toggle MIC mute err.", text = string.format("Exec: pactl list sources error, status: %s, %s, stderr: %s", exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
    end
  end)
end
-- Volume widget End }}}

local c
-- {{{ make focused client center Start
myhok.ccenter = function()
  c = client.focus
  if c then
    if not c.fullscreen then
      c.maximized = false
      c.maximized_vertical = false
      c.maximized_horizontal = false
      c.floating = true
      c:geometry({
        x      = c.screen.geometry['x'] + c.screen.geometry['width'] / 7,
        y      = c.screen.geometry['y'] + c.screen.geometry['height'] / 6,
        width  = c.screen.geometry['width'] / 7 * 5,
        height = c.screen.geometry['height'] / 6 * 4,
      })
    end
  end
end
-- make focused client center End }}}

-- {{{ make focused client right Start
myhok.cright = function()
  c = client.focus
  if c then
    if not c.fullscreen then
      c.maximized = false
      c.maximized_vertical = false
      c.maximized_horizontal = false
      c.floating = true
      c:geometry({
        x      = c.screen.geometry['x'] + c.screen.geometry['width'] / 2,
        y      = c.screen.geometry['y'],
        width  = c.screen.geometry['width'] / 2,
        --height = c.screen.geometry['height'] / 6 * 4,
      })
      c.maximized_vertical = true
    end
  end
end
-- make focused client right End }}}

-- {{{ make focused client left Start
myhok.cleft = function()
  c = client.focus
  if c then
    if not c.fullscreen then
      c.maximized = false
      c.maximized_vertical = false
      c.maximized_horizontal = false
      c.floating = true
      c:geometry({
        x      = c.screen.geometry['x'],
        y      = c.screen.geometry['y'],
        width  = c.screen.geometry['width'] / 2,
        --height = c.screen.geometry['height'] / 6 * 4,
      })
      c.maximized_vertical = true
    end
  end
end
-- make focused client left End }}}

-- {{{ make focused client right-bottom Start
myhok.ccorner = function()
  c = client.focus
  if c then
    if not c.fullscreen then
      c.maximized = false
      c.maximized_vertical = false
      c.maximized_horizontal = false
      c.floating = true
      c:geometry({
        x      = c.screen.geometry['width'] / 2 - 200 + c.screen.geometry['x'],
        y      = c.screen.geometry['height'] / 2 - 180 + c.screen.geometry['y'],
        width  = c.screen.geometry['width'] / 2 + 80,
        height = c.screen.geometry['height'] / 2 + 100
      })
    end
  end
end
-- make focused client right-bottom End }}}


-- {{ increase/decrease floating client size Start
local orx, ory, orwidth, orheight, cratio, diffi
myhok.resfloatcli = function(inc)
  c = client.focus
  if c and c.floating and not c.fullscreen and not c.maximized and not c.maximized_vertical and not c.maximized_horizontal then
    orx, ory, orwidth, orheight = c.x, c.y, c.width, c.height
    cratio = orheight / orwidth
    if inc then
      diffi = 50
    else
      diffi = -50
    end
    c.x      = orx - diffi
    c.y      = ory - diffi * cratio
    c.width  = orwidth + diffi * 2
    c.height = c.width * cratio
    widthd   = c.width - orwidth - diffi * 2
    heightd  = c.height - orheight - diffi * cratio * 2
    if widthd > 0 then
      c.x  = c.x - math.abs(widthd / 2)
    elseif widthd < 0 then
      c.x  = c.x + math.abs(widthd / 2)
    end
    if heightd > 0 then
      c.y  = c.y - math.abs(heightd / 2)
    elseif heightd < 0 then
      c.y  = c.y + math.abs(heightd / 2)
    end
  end
end
-- increase/decrease floating client size End }}}

return myhok
