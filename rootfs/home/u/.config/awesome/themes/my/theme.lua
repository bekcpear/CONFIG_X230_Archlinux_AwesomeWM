--[[
-- written by Bekcpear <i@ume.ink>
--]]

local gears = require("gears")

local theme                                     = {}
theme.dir                                       = os.getenv("HOME") .. "/.config/awesome/themes/my"

theme.wallpaper                                 = theme.dir .. "/wall.png"
theme.wallpaper_dir                             = theme.dir .. "/wall_dir"
theme.wallpaper_switch_time                     = 1200 -- seconds

-- {{{ comment below to disable day/night wallpapers
theme.wallpaper_dir_day                         = theme.dir .. "/wall_dir_day"
theme.wallpaper_dir_night                       = theme.dir .. "/wall_dir_night"
theme.wallpaper_day_h_s                         = 7   --  daytime start hour for wallpaper
theme.wallpaper_night_h_s                       = 18  --  night start hour for wallpaper
-- }}}

theme.font                                      = "DejaVu Sans Mono 8"

theme.fg_normal                                 = "#bdbdbd"
theme.fg_focus                                  = "#ffffff"
theme.fg_urgent                                 = theme.fg_normal

theme.bg_normal                                 = "#000000"
theme.bg_focus                                  = "#000000"
theme.bg_warn                                   = "#ffee58"
theme.bg_urgent                                 = "#ef5350"
theme.bg_green                                  = "#66bb6a"

theme.graph_0                                   = "#78a4ff"
theme.graph_1                                   = "#ec407a"

theme.tooltip_fg                                = theme.fg_focus
theme.tooltip_bg                                = theme.bg_normal

theme.tasklist_fg_focus                         = theme.fg_normal
theme.tasklist_fg_normal                        = theme.fg_normal
theme.tasklist_bg_focus                         = theme.bg_focus
theme.tasklist_bg_normal                        = theme.bg_normal
theme.tasklist_spacing                          = 1
theme.tasklist_shape                            = gears.shape.rectangle
theme.tasklist_shape_focus                      = gears.shape.rounded_rect
theme.tasklist_shape_border_width_focus         = 0.5
theme.tasklist_shape_border_color_focus         = theme.fg_normal
theme.tasklist_fg_minimize                      = "#616161"
theme.tasklist_disable_icon                     = false

theme.taglist_fg_focus                          = theme.fg_focus
theme.taglist_fg_normal                         = theme.fg_normal
theme.taglist_bg_focus                          = "#111111"
theme.taglist_bg_normal                         = "#111111"

theme.titlebar_fg_normal                        = theme.tasklist_fg_minimize
theme.titlebar_fg_focus                         = theme.tasklist_fg_minimize
theme.titlebar_bg_normal                        = "#212121"
theme.titlebar_bg_focus                         = theme.bg_focus

theme.border_normal                             = theme.titlebar_bg_normal
theme.border_focus                              = theme.bg_focus
theme.border_width                              = 0

theme.useless_gap                               = 8

theme.awesome_icon                              = theme.dir .."/icons/awesome.png"
theme.dropdown_icon                             = theme.dir .."/icons/dropdown_icon.png"
theme.reboot_icon                               = theme.dir .."/icons/reboot_icon.png"
theme.suspend_icon                              = theme.dir .."/icons/suspend_icon.png"
theme.power_off_icon                            = theme.dir .."/icons/power_off_icon.png"
theme.lock_icon                                 = theme.dir .."/icons/lock_icon.png"
theme.exit_icon                                 = theme.dir .."/icons/exit_icon.png"

theme.taglist_squares_sel                       = theme.dir .. "/icons/square_unsel.png"
theme.taglist_squares_unsel                     = theme.dir .. "/icons/square_unsel.png"

theme.temp_graph_bot_normal                     = theme.dir .. "/icons/temp_bot_normal.png"
theme.temp_graph_bot_high                       = theme.dir .. "/icons/temp_bot_high.png"
theme.temp_graph_bot_warn                       = theme.dir .. "/icons/temp_bot_warn.png"

theme.bat_graph_charging_ico                    = theme.dir .. "/icons/power.png"
theme.bat_graph_charging_black_ico              = theme.dir .. "/icons/power_black.png"
theme.bat_graph_head_normal                     = theme.dir .. "/icons/power_head_normal.png"
theme.bat_graph_head_low                        = theme.dir .. "/icons/power_head_low.png"
theme.bat_graph_head_charging                   = theme.dir .. "/icons/power_head_charging.png"

theme.vol_ico                                   = theme.dir .. "/icons/vol.png"
theme.vol_low_ico                               = theme.dir .. "/icons/vol_low.png"
theme.vol_no_ico                                = theme.dir .. "/icons/vol_no.png"
theme.vol_mute_ico                              = theme.dir .. "/icons/vol_mute.png"

theme.net_ico                                   = theme.dir .. "/icons/net.png"
theme.net_wl_ico                                = theme.dir .. "/icons/net-wifi.png"
theme.net_off_ico                               = theme.dir .. "/icons/net-offline.png"

theme.layout_tileleft                           = theme.dir .. "/icons/tileleft.png"
theme.layout_tiletop                            = theme.dir .. "/icons/tiletop.png"
theme.layout_max                                = theme.dir .. "/icons/max.png"
theme.layout_magnifier                          = theme.dir .. "/icons/magnifier.png"
theme.layout_floating                           = theme.dir .. "/icons/floating.png"
theme.layout_cornerse                           = theme.dir .. "/icons/cornerse.png"

theme.titlebar_close_button_focus               = theme.dir .. "/icons/titlebar/close_focus.png"
theme.titlebar_close_button_normal              = theme.dir .. "/icons/titlebar/close_normal.png"
theme.titlebar_sticky_button_focus_active       = theme.dir .. "/icons/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active      = theme.dir .. "/icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive     = theme.dir .. "/icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive    = theme.dir .. "/icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_floating_button_focus_active     = theme.dir .. "/icons/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active    = theme.dir .. "/icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive   = theme.dir .. "/icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive  = theme.dir .. "/icons/titlebar/floating_normal_inactive.png"
theme.titlebar_maximized_button_focus_active    = theme.dir .. "/icons/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active   = theme.dir .. "/icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = theme.dir .. "/icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = theme.dir .. "/icons/titlebar/maximized_normal_inactive.png"
theme.titlebar_minimize_button_focus            = theme.dir .. "/icons/titlebar/minimize_focus.png"
theme.titlebar_minimize_button_normal           = theme.dir .. "/icons/titlebar/minimize_normal.png"

return theme
