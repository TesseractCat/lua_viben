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
keys[27] = {handle=esc_handle}

-- I
function i_handle(e)
    input_mode_key(e, "i")
    if e.mode == 0 then
        e.mode = 1
    end
end
keys[105] = {handle=i_handle}

-- H
function h_handle(e)
    if e.mode == 0 then
        e.cursors[1]:move(-1, 0, e)
    end
    input_mode_key(e, "h")
end
keys[104] = {handle=h_handle}

-- L
function l_handle(e)
    if e.mode == 0 then
        e.cursors[1]:move(1, 0, e)
    end
    input_mode_key(e, "l")
end
keys[108] = {handle=l_handle}
 
-- J
function h_handle(e)
    if e.mode == 0 then
        e.cursors[1]:move(0, 1, e)
    end
    input_mode_key(e, "j")
end
keys[106] = {handle=h_handle}

-- K
function l_handle(e)
    if e.mode == 0 then
        e.cursors[1]:move(0, -1, e)
    end
    input_mode_key(e, "k")
end
keys[107] = {handle=l_handle}

return keys
