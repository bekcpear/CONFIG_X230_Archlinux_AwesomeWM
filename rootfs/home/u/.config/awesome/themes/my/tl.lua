--[[
-- @author Bekcpear <i@ume.ink>
-- @module mytl
--]]

local awful     = require("awful")
local gears     = require("gears")
local naughty   = require("naughty")
local beautiful = require("beautiful")

local mytl = {}

-- {{{ an asynchronous executer with error reporter Start
mytl.s_easy_async = function(cmd)
  awful.spawn.easy_async("/usr/bin/bash -c '" .. cmd .. "'", function(stdout, stderr, reason, exit_code)
    if exit_code ~= 0 then
      naughty.notify({title = "EXEC: " .. cmd .. " ERR.", text = string.format("[%s] %s, %s", exit_code, reason, stderr), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
    end
  end)
end
-- an asynchronous executer with error reporter End }}}

-- {{{ a file reader Start
-- @param0 file path
-- @param1 report error? default is true
-- @param2 file read mode, default(false) is line
-- return the readed file content (one line or whole file content)
local file        = {}
local file_s      = {}
local file_err    = {}
local file_err_no = {}
local file_i      = 0
mytl.file_read = function(name, notify_err, read_mode)
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
    naughty.notify({title = "Read file err.", text = string.format("[%s] %s", tostring(file_err_no[file_i]), tostring(file_err[file_i])), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
  end
  return false
end
-- a file reader End }}}

-- {{{ Get rss Start
local rss = 0
mytl.getrss = function(pid)
  rss     = tonumber(string.match(mytl.file_read('/proc/' .. tostring(pid) .. '/statm'), '%d+%s+(%d+)')) * 4
  if rss < 1024 then -- KiB
    rss   = tostring(rss) .. ' KiB'
  elseif rss >= 1024 and rss / 1024 < 1024 then -- MiB
    rss   = string.format('%.2f MiB', rss / 1024)
  else -- GiB
    rss   = string.format('%.2f GiB', rss / 1024 / 1024)
  end
  return rss
end
-- Get rss End }}}

-- {{{ Calculate current CPU usage by percentage of an awesome client Start
mytl.cpuu       = {} -- table to store the corresponding process cpu usage 
mytl.clockTicks = nil
mytl.cpun       = nil
-- use an external C program to get clock ticks and cpu numbers
-- #include <stdio.h>
-- #include <unistd.h>
-- #include <sys/sysinfo.h>
-- int main()
-- {
--     fprintf(stdout, "%ld %d", sysconf(_SC_CLK_TCK), get_nprocs());
--    return 0;
-- }
local getCpuInfoCmd    = beautiful.dir .. '/getClkTckAndProcNum'
awful.spawn.easy_async_with_shell(getCpuInfoCmd, function(so, se, er, ec)
  if ec ~= 0 then
    mytl.clockTicks, mytl.cpun     = 100, 1
    naughty.notify({title = "EXEC: " .. getCpuInfoCmd .. " ERR.", text = string.format("[%s] %s, %s", ec, er, se), timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
    return
  end
  mytl.clockTicks, mytl.cpun     = string.match(so, '(%d+)%s(%d+)')
  if mytl.clockTicks == -1 then
    naughty.notify({title = "GET ERR: Clock Ticks ", timeout = 0, fg = beautiful.taglist_fg_focus, bg = beautiful.bg_urgent, border_color = beautiful.bg_urgent})
  end
end)
--local wholecputipi
--local wholecputi_d     = 0  -- whole cpu clock ticks per second
--local wholecputi_l     = 0  -- last whole cpu clock ticks
--local wholecputi_tout  = 60 -- refresh period (second)
--local wholecputi_get = function(initStep)
--  wholecputifi = mytl.file_read('/proc/stat')
--  local wholecputi_c   = 0
--  for wholecputipi in string.gmatch(wholecputifi, '%d+') do
--    wholecputi_c = wholecputi_c + wholecputipi
--  end
--  if wholecputi_l ~= 0 then
--    wholecputi_d = wholecputi_c - wholecputi_l
--    if initStep == nil then
--      wholecputi_d = wholecputi_d / wholecputi_tout
--    end
--    naughty.notify({text=tostring(wholecputi_d), timeout=0})
--  end
--  wholecputi_l = wholecputi_c
--end
--local wholecputi_timer0 = gears.timer({ timeout = 1 })
--local wholecputi_timer1 = gears.timer({ timeout = wholecputi_tout })
--wholecputi_timer0:start()
--wholecputi_timer0:connect_signal("timeout", function()
--  wholecputi_get(true)
--  if wholecputi_d ~= 0 then
--    wholecputi_timer0:stop()
--    wholecputi_timer1:start()
--  end
--end)
--wholecputi_timer1:connect_signal("timeout", function() wholecputi_get() end)
--wholecputi_timer0:emit_signal("timeout")
local proccputi_lx = 0
mytl.calcpuper = function(pid)
  -- 計算方法：
  -- 獲取當前進程被分配到的總 Clock Ticks，這裏獲取到的 ticks 是被當前系統設定的每秒觸發的 Clock Ticks 所整除的
  -- 一般設定的每秒的 Clock Ticks 是 100，我的系統通過 sysconf(_SC_CLK_TCK) 查看，確認是 100
  -- 也就是每秒觸發 100 個 Clock Ticks，而這裏通過計算一秒週期內，該進程被分配到的 Clock Ticks 就可以直接求出該進程的 CPU 使用百分比
  -- 比如求得 2977 進程一秒內被分配到 12 個 Clock Ticks，而系統設定了一秒可以執行 100 個 Clock Ticks，所以該進程的 CPU 使用率就是 12%
  -- 而 Clock Tick 的觸發是由 PIT 通道 0 計數器減到 0 的時候觸發的，具體真實時間根據 CPU 時鐘週期來定，不用特別理會
  -- 同樣的，因爲多核 CPU 有多個線程，所以 CPU 使用率能出現超過 100% 的情況，具體最高能到多少由 CPU 線程數決定，比如四核 CPU 可以到 400%
  -- TODO: calculate all child processes' cpu useage
  local proccputireg = '[^%s]+%s[^%s]+%s[^%s]+%s[^%s]+%s[^%s]+%s[^%s]+%s[^%s]+%s[^%s]+%s[^%s]+%s[^%s]+%s[^%s]+%s[^%s]+%s[^%s]+%s([^%s]+)%s([^%s]+)%s([^%s]+)%s([^%s]+)%s'
  local proccputi0, proccputi1, proccputi2, proccputi3  = string.match(mytl.file_read('/proc/' .. pid .. '/stat'), proccputireg)
  local proccputi_l = proccputi0 + proccputi1 + proccputi2 + proccputi3
  gears.timer.weak_start_new(2.8, function()
    proccputi0, proccputi1, proccputi2, proccputi3  = string.match(mytl.file_read('/proc/' .. pid .. '/stat', false), proccputireg)
    if proccputi0 == nil then
      return
    end
    local proccputi_d = proccputi0 + proccputi1 + proccputi2 + proccputi3 - proccputi_l
    mytl.cpuu[pid] = string.format("%.1f%%", proccputi_d / 2.8 / mytl.clockTicks * 100)
  end)
end
-- Calculate current CPU usage by percentage of an awesome client End }}}

-- {{{ Close unfocused popup widget Start
mytl.closeUnfocusedPopup = function()
  mytl.popVol.visible = false
  mytl.popVol_visible = false
end
-- Close unfocused popup widget End}}}


return mytl

