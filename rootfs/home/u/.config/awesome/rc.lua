--[[
-- Modified by Bekcpear
--]]
-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
local cairo = require("lgi").cairo
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")

local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
--require("eminent")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init("/home/u/.config/awesome/themes/my/theme.lua")

local mywi  = require("themes.my.wi")
local myhok = require("themes.my.hok")
local mytl  = require("themes.my.tl")

-- This is used later as the default terminal and editor to run.
terminal    = "urxvt"
editor      = os.getenv("EDITOR") or "nano"
editor_cmd  = terminal .. " -e " .. editor
scrlock     = function() mytl.s_easy_async("i3lock -c002b36 -e") end

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.corner.se,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.top,
    awful.layout.suit.max,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating,
--    awful.layout.suit.tile,
--    awful.layout.suit.tile.bottom,
--    awful.layout.suit.fair,
--    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
--    awful.layout.suit.max.fullscreen,
--    awful.layout.suit.corner.nw,
--    awful.layout.suit.corner.ne,
--    awful.layout.suit.corner.sw,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
font_tmp         = beautiful.font
beautiful.font   = "DejaVu Sans Mono 10"
mytextclock_time = wibox.widget.textclock("%H:%M")
beautiful.font   = "DejaVu Sans Mono 6"
mytextclock_day  = wibox.widget.textclock("%d")
mytextclock_week = wibox.widget.textclock("%a")
beautiful.font   = font_tmp
mytextclock_date = wibox.widget {
  wibox.container.margin(mytextclock_day, 0, 0, 2, 10),
  wibox.container.margin(mytextclock_week, 0, 0, 10.5, 3),
  layout  = wibox.layout.stack
}
mytextclock      = wibox.widget {
  mytextclock_time,
  mywi.separator_empty,
  mytextclock_date,
  layout = wibox.layout.fixed.horizontal
}
awful.tooltip({
  objects = {mytextclock},
  delay_show = beautiful.ttdelayshowtime,
  timer_function = function()
    return os.date("Today is %A - %B %d, %Y\nThe time is %T")
  end,
})

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s, noFade)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper(s, noFade)
        else
            gears.wallpaper.maximized(wallpaper, s, true)
        end
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- power-buttons
powermenu = awful.menu({ items = {
                                   {
                                     "Reboot",
                                     function()
                                       mytl.s_easy_async("systemctl reboot")
                                     end,
                                     beautiful.reboot_icon
                                   },
                                   {
                                     "Suspend",
                                     function()
                                       mytl.s_easy_async("systemctl suspend")
                                     end,
                                     beautiful.suspend_icon
                                   },
                                   {
                                     "Power off",
                                     function()
                                       mytl.s_easy_async("systemctl poweroff")
                                     end,
                                     beautiful.power_off_icon
                                   },
                                   ----[[
                                   {
                                     text  = ' ────────────── ',
                                     theme = {
                                       fg_normal = "#424242",
                                       fg_focus  = "#424242"
                                     },
                                     new   = function(parent, args)
                                                local label = wibox.widget.textbox()
                                                label:set_font(args.theme.font)
                                                label:set_markup(args.text)
                                                local layout = wibox.layout.fixed.horizontal()
                                                layout:add(label)
                                                return {
                                                  label = label,
                                                  widget = layout,
                                                }
                                            end
                                   },
                                   --]]--
                                   {
                                     "Lock",
                                     scrlock,
                                     beautiful.lock_icon
                                   },
                                   {
                                     "Exit session",
                                     function()
                                       awesome.quit()
                                     end,
                                     beautiful.exit_icon
                                   }
                                 }
                       })
