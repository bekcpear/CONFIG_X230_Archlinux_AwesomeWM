-------------------------------------------------
-------------------------------------------------
-- Weather Widget based on the OpenWeatherMap
-- https://openweathermap.org/
-------------------------------------------------
-- Original url:
--   https://github.com/streetturtle/awesome-wm-widgets/blob/master/weather-widget/weather.lua
-- !!
-- !! This is a modified version::
-- !!
--  * Use breeze icons
--  * Add forecast (4 periods of time)
--  * support multiple cities
--  * use popup widget instead of notification to display
--  * remove socket.http and use curl to get json data asynchronously
--  * Modified by Bekcpear <i@ume.ink>
--  * require lua-luajson package on Archlinux
--
--  ** Usage:
--  **  Add following properties to theme, then require this module after theme
--  **   theme.weather_widget_city                       = {"Shanghai,CN", "Shenzhen,CN"} -- or "Shanghai,CN" for sigle city
--  **   theme.weather_widget_api_key                    = ""
--  **   theme.weather_widget_units                      = "metric" -- or imperial
--  ** the forecast configuration is now for UTC+8/9/10 only
-------------------------------------------------
-------------------------------------------------

local awful = require("awful")
local json = require("json")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local path_to_icons = "/usr/share/icons/breeze/applets/48/"

--- Maps openWeatherMap icons to Breeze icons
local icon_map = {
    ["01d"] = "weather-clear.svg",
    ["02d"] = "weather-few-clouds.svg",
    ["03d"] = "weather-clouds.svg",
    ["04d"] = "weather-overcast.svg",
    ["09d"] = "weather-showers-scattered.svg",
    ["10d"] = "weather-showers.svg",
    ["11d"] = "weather-storm.svg",
    ["13d"] = "weather-snow.svg",
    ["50d"] = "weather-fog.svg",
    ["01n"] = "weather-clear-night.svg",
    ["02n"] = "weather-few-clouds-night.svg",
    ["03n"] = "weather-clouds-night.svg",
    ["04n"] = "weather-overcast.svg",
    ["09n"] = "weather-showers-scattered.svg",
    ["10n"] = "weather-showers.svg",
    ["11n"] = "weather-storm.svg",
    ["13n"] = "weather-snow.svg",
    ["50n"] = "weather-fog.svg"
}

--- Return wind direction as a string.
local directions = {
    "N",
    "NNE",
    "NE",
    "ENE",
    "E",
    "ESE",
    "SE",
    "SSE",
    "S",
    "SSW",
    "SW",
    "WSW",
    "W",
    "WNW",
    "NW",
    "NNW",
    "N",
}
local function to_direction(degrees)
    -- Ref: https://www.campbellsci.eu/blog/convert-wind-directions
    if degrees == nil then
        return "风向未知"
    end
    return directions[math.floor((degrees % 360) / 22.5) + 1]
end

local city = {}
local cities
if type(beautiful.weather_widget_city) == "table" then
  cities = #beautiful.weather_widget_city
else
  cities   = 1
  city[1] = beautiful.weather_widget_city
end

local lastUpdate
local resp = {}
local respT = {}
local respTD = {}
local weather_widget = {}
local weather_timer = {}
local weather_emit_timer = {}

