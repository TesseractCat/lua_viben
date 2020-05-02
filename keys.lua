local renderer = require "renderer"
local rex = require "rex_pcre2" -- lrexlib
local cursor = require "cursor"
local commands = require "commands"

local keys = {}

function input_mode_key(e, val)
    if e.mode == 1 then
        -- Input mode
        --e.active_window.contents[e.active_cursor.line] = e.active_window.contents[e.active_cursor.line] .. val
        for i, c in ipairs(e.cursors) do
            line = e.active_window.contents[c.line]
            line = line:sub(1, c.horizontal-1) .. val .. line:sub(c.horizontal)
            e.active_window.contents[c.line] = line
            c:move(val:len(),0,e)
            
            -- Move all following cursors on the same line
            for k, fc in ipairs(e.cursors) do
                if fc.line == c.line and fc ~= c and fc.horizontal > c.horizontal then
                    fc:move(val:len(),0,e)
                end
            end
        end
        return true
    elseif e.mode == 5 then
        -- C-LINE mode
        e.active_window.status = e.active_window.status .. val
        return true
    elseif e.mode == 6 then
        -- WFK mode
        e.wfk_mode_data(e, val)
        return true
    end
    return false
end

chars = " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()-=+_[]{}|\\:;<>,.?/`~\'\""
for c in chars:gmatch(".") do
    keys[c:byte(1)] = {handle=function(e)
        if input_mode_key(e, c) then return end
    end}
end

nums = "123456789"
for n in nums:gmatch(".") do
    keys[n:byte(1)] = {handle=function(e)
        if input_mode_key(e, n) then return end
        if e.mode == 0 or e.mode == 2 then
            e.last_mode = e.mode
            e.mode = 3
            e.numerical_mode_data = tonumber(n)
        elseif e.mode == 3 then
            e.numerical_mode_data = tonumber(tostring(e.numerical_mode_data) .. n)
        end
    end}
end

-- 0
function zero_handle(e)
    if input_mode_key(e, '0') then return end
    if e.mode == 0 or e.mode == 2 then
        for i, c in ipairs(e.cursors) do
            c:move_abs(1, nil, e)
        end
    elseif e.mode == 3 then
        e.numerical_mode_data = tonumber(tostring(e.numerical_mode_data) .. '0')
    end
end
keys[48] = {handle=zero_handle}

-- $
function dollar_handle(e)
    if input_mode_key(e, '$') then return end
    if e.mode == 0 or e.mode == 2 then
        for i, c in ipairs(e.cursors) do
            c:move_abs(e.active_window.contents[c.line]:len(), nil, e)
            c.real_horizontal = 10000
        end
    end
end
keys[36] = {handle=dollar_handle}

-- Escape
function esc_handle(e)
    if e.mode == 1 then
        for i, c in ipairs(e.cursors) do
            c:move(-1, 0, e)
        end
        e.mode = 0
    elseif e.mode == 0 then
        -- Remove extra cursors
        e.cursors = {e.active_cursor}
        e.mode = 0
    elseif e.mode == 2 then
        -- Remove selection lengths
        for i, c in ipairs(e.cursors) do
            c.range = false
            c:zero_range()
        end
        e.mode = 0
    elseif e.mode == 6 or e.mode == 3 then
        -- WFK mode, set mode to last mode
        e.mode = e.last_mode
    end
    e.last_mode = 0
    e.numerical_mode_data = 1
    
    --e.active_window.status = 'PCRE2 (' .. rex.version() .. ')' .. ' VIB (0.0.1)'
end
keys[27] = {handle=esc_handle}

