--------------------------------------------------------------------------------------------
-- @author moego <moego@moego.me> modified from Uli Schlachter's wallpaper.lua
-- @module smoothwp
-- Usage:
--   local smoothwp = require("theme.<yourtheme>.smoothwp")
--     smoothwp.fade(<wallpaper file path>, <screen object>)
-- if multi screens existed, this function will switch wallpapers one by one on the screen
-- the fade function will take up a lot of CPU resources in a short time
-- refer https://stackoverflow.com/questions/48378414/is-there-a-way-to-switch-the-wallpapers-with-a-fade-transition-effect-on-awesome
--------------------------------------------------------------------------------------------

local cairo = require("lgi").cairo
local color = require("gears.color")
local surface = require("gears.surface")
local timer = require("gears.timer")
local debug = require("gears.debug")
local root = root

local smoothwp = { mt = {} }

local function root_geometry()
    local width, height = root.size()
    return { x = 0, y = 0, width = width, height = height }
end

-- Information about a pending wallpaper change, see prepare_context()
local pending_wallpaper = nil

-- The fixed last source surface used when transitioning wallpaper,
-- see prepare_context()
local last_source       = nil
-- The active screen index, see smoothwp.fade()
local asindex           = -1
-- The buffered wallpaper paths, see smoothwp.fade()
local wpaths            = {}
-- The buffered screens that have not been switched wallpapers,
-- see prepare_context()
local screens           = {}


local function get_screen(s)
    return s and screen[s]
end

--- Prepare the needed state for setting a wallpaper.
-- This function returns a cairo context through which a wallpaper can be drawn.
-- The context is only valid for a short time and should not be saved in a
-- global variable.
-- @param s The screen to set the wallpaper on or nil for all screens
-- @return[1] The available geometry (table with entries width and height)
-- @return[1] A cairo context that the wallpaper should be drawn to
local function prepare_context(s)
    s = get_screen(s)

    local root_width, root_height = root.size()
    local geom = s and s.geometry or root_geometry()
    local source, target, cr

    if not pending_wallpaper then
        -- Prepare a pending wallpaper
        -- When transitioning the wallpaper, the source surface will be used
        -- many times. In order to simplify the calculation of transparency
        -- factor, it's necessary to save a base source surface for each
        -- transition.
        if last_source == nil then
            source = surface(root.wallpaper())
            last_source = surface.duplicate_surface(source)
        else
            source = last_source
        end
        target = source:create_similar(cairo.Content.COLOR, root_width, root_height)

        -- Set the wallpaper (delayed)
        timer.delayed_call(function()
            local paper = pending_wallpaper
            pending_wallpaper = nil
            smoothwp.set(paper.surface)
            paper.surface:finish()
        end)
    elseif root_width > pending_wallpaper.width or root_height > pending_wallpaper.height then
        -- The root window was resized while a wallpaper is pending
        if last_source == nil then
            source = pending_wallpaper.surface
            last_source = surface.duplicate_surface(source)
        else
            source = last_source
        end
        target = source:create_similar(cairo.Content.COLOR, root_width, root_height)
    else
        -- Draw to the already-pending wallpaper
        if last_source == nil then
            source = nil
            last_source = source
        else
            source = last_source
        end
        target = pending_wallpaper.surface
    end

    -- preparing the cario
    cr = cairo.Context(target)

    if source then
        -- Copy the old wallpaper to the new one
        cr:save()
        cr.operator = cairo.Operator.SOURCE
        cr:set_source_surface(source, 0, 0)
        cr:paint()
        cr:restore()
    end

    pending_wallpaper = {
        surface = target,
        width = root_width,
        height = root_height
    }

    cr:translate(geom.x, geom.y)
    cr:rectangle(0, 0, geom.width, geom.height)
    cr:clip()
    last_cario = cr

    return geom, cr
end

--- Set the current wallpaper.
-- @param pattern The wallpaper that should be set. This can be a cairo surface,
--   a description for gears.color or a cairo pattern.
-- @see gears.color
function smoothwp.set(pattern)
    if cairo.Surface:is_type_of(pattern) then
        pattern = cairo.Pattern.create_for_surface(pattern)
    end
    if type(pattern) == "string" or type(pattern) == "table" then
        pattern = color(pattern)
    end
    if not cairo.Pattern:is_type_of(pattern) then
        error("wallpaper.set() called with an invalid argument")
    end
    root.wallpaper(pattern._native)
end

--- Set a maximized wallpaper.
-- @param surf The wallpaper to set. Either a cairo surface or a file name.
-- @param s The screen whose wallpaper should be set. Can be nil, in which case
--   all screens are set.
-- @factor the transparency, from 0.0 to 1.0
local function maximized(surf, s, factor)
    local geom, cr = prepare_context(s)
    local original_surf = surf
    surf = surface.load_uncached(surf)

    -- scale the new source surface to fill the screen
    local w, h = surface.get_size(surf)
    local aspect_w = geom.width / w
    local aspect_h = geom.height / h
    aspect_h = math.max(aspect_w, aspect_h)
    aspect_w = math.max(aspect_w, aspect_h)
    cr:scale(aspect_w, aspect_h)
    local scaled_width = geom.width / aspect_w
    local scaled_height = geom.height / aspect_h
    cr:translate((scaled_width - w) / 2, (scaled_height - h) / 2)

    -- Draw new wallpaper according to transparency
    cr:set_source_surface(surf, 0, 0)
    cr.operator = cairo.Operator.SOURCE
    cr:paint_with_alpha(factor)
    if surf ~= original_surf then
        surf:finish()
    end
    if cr.status ~= "SUCCESS" then
        debug.print_warning("Cairo context entered error state: " .. cr.status)
    end
end

--- Push unprocessed wallpapers and screens into the buffer
-- @param p the unprocessed wallpaper path
-- @param s the unprocessed screen
local function pushFade(p, s)
    for i = 1, table.maxn(screens) do
        if s.index == screens[i].index then
            return
        end
    end
    table.insert(wpaths, p)
    table.insert(screens, s)
end

--- Pull a pair of an unprocessed wallpaper and the coresponding screen
local function pullFade()
    local p, s
    p = table.remove(wpaths, 1)
    s = table.remove(screens, 1)
    return p, s
end

--- Switch wallpapers with a fade transition
--- Setting the wallpaper is for the entire root area, there is no way to
--set to a specical screen. So in order to achieve the effect of wallpaper
--transition on each screen, I have to switch one screen after another.
--- Steps and the interval time determine the overall time required to switch
--once. The specific time will vary depending on the performance of the
--computer, please adjust by yourself.
-- @param wpath a new wallpaper path
-- @param s the corrensponding screen
function smoothwp.fade(wpath, s)
    local steps      = 120
    local steps_done = 0
    local interval   = 1/60
    if asindex == -1 then
        asindex = s.index
    else
        if s.index ~= asindex then
            pushFade(wpath, s)
            return
        end
    end

    timer.start_new(interval, function()
        steps_done = steps_done + 1
        maximized(wpath, s, steps_done / steps)
        if steps_done / steps == 1 then
            last_source = nil
            asindex = -1
            wpath, s = pullFade()
            if wpath ~= nil and s ~= nil then
                smoothwp.fade(wpath, s)
            end
        end
        return steps_done < steps
    end)
end

return smoothwp

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