local hour, date, dateT, respJson
local function getResp(url, i, t)
  awful.spawn.easy_async("curl '" .. url .. "'", function(stdout, stderr, reason, exit_code)
    if exit_code == 0 then
      if t == 0 then
        resp[i]  = json.decode(stdout)
        if resp[i].cod ~= 200 then
          naughty.notify({title = "Get weather data error", text = string.format("Error data, status code: %s, URL: %s", resp[i].cod, url), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
        else
          weather_widget[i].image = path_to_icons .. icon_map[resp[i].weather[1].icon]
        end
      else
        respT[i] = json.decode(stdout)
        if respT[i].cod ~= "200" then
          naughty.notify({title = "Get forecase data error", text = string.format("Error data, status code: %s", respT[i].cod), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
        else
          hour  = tonumber(os.date("%H")) -- CST
          date  = os.date("%Y-%m-%d")
          dateT = os.date("%Y-%m-%d",
                          os.time{year=os.date("%Y"),
                                  month=os.date("%m"),
                                  day=os.date("%d") + 1})
          respTD    = {}
          respTD[1] = {}
          respTD[2] = {}
          respTD[3] = {}
          respTD[4] = {}
          if hour >= 2 and hour < 8 then
            respTD[1][1] = date  .. " 00:00:00" -- UTC
            respTD[2][1] = date  .. " 06:00:00"
            respTD[3][1] = date  .. " 12:00:00"
            respTD[4][1] = date  .. " 18:00:00"
            respTD[1][2] = "今早"
            respTD[2][2] = "今午"
            respTD[3][2] = "今晚"
            respTD[4][2] = "今夜"
          elseif hour >= 8 and hour < 14 then
            respTD[1][1] = date  .. " 06:00:00"
            respTD[2][1] = date  .. " 12:00:00"
            respTD[3][1] = date  .. " 18:00:00"
            respTD[4][1] = dateT .. " 00:00:00"
            respTD[1][2] = "今午"
            respTD[2][2] = "今晚"
            respTD[3][2] = "今夜"
            respTD[4][2] = "明早"
          elseif hour >= 14 and hour < 20 then
            respTD[1][1] = date  .. " 12:00:00"
            respTD[2][1] = date  .. " 18:00:00"
            respTD[3][1] = dateT .. " 00:00:00"
            respTD[4][1] = dateT .. " 06:00:00"
            respTD[1][2] = "今晚"
            respTD[2][2] = "今夜"
            respTD[3][2] = "明早"
            respTD[4][2] = "明午"
          elseif (hour >= 20 and hour <= 23) or (hour >= 0 and hour < 2) then
            respTD[1][1] = date  .. " 18:00:00"
            respTD[2][1] = dateT .. " 00:00:00"
            respTD[3][1] = dateT .. " 06:00:00"
            respTD[4][1] = dateT .. " 12:00:00"
            respTD[1][2] = "今夜"
            respTD[2][2] = "明早"
            respTD[3][2] = "明午"
            respTD[4][2] = "明晚"
          end
          respJson = respT[i]
          respT[i] = {}
          for j = 1, 30, 1 do
            if respJson.list[j].dt_txt == respTD[1][1] then
              respT[i][1] = respJson.list[j]
              respT[i][1].dt_txt_c = respTD[1][2]
            elseif respJson.list[j].dt_txt == respTD[2][1] then
              respT[i][2] = respJson.list[j]
              respT[i][2].dt_txt_c = respTD[2][2]
            elseif respJson.list[j].dt_txt == respTD[3][1] then
              respT[i][3] = respJson.list[j]
              respT[i][3].dt_txt_c = respTD[3][2]
            elseif respJson.list[j].dt_txt == respTD[4][1] then
              respT[i][4] = respJson.list[j]
              respT[i][4].dt_txt_c = respTD[4][2]
            end
          end
        end
      end
      lastUpdate = os.date("%H:%M")
    else
      naughty.notify({title = "Get weather data error", text = string.format("Exec: curl %s error, status: %s, %s, stderr: %s", url, exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
    end
  end)
end

local function myplacementforvolpopup(p, sg)
  local sw = sg['bounding_rect'].width
  local sx = sg['bounding_rect'].x
  local sy = sg['bounding_rect'].y
  local pw = p:geometry().width
  local ph = p:geometry().height
  p:geometry({x=sx + sw - pw - 150, y=21, width=pw, height=ph})
end

local url
for i = 1, cities, 1 do
  city[i] = city[i] ~= nil and city[i] or beautiful.weather_widget_city[i]
  weather_widget[i] = wibox.widget {
      {
          id = "icon",
          resize = true,
          widget = wibox.widget.imagebox,
      },
      layout = wibox.container.margin(_ , 0, 0, 0, 1),
      set_image = function(self, path)
          self.icon.image = path
      end,
  }

  weather_timer[i] = gears.timer({ timeout = 600 })
  weather_timer[i]:connect_signal("timeout", function ()
      url = 'https://api.openweathermap.org/data/2.5/weather?lang=zh_cn&q='
              .. city[i]
              .. '&appid=' .. beautiful.weather_widget_api_key
              .. '&units=' .. beautiful.weather_widget_units
      getResp(url, i, 0)
      url = 'https://api.openweathermap.org/data/2.5/forecast?lang=zh_cn&q='
              .. city[i]
              .. '&appid=' .. beautiful.weather_widget_api_key
              .. '&units=' .. beautiful.weather_widget_units
      getResp(url, i, 1)
  end)
  weather_timer[i]:start()
  weather_emit_timer[i] = gears.timer({ timeout = 1 })
  weather_emit_timer[i]:connect_signal("timeout", function ()
    weather_timer[i]:emit_signal("timeout")
    weather_emit_timer[i]:stop()
  end)
  weather_emit_timer[i]:start()

  --- Notification with weather information. Popups when mouse hovers over the icon
  local weather_pop, weather_pop_inner
  local popuped = false
  weather_widget[i]:connect_signal("mouse::enter", function()
    if popuped == false and resp ~= nil and respT[i] ~= nil then
      popuped = true
      weather_pop_inner = {
        {
          {
            {
              image  = path_to_icons .. icon_map[resp[i].weather[1].icon],
              resize = true,
              forced_width = 30,
              forced_height = 30,
              widget = wibox.widget.imagebox
            },
            margins = 5,
            layout  = wibox.container.margin,
          },
          {
            {
              markup =
                '<b>' .. city[i] .. '</b>\n'
                      .. '<span size="x-large"><b>' .. resp[i].weather[1].description
                      .. ' ' .. resp[i].main.temp .. '°'
                      .. (beautiful.weather_widget_units == 'metric' and 'C' or 'F')
                      .. '</b></span>\n' ..
                ' 湿度: ' .. resp[i].main.humidity .. '%\n' ..
                ' 气压: ' .. resp[i].main.pressure .. 'hPa\n' ..
                ' 云量: ' .. resp[i].clouds.all .. '%\n' ..
                ' 风速: ' .. resp[i].wind.speed .. 'm/s (' .. to_direction(resp[i].wind.deg) .. ')',
              align  = 'left',
              valign = 'center',
              forced_width = 180,
              forced_height = 100,
              widget = wibox.widget.textbox
            },
            margins = 5,
            layout  = wibox.container.margin,
          },
          layout = wibox.layout.fixed.horizontal
        },
        {
          thickness = 0.3,
          border_width = 0.2,
          forced_height = 10,
          forced_width = 230,
          widget = wibox.widget.separator
        },
      }
      for k = 1, #respT[i] do
        if respT[i][k] ~= nil then
          weather_pop_inner[#weather_pop_inner + 1] = {
            {
              {
                markup = '<small><b>' .. respT[i][k].dt_txt_c .. '</b></small>',
                align  = 'right',
                valign = 'center',
                forced_width = 20,
                forced_height = 20,
                widget = wibox.widget.textbox
              },
              top = 0,
              right = 0,
              bottom = 0,
              left = 10,
              layout  = wibox.container.margin,
            },
            {
              {
                image  = path_to_icons .. icon_map[respT[i][k].weather[1].icon],
                resize = true,
                forced_width = 20,
                forced_height = 20,
                widget = wibox.widget.imagebox
              },
              top = 0,
              right = 5,
              bottom = 0,
              left = 5,
              layout = wibox.container.margin,
            },
            {
              {
                markup = '<span size="large"><b>'
                          .. respT[i][k].weather[1].description
                          .. ' ' .. respT[i][k].main.temp .. '°'
                          .. (beautiful.weather_widget_units == 'metric' and 'C' or 'F')
                          .. '</b></span>',
                align  = 'left',
                valign = 'center',
                forced_width = 160,
                forced_height = 20,
                widget = wibox.widget.textbox
              },
              top = 0,
              right = 0,
              bottom = 0,
              left = 0,
              layout  = wibox.container.margin,
            },
            layout = wibox.layout.fixed.horizontal
          }
        end
      end
      weather_pop_inner[#weather_pop_inner + 1] = {
        {
          markup = '<span size="small">last update: ' .. lastUpdate .. '</span>',
          align  = 'right',
          valign = 'center',
          forced_width = 230,
          forced_height = 10,
          widget = wibox.widget.textbox
        },
        top     = 10,
        left    = 0,
        right   = -10,
        bottom  = 3,
        layout  = wibox.container.margin,
      }
      weather_pop_inner["layout"] = wibox.layout.fixed.vertical
      require 'pl.pretty'.dump(weather_pop_inner)
      weather_pop = awful.popup {
        widget = {
          weather_pop_inner,
          top     = 10,
          left    = 20,
          right   = 20,
          bottom  = 0,
          layout  = wibox.container.margin,
        },
        placement    = myplacementforvolpopup,
        visible      = true,
        ontop        = true,
        opacity      = beautiful.opacity,
      }
    end
  end)

  weather_widget[i]:connect_signal("mouse::leave", function()
    if weather_pop ~= nil then
      weather_pop.visible = false
    end
    weather_pop = nil
    popuped = false
  end)
end

local weather_inner = {}
for i = 1, #weather_widget do
  weather_inner[i] = weather_widget[i]
end
weather_inner["layout"] = wibox.layout.fixed.horizontal

local weather = wibox.widget {
  weather_inner,
  layout = wibox.container.margin
}

return weather