-- Backspace
function backspace_handle(e)
    if e.mode == 0 then
        for i, c in ipairs(e.cursors) do
            c:move(-1, 0, e)
        end
    elseif e.mode == 1 then
        for i, c in ipairs(e.cursors) do
            if c.horizontal == 1 then
                if c.line ~= 1 then
                    -- Join lines
                    prev_line_length = e.active_window.contents[c.line - 1]:len()
                    e.active_window.contents[c.line] = e.active_window.contents[c.line - 1] .. e.active_window.contents[c.line]
                    table.remove(e.active_window.contents, c.line - 1)
                    c:move(0, -1, e)
                    c:move(prev_line_length, 0, e)
                end
            else
                line = e.active_window.contents[c.line]
                line = line:sub(1, c.horizontal - 2) .. line:sub(c.horizontal)
                e.active_window.contents[c.line] = line
                c:move(-1, 0, e)
                
                -- Move all following cursors on the same line
                for k, fc in ipairs(e.cursors) do
                    if fc.line == c.line and fc ~= c and fc.horizontal > c.horizontal then
                        fc:move(-1,0,e)
                    end
                end
            end
        end
    elseif e.mode == 5 then
        e.active_window.status = e.active_window.status:sub(1, -2)
    end
    --e.active_window.status = e.active_cursor:get_contents(e.active_window.contents)
end
keys[127] = {handle=backspace_handle}

-- Tab
function tab_handle(e)
    if input_mode_key(e, "    ") then return end
end
keys[9] = {handle=tab_handle}

-- Enter
function enter_handle(e)
    if e.mode == 1 then
        for i, c in ipairs(e.cursors) do
            table.insert(e.active_window.contents, c.line + 1, " ")
            -- Move all the following cursors on different lines
            for k, fc in ipairs(e.cursors) do
                if fc ~= c and fc.line > c.line then
                    fc:move(0,1,e)
                end
            end
            c:move(0, 1, e)
        end
    elseif e.mode == 5 then
        commands:process(e)
    end
end
keys[13] = {handle=enter_handle}

-- Forward Slash
function forward_slash_handle(e)
    if input_mode_key(e, '/') then return end
    if e.mode == 0 then
        e.mode = 5
        e.active_window.status = "/"
    end
end
keys[47] = {handle=forward_slash_handle}

-- Colon
function colon_handle(e)
    if input_mode_key(e, ':') then return end
    if e.mode == 0 then
        e.mode = 5
        e.active_window.status = ":"
    end
end
keys[58] = {handle=colon_handle}