powerlauncher = awful.widget.launcher({
                                        image = beautiful.dropdown_icon,
                                        menu  = powermenu
                                      })

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s, true)
    -- Loop to re-set wallpaper
    gears.timer({timeout = beautiful.wallpaper_switch_time, autostart = true, callback = function() set_wallpaper(s) end})

    -- Each screen has its own tag table.
    awful.tag({ "Nor", "Ext", "Stt", "Mzx", "Sur", "Mai", "Des", "Dei", "Soc", "10", "11" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
      screen  = s,
      filter  = awful.widget.taglist.filter.noempty,
      buttons = taglist_buttons,
      widget_template = {
        {
          id     = 'background_role',
          forced_height = 5,
          wibox.widget.base.make_widget(),
          widget = wibox.container.background,
        },
        {
          {
            {
              {
                {
                  id     = 'index_role',
                  widget = wibox.widget.textbox,
                },
                margins = 4,
                widget  = wibox.container.margin,
              },
              bg     = '#333333',
              shape  = gears.shape.circle,
              widget = wibox.container.background,
            },
            top     = 3,
            bottom  = 3,
            visible = false,
            widget  = wibox.container.margin,
          },
          {
            {
              id     = 'icon_role',
              widget = wibox.widget.imagebox,
            },
            margins = 0,
            visible = false,
            widget  = wibox.container.margin,
          },
          {
            {
              id     = 'text_role',
              widget = wibox.widget.textbox,
            },
            left    = 7,
            right   = 7,
            top     = 2,
            bottom  = 5,
            widget  = wibox.container.margin,
          },
          layout = wibox.layout.fixed.horizontal,
        },
        forced_width = 32,
        layout = wibox.layout.align.vertical,
      },
    }
    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist{
      screen  = s,
      filter  = awful.widget.tasklist.filter.currenttags,
      buttons = tasklist_buttons,
      layout   = {
        spacing = 3,
        spacing_widget = {
          {
            color         = nil,
            border_color  = nil,
            forced_width  = 3,
            opacity       = 0,
            shape         = gears.shape.rectangle,
            widget        = wibox.widget.separator
          },
          valign = 'center',
          halign = 'center',
          widget = wibox.container.place,
        },
        layout  = wibox.layout.flex.horizontal
      },
      widget_template = {
        {
          {
            {
              {
                id     = 'icon_role',
                forced_height = 10,
                widget = wibox.widget.imagebox,
              },
              left    = 3,
              right   = 3,
              top     = 2,
              bottom  = 2,
              widget  = wibox.container.margin,
            },
            {
              {
                id     = 'text_role',
                widget = wibox.widget.textbox,
              },
              top     = 1,
              widget  = wibox.container.margin,
            },
            forced_height = 16,
            layout = wibox.layout.fixed.horizontal,
          },
          {
            id     = 'background_role',
            wibox.widget.base.make_widget(),
            widget = wibox.container.background,
          },
          layout = wibox.layout.align.vertical,
        },
        left  = 5,
        right = 10,
        bottom = 0,
        widget = wibox.container.margin
      },
    }

    -- Create the wibox
    -- s.mywibox = awful.wibar({ position = "top", screen = s, height = 18, bg = beautiful.bg_normal, fg = beautiful.fg_normal })
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mylayoutbox,
            mywi.separator,
            s.mytaglist,
            mywi.separator,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.systray(),
            mywi.separator,
            mywi.tempgraph,
            mywi.separator_empty,
            mywi.cpuubar,
            mywi.separator_empty,
            mywi.batpbar,
            mywi.separator_empty,
            mywi.netwidget,
            mywi.separator,
            mywi.volicon,
            mywi.sliderwidget,
            mywi.separator_empty,
            powerlauncher,
            mywi.separator,
            mytextclock,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 1, function () mytl.closeUnfocusedPopup() end)
