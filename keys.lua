local renderer = require "renderer"
local rex = require "rex_pcre2" -- lrexlib

local keys = {}

function input_mode_key(e, val)
    if e.mode == 1 then
        --e.active_window.contents[e.cursors[1].line] = e.active_window.contents[e.cursors[1].line] .. val
        line = e.active_window.contents[e.cursors[1].line]
        line = line:sub(1, e.cursors[1].horizontal-1) .. val .. line:sub(e.cursors[1].horizontal)
        e.active_window.contents[e.cursors[1].line] = line
        e.cursors[1]:move(val:len(),0,e)
    elseif e.mode == 5 then
        e.active_window.status = e.active_window.status .. val
    end
end

chars = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()-=+_[]{}|\\:;<>,.?/`~\'\""
for c in chars:gmatch(".") do
    keys[c:byte(1)] = {handle=function(e)
        input_mode_key(e, c)
    end}
end

nums = "123456789"
for n in nums:gmatch(".") do
    keys[n:byte(1)] = {handle=function(e)
        input_mode_key(e, n)
        if e.mode == 0 then
            e.mode = 3
            e.numerical_mode_data = tonumber(n)
        elseif e.mode == 3 then
            e.numerical_mode_data = tonumber(tostring(e.numerical_mode_data) .. n)
        end
    end}
end

-- 0
function zero_handle(e)
    input_mode_key(e, '0')
    if e.mode == 0 then
        e.cursors[1].horizontal = 1
        e.cursors[1].real_horizontal = 1
    elseif e.mode == 3 then
        e.numerical_mode_data = tonumber(tostring(e.numerical_mode_data) .. '0')
    end
end
keys[48] = {handle=zero_handle}

-- $
function dollar_handle(e)
    input_mode_key(e, '$')
    if e.mode == 0 then
        e.cursors[1].horizontal = e.active_window.contents[e.cursors[1].line]:len()
        e.cursors[1].real_horizontal = e.active_window.contents[e.cursors[1].line]:len()
    end
end
keys[36] = {handle=dollar_handle}

-- Escape
function esc_handle(e)
    if e.mode == 1 then
        e.cursors[1]:move(-1, 0, e)
    end
    e.mode = 0
    e.numerical_mode_data = 1
    
    e.active_window.status = 'PCRE2 (' .. rex.version() .. ')' .. ' VIB (0.0.1)'
end
keys[27] = {handle=esc_handle}

-- Backspace
function backspace_handle(e)
    if e.mode == 0 then
        e.cursors[1]:move(-1, 0, e)
    elseif e.mode == 1 then
        if e.cursors[1].horizontal == 1 then
            if e.cursors[1].line ~= 1 then
                -- Join lines
                prev_line_length = e.active_window.contents[e.cursors[1].line - 1]:len()
                e.active_window.contents[e.cursors[1].line] = e.active_window.contents[e.cursors[1].line - 1] .. e.active_window.contents[e.cursors[1].line]
                table.remove(e.active_window.contents, e.cursors[1].line - 1)
                e.cursors[1]:move(0, -1, e)
                e.cursors[1]:move(prev_line_length, 0, e)
            end
        else
            line = e.active_window.contents[e.cursors[1].line]
            line = line:sub(1, e.cursors[1].horizontal - 2) .. line:sub(e.cursors[1].horizontal)
            e.active_window.contents[e.cursors[1].line] = line
            e.cursors[1]:move(-1, 0, e)
        end
    elseif e.mode == 5 then
        e.active_window.status = e.active_window.status:sub(1, -2)
    end
end
keys[127] = {handle=backspace_handle}

-- Tab
function tab_handle(e)
    input_mode_key(e, "    ")
end
keys[9] = {handle=tab_handle}

-- Enter
function enter_handle(e)
    if e.mode == 1 then
        table.insert(e.active_window.contents, e.cursors[1].line + 1, " ")
        e.cursors[1]:move(0, 1, e)
    elseif e.mode == 5 then
        esc_handle(e)
    end
end
keys[13] = {handle=enter_handle}

-- Forward Slash
function forward_slash_handle(e)
    input_mode_key(e, '/')
    if e.mode == 0 then
        e.mode = 5
        e.active_window.status = "/"
    end
end
keys[47] = {handle=forward_slash_handle}

-- Colon
function colon_handle(e)
    input_mode_key(e, ':')
    if e.mode == 0 then
        e.mode = 5
        e.active_window.status = ":"
    end
end
keys[58] = {handle=colon_handle}

-- S
function s_handle(e)
    input_mode_key(e, 's')
    x_handle(e)
    i_handle(e)
end
keys[115] = {handle=s_handle}

-- I
function i_handle(e)
    input_mode_key(e, "i")
    if e.mode == 0 then
        --e.cursors[1]:move(-1, 0, e)
        if e.active_window.contents[e.cursors[1].line]:len() == 0 then
            e.active_window.contents[e.cursors[1].line] = " "
        end
        e.mode = 1
    end
end
keys[105] = {handle=i_handle}

-- A
function a_handle(e)
    input_mode_key(e, "a")
    if e.mode == 0 then
        --If at end of line
        if e.cursors[1].horizontal == e.active_window.contents[e.cursors[1].line]:len() then
            e.active_window.contents[e.cursors[1].line] = e.active_window.contents[e.cursors[1].line] .. " "
        end
        e.cursors[1]:move(1, 0, e)
        e.mode = 1
    end
end
keys[97] = {handle=a_handle}

-- H
function h_handle(e)
    if e.mode == 0 or e.mode == 3 then
        for i, c in ipairs(e.cursors) do
            c:move(-e.numerical_mode_data, 0, e)
        end
        if e.mode == 3 then
            esc_handle(e)
        end
    end
    input_mode_key(e, "h")
end
keys[104] = {handle=h_handle}

-- L
function l_handle(e)
    if e.mode == 0 or e.mode == 3 then
        for i, c in ipairs(e.cursors) do
            c:move(e.numerical_mode_data, 0, e)
        end
        if e.mode == 3 then
            esc_handle(e)
        end
    end
    input_mode_key(e, "l")
end
keys[108] = {handle=l_handle}
 
-- J
function j_handle(e)
    if e.mode == 0 or e.mode == 3 then
        for i, c in ipairs(e.cursors) do
            c:move(0, e.numerical_mode_data, e)
        end
        if e.mode == 3 then
            esc_handle(e)
        end
    end
    input_mode_key(e, "j")
end
keys[106] = {handle=j_handle}

-- K
function k_handle(e)
    if e.mode == 0 or e.mode == 3 then
        for i, c in ipairs(e.cursors) do
            c:move(0, -e.numerical_mode_data, e)
        end
        if e.mode == 3 then
            esc_handle(e)
        end
    end
    input_mode_key(e, "k")
end
keys[107] = {handle=k_handle}

-- X
function x_handle(e)
    if e.mode == 0 then
        line = e.active_window.contents[e.cursors[1].line]
        line = line:sub(1, e.cursors[1].horizontal - 1) .. line:sub(e.cursors[1].horizontal + 1)
        e.active_window.contents[e.cursors[1].line] = line
        
        -- Make sure cursor isn't out of bounds
        e.cursors[1]:move(0, 0, e)
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

-- Shift+O
function shift_o_handle(e)
    input_mode_key(e, "O")
    if e.mode == 0 then
        table.insert(e.active_window.contents, e.cursors[1].line, " ")
        e.mode = 1
        e.cursors[1]:move(0, 0, e)
    end
end
keys[79] = {handle=shift_o_handle}

-- D
function d_handle(e)
    if e.mode == 4 then
        table.remove(e.active_window.contents, e.cursors[1].line)
        e.mode = 0
        for i, c in ipairs(e.cursors) do
            c:move(0, 0, e)
        end
    elseif e.mode == 0 then
        e.mode = 4
    end
    input_mode_key(e, "d")
end
keys[100] = {handle=d_handle}

return keys