-- Ctrl + J
function ctrl_j_handle(e)
    if e.mode == 0 and e.active_cursor.line < #e.active_window.contents then
        -- Need to check if there already is a cursor here
        table.insert(e.cursors, cursor:new{
            line=e.active_cursor.line+1,
            horizontal=e.active_cursor.horizontal,
            real_horizontal=e.active_cursor.real_horizontal
        })
        e.active_cursor = e.cursors[#e.cursors]
        e.active_cursor:move(0, 0, e)
        
        -- Sort
        table.sort(e.cursors, e.compare_cursors)
    end
end
keys[10] = {handle=ctrl_j_handle}

-- Ctrl + K
function ctrl_k_handle(e)
    if e.mode == 0 and e.active_cursor.line > 1 then
        -- Need to check if there already is a cursor here
        table.insert(e.cursors, cursor:new{
            line=e.active_cursor.line-1,
            horizontal=e.active_cursor.horizontal,
            real_horizontal=e.active_cursor.real_horizontal
        })
        e.active_cursor = e.cursors[#e.cursors]
        e.active_cursor:move(0, 0, e)
        
        -- Sort
        table.sort(e.cursors, e.compare_cursors)
    end
end
keys[11] = {handle=ctrl_k_handle}

-- V
function v_handle(e)
    if input_mode_key(e, "v") then return end
    if e.mode == 0 then
        e.mode = 2
        for i, c in ipairs(e.cursors) do
            c:zero_range()
            c.range = true
        end
    end
end
keys[118] = {handle=v_handle}

-- N
function n_handle(e)
    if input_mode_key(e, "n") then return end
    if e.mode == 0 and #e.cursors > 1 then
        -- Sort
        table.sort(e.cursors, e.compare_cursors)
        
        for i, c in ipairs(e.cursors) do
            if c == e.active_cursor then
                if i ~= #e.cursors then
                    e.active_cursor = e.cursors[i + 1]
                else
                    e.active_cursor = e.cursors[1]
                end
                return
            end
        end
    end
end
keys[110] = {handle=n_handle}

-- Q
function q_handle(e)
    if input_mode_key(e, "q") then return end
    if e.mode == 0 and #e.cursors > 1 then
        table.remove(e.cursors, 1)
    end
end
keys[113] = {handle=q_handle}

-- Shift+H
function shift_h_handle(e)
    if input_mode_key(e, "H") then return end
    if e.mode == 0 then
        for i, c in ipairs(e.cursors) do
            char_horizontal, _, _ = rex.find(e.active_window.contents[c.line], "[^\\s]")
            c:move_abs(char_horizontal, nil, e)
        end
    end
end
keys[72] = {handle=shift_h_handle}

-- S
function s_handle(e)
    if input_mode_key(e, 's') then return end
    x_handle(e)
    i_handle(e)
end
keys[115] = {handle=s_handle}

-- I
function i_handle(e)
    if input_mode_key(e, "i") then return end
    if e.mode == 0 then
        for i, c in ipairs(e.cursors) do
            if e.active_window.contents[c.line]:len() == 0 then
                e.active_window.contents[c.line] = " "
            end
        end
        e.mode = 1
    end
end
keys[105] = {handle=i_handle}

-- A
function a_handle(e)
    if input_mode_key(e, "a") then return end
    if e.mode == 0 then
        --If at end of line
        for i, c in ipairs(e.cursors) do
            if c.horizontal == e.active_window.contents[c.line]:len() then
                e.active_window.contents[c.line] = e.active_window.contents[c.line] .. " "
            end
            c:move(1, 0, e)
        end
        e.mode = 1
    end
end
keys[97] = {handle=a_handle}

-- H
function h_handle(e)
    if input_mode_key(e, "h") then return end
    if e.mode == 0 or e.mode == 3 then
        -- Command mode or numerical mode
        for i, c in ipairs(e.cursors) do
            c:move(-e.numerical_mode_data, 0, e)
        end
        if e.mode == 3 then
            esc_handle(e)
        end
    elseif e.mode == 2 then
        -- Visual mode
        for i, c in ipairs(e.cursors) do
            c:move(-1, 0, e)
        end
    end
end
keys[104] = {handle=h_handle}

-- L
function l_handle(e)
    if input_mode_key(e, "l") then return end
    if e.mode == 0 or e.mode == 3 then
        -- Command mode or numerical mode
        for i, c in ipairs(e.cursors) do
            c:move(e.numerical_mode_data, 0, e)
        end
        if e.mode == 3 then
            esc_handle(e)
        end
    elseif e.mode == 2 then
        -- Visual mode
        for i, c in ipairs(e.cursors) do
            c:move(1, 0, e)
        end
    end
end
keys[108] = {handle=l_handle}
 
-- J
function j_handle(e)
    if input_mode_key(e, "j") then return end
    if e.mode == 0 or e.mode == 3 then
        for i, c in ipairs(e.cursors) do
            c:move(0, e.numerical_mode_data, e)
        end
        if e.mode == 3 then
            esc_handle(e)
        end
    elseif e.mode == 2 then
        -- Visual mode
        for i, c in ipairs(e.cursors) do
            c:move(0, 1, e)
        end
    end
end
keys[106] = {handle=j_handle}

-- K
function k_handle(e)
    if input_mode_key(e, "k") then return end
    if e.mode == 0 or e.mode == 3 then
        for i, c in ipairs(e.cursors) do
            c:move(0, -e.numerical_mode_data, e)
        end
        if e.mode == 3 then
            esc_handle(e)
        end
    elseif e.mode == 2 then
        -- Visual mode
        for i, c in ipairs(e.cursors) do
            c:move(0, -1, e)
        end
    end
end
keys[107] = {handle=k_handle}

-- X
function x_handle(e)
    if input_mode_key(e, "x") then return end
    if e.mode == 0 or e.mode == 2 then
        for i, c in ipairs(e.cursors) do
            c:set_contents(e.active_window.contents, "")
            
            -- Make sure cursor isn't out of bounds
            c:sort_sides()
            c:zero_range()
            c:move(0, 0, e)
            c.real_horizontal = c.horizontal
        end
        if e.mode == 2 then
            esc_handle(e)
        end
    end
end
keys[120] = {handle=x_handle}

-- O
function o_handle(e)
    if input_mode_key(e, "o") then return end
    if e.mode == 0 then
        table.insert(e.active_window.contents, e.active_cursor.line + 1, " ")
        e.mode = 1
        e.active_cursor:move(0, 1, e)
    elseif e.mode == 2 then
        for i, c in ipairs(e.cursors) do
            c:swap_sides()
        end
    end
end
keys[111] = {handle=o_handle}

-- Shift+O
function shift_o_handle(e)
    if input_mode_key(e, "O") then return end
    if e.mode == 0 then
        table.insert(e.active_window.contents, e.active_cursor.line, " ")
        e.mode = 1
        e.active_cursor:move(0, 0, e)
    end
end
keys[79] = {handle=shift_o_handle}

-- D
function d_handle(e)
    if input_mode_key(e, "d") then return end
    if e.mode == 4 then
        for i=#e.cursors,1,-1 do
            table.remove(e.active_window.contents, e.cursors[i].line)
            e.cursors[i]:move(0, 0, e)
        end
        e.mode = 0
    elseif e.mode == 0 then
        e.mode = 4
    elseif e.mode == 2 then
        x_handle(e)
    end
end
keys[100] = {handle=d_handle}

-- F
function f_handle_wfk(e, val)
    for i, c in ipairs(e.cursors) do
        remaining_line = e.active_window.contents[c.line]:sub(c.horizontal+1)
        offset, _, _ = rex.find(remaining_line, val)
        if offset ~= nil then
            c:move(offset, 0, e)
        end
    end
    esc_handle(e)
end
function f_handle(e)
    if input_mode_key(e, "f") then return end
    if e.mode == 0 then
        e.mode = 6
        e.wfk_mode_data = f_handle_wfk
    elseif e.mode == 2 then
        e.mode = 6
        e.last_mode = 2
        e.wfk_mode_data = f_handle_wfk
    end
end
keys[102] = {handle=f_handle}

-- Shift+F
function shift_f_handle_wfk(e, val)
    for i, c in ipairs(e.cursors) do
        remaining_line = string.reverse(e.active_window.contents[c.line]:sub(1, c.horizontal-1))
        offset, _, _ = rex.find(remaining_line, val)
        if offset ~= nil then
            c:move(-offset, 0, e)
        end
    end
    esc_handle(e)
end
function shift_f_handle(e)
    if input_mode_key(e, "F") then return end
    if e.mode == 0 then
        e.mode = 6
        e.wfk_mode_data = shift_f_handle_wfk
    elseif e.mode == 2 then
        e.mode = 6
        e.last_mode = 2
        e.wfk_mode_data = shift_f_handle_wfk
    end
end
keys[70] = {handle=shift_f_handle}

-- R
function r_handle_wfk(e, val)
    for i, c in ipairs(e.cursors) do
        --if e.last_mode == 0 then
        --    line = e.active_window.contents[c.line]
        --    line = line:sub(1, c.horizontal - 1) .. val .. line:sub(c.horizontal+1)
        --    e.active_window.contents[c.line] = line
        --end
        local replacement_contents = c:get_contents(e.active_window.contents)
        replacement_contents = replacement_contents:gsub("[^\n]", val)
        c:set_contents(e.active_window.contents, replacement_contents)
        
        -- Make sure cursor isn't out of bounds
        c:sort_sides()
        c:zero_range()
        c:move(0, 0, e)
        c.real_horizontal = c.horizontal
    end
    esc_handle(e)
    esc_handle(e)
end
function r_handle(e)
    if input_mode_key(e, "r") then return end
    if e.mode == 0 or e.mode == 2 then
        e.last_mode = e.mode
        e.mode = 6
        e.wfk_mode_data = r_handle_wfk
    end
end
keys[114] = {handle=r_handle}

-- Shift+A
function shift_a_handle(e)
    if input_mode_key(e, "A") then return end
    if e.mode == 0 then
        dollar_handle(e)
        a_handle(e)
    end
end
keys[65] = {handle=shift_a_handle}

-- Shift+I
function shift_i_handle(e)
    if input_mode_key(e, "I") then return end
    if e.mode == 0 then
        zero_handle(e)
        i_handle(e)
    end
end
keys[73] = {handle=shift_i_handle}

-- E
--function e_handle(e)
--    if input_mode_key(e, "I") then return end
--    if e.mode == 0 then
--    end
--end

return keys