--    awful.button({ }, 3, function () mymainmenu:toggle() end),
--    awful.button({ }, 4, awful.tag.viewnext),
--    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{
-- open terminal smartly
-- make the first terminal of corresponding tag floating and nice placed
local tagFirTers = {}
function openTerminal()
  local ntag = awful.screen.focused().selected_tag
  if tagFirTers[ntag.index] ~= true then -- for urxvt only
    mytl.s_easy_async("urxvt -name 'tagFirTer'")
  else
    mytl.s_easy_async("urxvt")
  end
end
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey, "Control" }, "i",
        function ()
            myhok.ccenter()
        end,
        {description = "make focused client center", group = "client"}
    ),
    awful.key({ modkey, "Control" }, "l",
        function ()
            myhok.cleft()
        end,
        {description = "make focused client left", group = "client"}
    ),
    awful.key({ modkey, "Control" }, "h",
        function ()
            myhok.cright()
        end,
        {description = "make focused client right", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () powermenu:show() end,
              {description = "show power menu", group = "awesome"}),
    awful.key({ modkey,           }, "i", scrlock,
              {description = "lock screen by i3lock", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey,           }, "a", function () set_wallpaper(awful.screen.focused(), true) end,
              {description = "change the current screen wallpaper randomly", group = "screen"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () openTerminal() end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function ()
                  awful.tag.incmwfact( 0.05)
                  myhok.resfloatcli(true)
                end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function ()
                  awful.tag.incmwfact(-0.05)
                  myhok.resfloatcli(false)
                end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),
    awful.key({ modkey }, "u", function() mytl.s_easy_async("/usr/bin/rofi -show window") end,
              {description = "pop up the selector of opening windows", group = "launcher"}),
    -- Show power status notification
    awful.key({ modkey }, "b", function() mywi.showBatStat() end,
              {description = "Toggle power status notification", group = "Device"}),
    -- Show brightness
    awful.key({}, "XF86MonBrightnessUp", function() myhok.showBrightness(1) end,
              {description = "Increase brightness", group = "Device"}),
    awful.key({}, "XF86MonBrightnessDown", function() myhok.showBrightness(-1) end,
              {description = "Decrease brightness", group = "Device"}),
    -- Volume
    awful.key({}, "Print", function() mytl.s_easy_async('/usr/bin/gnome-screenshot') end,
              {description = "Capture whole screen", group = "Media"}),
    awful.key({}, "XF86AudioMicMute", function() myhok.micmutetoggle() end,
              {description = "Toggle MIC mute", group = "Media"}),
    awful.key({}, "XF86AudioRaiseVolume", function() mywi.sliderbar.value = mywi.sliderbar.value + 5 end,
              {description = "Increase volume 5%", group = "Media"}),
    awful.key({}, "XF86AudioLowerVolume", function() mywi.sliderbar.value = mywi.sliderbar.value - 5 end,
              {description = "Decrease volume 5%", group = "Media"}),
    awful.key({}, "XF86AudioMute", function()
                  if mywi.sliderbar.handle_color == beautiful.fg_normal then mywi.sliderbar.handle_color = beautiful.bg_urgent
                  else mywi.sliderbar.handle_color = beautiful.fg_normal end
              end,
              {description = "Toggle mute", group = "Media"}),
    awful.key({ modkey, "Control" }, "a", function() mytl.s_easy_async("/usr/bin/flameshot gui") end,
              {description = "capture screen area", group = "Media"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Gimp",
          "Code",
          "netease-cloud-music",
          "TeamViewer",
          "Teamviewer",
          "bitcoin-qt",
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "pavucontrol",
          "Pavucontrol",
          "xtightvncviewer"},
        name = {
          "Event Tester",  -- xev.
--          "tagFirTer", -- first floating terminal
--          "Netease Music Box",
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    { rule_any = {
        role = {
          "GtkFileChooserDialog",
        }
      },
      properties = {
        floating = true,
        --x = awful.screen.focused().geometry['x'] + awful.screen.focused().geometry['width'] / 2 - client.focus.width / 2,
        --y = awful.screen.focused().geometry['y'] + awful.screen.focused().geometry['height'] / 2 - client.focus.height / 2
      },
      callback = function(c)
        c:relative_move(awful.screen.focused().geometry['width'] / 2 - c.width / 2, awful.screen.focused().geometry['height'] / 2 - c.height / 2, 0, 0)
      end
    },

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    -- Set to always map on the tag named "Mai".
    { rule = { instance = "^mail%.google%.com.+" },
      properties = { tag = "Mai", maximized = false, floating = false} },
    -- Set to always map on the tag named "Soc".
    { rule = { class = "Telegram" },
      properties = { tag = "Soc", maximized = false } },

    -- Set transparent
    { rule_any = {
        class = {
          "XTerm",
          "Sakura",
        }
      },
      properties = {
        opacity = beautiful.opacity
      }
    },
    { rule = {class = "netease-cloud-music", type = "utility"},
      properties = { sticky = true },
    },
    { rule_any = {
        class = {
          "netease-cloud-music",
        }
      },
      properties = {
        opacity = beautiful.opacity - 0.1,
      },
      callback = function(c)
        c:connect_signal("unfocus", function(c) c.opacity = beautiful.opacity - 0.3 end)
        c:connect_signal("focus", function(c) c.opacity = beautiful.opacity - 0.1 end)
      end
    },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

--    naughty.notify({title = "Test client prop.", text = tostring(c.class), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent})

    -- set Sakura terminal (running musicbox) geometry
    if c.name == "Netease Music Box" and c.class == "Sakura" then
      c.floating = true
      c:geometry({x = 16 + c.screen.geometry['x'], y = math.abs((c.screen.geometry['height'] - 540) / 2) + c.screen.geometry['y'], width = c.screen.geometry['width'] - 32, height = 500})
    end
    -- make the first terminal of corresponding tag floating and nice placed
    if c.name == "tagFirTer" then
      local ctag = c.first_tag
      tagFirTers[ctag.index] = true
      c.floating = true
      c:geometry({x = c.screen.geometry['width'] / 2 - 200 + c.screen.geometry['x'], y = c.screen.geometry['height'] / 2 - 180 + c.screen.geometry['y'], width = c.screen.geometry['width'] / 2 + 80, height = c.screen.geometry['height'] / 2 + 100})
      c:connect_signal("unmanage", function ()
        tagFirTers[ctag.index] = nil
      end)
    end

    c:connect_signal("button::press", function() mytl.closeUnfocusedPopup() end)

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    local pid = c.pid
    local title_name = wibox.widget {
      text   = 'PID: ' .. tostring(pid) .. ' ',
      align  = 'right',
      valign = 'center',
      font   = 'DejaVu Sans Mono 8',
      widget = wibox.widget.textbox
    }
    local title_name_tt = awful.tooltip({
      objects     = {title_name},
      delay_show  = beautiful.ttdelayshowtime,
      text        = tostring(c.name)
    })
    c:connect_signal('property::name', function()
      title_name_tt:set_text(tostring(c.name))
    end)

    if pid ~= nil then
      local client_info_timer = gears.timer {
        timeout   = 3,
        autostart = true,
        callback  = function(c)
          mytl.calcpuper(pid)
          local cpuu = mytl.cpuu[pid]
          if cpuu == nil then
            cpuu = "--"
          end
          title_name:set_text(string.format('CPU: %s | RSS: %s | PID: %s ', cpuu, mytl.getrss(pid), tostring(pid)))
        end
      }
      client_info_timer:emit_signal('timeout')
      c:connect_signal('unmanage', function()
        client_info_timer:stop()
        mytl.cpuu[pid] = nil
      end)
    end

    local titlebarbg = beautiful.titlebar_bg_normal
    if c.name and string.find(c.name, 'Cloud%sMusic$') ~= nil then -- for Netease Cloud Music Black Theme
      titlebarbg = "#222225"
    end
    awful.titlebar(c, {
        bg_normal = titlebarbg,
        bg_focus  = titlebarbg
      }) : setup {
        { -- Left
            awful.titlebar.widget.closebutton    (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.minimizebutton (c),
            awful.titlebar.widget.stickybutton   (c),
            --awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.floatingbutton (c),
            layout = wibox.layout.fixed.horizontal()
        },
        { -- Middle
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Right
            { -- PID & Title tooltip
                align  = "center",
                widget = title_name
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        layout = wibox.layout.align.horizontal
    }
--    elseif c.width then
--      -- suppose the height of titlebar is 20 pixel
--      -- transparency is 0.815 (#xxxxxxCC)
--      local ccmd = "/home/u/go/bin/getColor " .. tostring(math.floor(c.x + c.width / 2)) .. " " .. tostring(c.y + 22)
--      awful.spawn.easy_async_with_shell(ccmd, function(stdout, stderr, exit_reason, exit_code)
--        if exit_code ~= 0 then
--          naughty.notify({title = "Get a pixel color error", text = string.format("cmd: %s, status: %s, %s, stderr: %s", ccmd, exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
--        else
--          titlebarbg = "#" .. stdout
--          naughty.notify({text=titlebarbg})
--          awful.titlebar(c, {
--              bg_normal = titlebarbg,
--              bg_focus  = titlebarbg
--            }) : setup {
--              { -- Left
--                  awful.titlebar.widget.closebutton    (c),
--                  awful.titlebar.widget.maximizedbutton(c),
--                  awful.titlebar.widget.minimizebutton (c),
--                  awful.titlebar.widget.stickybutton   (c),
--                  --awful.titlebar.widget.ontopbutton    (c),
--                  awful.titlebar.widget.floatingbutton (c),
--                  layout = wibox.layout.fixed.horizontal()
--              },
--              { -- Middle
--                  buttons = buttons,
--                  layout  = wibox.layout.fixed.horizontal
--              },
--              { -- Right
--                  { -- PID & Title tooltip
--                      align  = "center",
--                      widget = title_name
--                  },
--                  buttons = buttons,
--                  layout  = wibox.layout.flex.horizontal
--              },
--              layout = wibox.layout.align.horizontal
--          }
--        end
--      end)
--    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c)
  c.border_color  = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
  c.border_color  = beautiful.border_normal

end)

-- Autorun programs
autorun = true
autorunApps =
{
  --"LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/u/s/local/lib64/ /home/u/s/local/bin/nextcloud",
  "nextcloud",
  "fcitx",
  "quiterss",
  "chromium --app=https://mail.google.com/mail/u/0/#inbox",
}
if autorun then
  for app = 1, #autorunApps do
    awful.spawn.easy_async_with_shell(autorunApps[app], function(o, e, er, ec)
      if ec ~= 0 then
        naughty.notify({title = "Autostart error", text = autorunApps[app] .. " :: " .. e, timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
      end
    end)
  end
end

-- }}}
