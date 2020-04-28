local renderer = require "renderer"

local keys = {}

function input_mode_key(e, val)
    if e.mode == 1 then
        --e.active_window.contents[e.cursors[1].line] = e.active_window.contents[e.cursors[1].line] .. val
        line = e.active_window.contents[e.cursors[1].line]
        line = line:sub(1, e.cursors[1].horizontal-1) .. val .. line:sub(e.cursors[1].horizontal)
        e.active_window.contents[e.cursors[1].line] = line
        e.cursors[1]:move(1,0,e)
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
        e.cursors[1]:move(-1, 0, e)
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

-- X
function x_handle(e)
    if e.mode == 0 then
        line = e.active_window.contents[e.cursors[1].line]
        line = line:sub(1, e.cursors[1].horizontal - 1) .. line:sub(e.cursors[1].horizontal + 1)
        e.active_window.contents[e.cursors[1].line] = line
    end
    input_mode_key(e, "x")
end
keys[120] = {handle=x_handle}

-- O
function o_handle(e)
    input_mode_key(e, "o")
    if e.mode == 0 then
        table.insert(e.active_window.contents, e.cursors[1].line + 1, " ")
        e.mode = 1
        e.cursors[1]:move(0, 1, e)
    end
end
keys[111] = {handle=o_handle}

return keys
