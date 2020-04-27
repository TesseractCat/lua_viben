local renderer = require "renderer"

local keys = {}

function input_mode_key(e, val)
    if e.mode == 1 then
        e.active_window.contents[e.cursors[1].line] = e.active_window.contents[e.cursors[1].line] .. val
    end
end

-- Escape
function esc_handle(e)
    e.mode = 0
end
keys[27] = {handle=esc_handle} -- Escape

-- I
function i_handle(e)
    if e.mode == 0 then
        e.mode = 1
    end
    input_mode_key(e, "i")
end
keys[105] = {handle=i_handle} -- I

-- H
function h_handle(e)
    if e.mode == 0 then
        e.cursors[1]:move(-1, 0)
    end
    input_mode_key(e, "h")
end
keys[104] = {handle=h_handle} -- H

-- L
function l_handle(e)
    if e.mode == 0 then
        e.cursors[1]:move(0, 1)
        e.cursors[1].line = 2
    end
    input_mode_key(e, "l")
end
keys[108] = {handle=l_handle} -- L

return keys
