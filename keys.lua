local renderer = require "renderer"
local rex = require "rex_pcre2" -- lrexlib
local cursor = require "cursor"
local commands = require "commands"

-- Per mode
-- Example keymap:
-- {48}: {handle=zero_handle}
-- {105,119}: {handle=word_handle, params={inner=true}}
local mode_keymaps = {{},{},{},{},{},{},{}}

-- e = input statE
function insert_mode_default(e, val)
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
end

function cline_mode_default(e, val)
    e.cline_mode_data = e.cline_mode_data .. val
    commands:keypress(e)
end

function wfk_mode_default(e, val)
    if e.wfk_mode_data ~= nil then
        e.wfk_mode_data(e, val)
    end
end

chars = " 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()-=+_[]{}|\\:;<>,.?/`~\'\""
for c in chars:gmatch(".") do
    --keys[c:byte(1)] = {handle=function(e)
    --    if input_mode_key(e, c) then return end
    --end}
    mode_keymaps[2][{c:byte(1)}] = {handle=function(e)
        insert_mode_default(e, c)
    end}
    mode_keymaps[6][{c:byte(1)}] = {handle=function(e)
        cline_mode_default(e, c)
    end}
    mode_keymaps[7][{c:byte(1)}] = {handle=function(e)
        wfk_mode_default(e, c)
    end}
end

nums = "123456789"
for n in nums:gmatch(".") do
    num_handle = function(e)
        if e.mode == 1 or e.mode == 3 then
            e.last_mode = e.mode
            e.mode = 4
            e.numerical_mode_data = tonumber(n)
        elseif e.mode == 4 then
            e.numerical_mode_data = tonumber(tostring(e.numerical_mode_data) .. n)
        end
    end
    
    mode_keymaps[4][{n:byte(1)}] = {handle=num_handle}
    mode_keymaps[1][{n:byte(1)}] = {handle=num_handle}
    mode_keymaps[3][{n:byte(1)}] = {handle=num_handle}
end

-- 0
function zero_handle(e)
    for i, c in ipairs(e.cursors) do
        c:move_abs(1, nil, e)
    end
end
mode_keymaps[1][{48}] = {handle=zero_handle}
mode_keymaps[3][{48}] = {handle=zero_handle}

-- $
function dollar_handle(e)
    for i, c in ipairs(e.cursors) do
        c:move_abs(e.active_window.contents[c.line]:len(), nil, e)
        c.real_horizontal = 10000
    end
end
mode_keymaps[1][{36}] = {handle=dollar_handle}
mode_keymaps[3][{36}] = {handle=dollar_handle}

-- Escape
function esc_handle(e)
    if e.mode == 2 then
        for i, c in ipairs(e.cursors) do
            c:move(-1, 0, e)
        end
        e.mode = 1
    elseif e.mode == 1 then
        -- Remove extra cursors
        e.cursors = {e.active_cursor}
        e.mode = 1
    elseif e.mode == 3 or e.mode == 5 then
        -- Remove selection lengths
        for i, c in ipairs(e.cursors) do
            c.range = false
            c:zero_range()
        end
        e.mode = 1
    elseif e.mode == 7 or e.mode == 4 then
        -- Set mode to last mode
        e.mode = e.last_mode
    elseif e.mode == 6 then
        -- Set mode to last mode
        e.mode = e.last_mode
        -- Run commands escape callback
        commands:escape(e)
        -- Reset status message
        e.cline_mode_data = ""
    end
    e.last_mode = 1
    e.numerical_mode_data = 1
    
    --e.cline_mode_data = 'PCRE2 (' .. rex.version() .. ')' .. ' VIB (0.0.1)'
end
mode_keymaps[1][{27}] = {handle=esc_handle}
mode_keymaps[2][{27}] = {handle=esc_handle}
mode_keymaps[3][{27}] = {handle=esc_handle}
mode_keymaps[4][{27}] = {handle=esc_handle}
mode_keymaps[5][{27}] = {handle=esc_handle}
mode_keymaps[6][{27}] = {handle=esc_handle}
mode_keymaps[7][{27}] = {handle=esc_handle}

-- Backspace
function backspace_handle(e)
    if e.mode == 1 then
        for i, c in ipairs(e.cursors) do
            c:move(-1, 0, e)
        end
    elseif e.mode == 2 then
        for i, c in ipairs(e.cursors) do
            if c.horizontal == 1 and #e.cursors == 1 then
                if c.line ~= 1 then
                    -- Join lines
                    prev_line_length = e.active_window.contents[c.line - 1]:len()
                    e.active_window.contents[c.line] = e.active_window.contents[c.line - 1] .. e.active_window.contents[c.line]
                    table.remove(e.active_window.contents, c.line - 1)
                    c:move(0, -1, e)
                    c:move(prev_line_length, 0, e)
                end
            elseif c.horizontal ~= 1 then
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
    elseif e.mode == 6 then
        e.cline_mode_data = e.cline_mode_data:sub(1, -2)
        commands:keypress(e)
    end
end
mode_keymaps[1][{127}] = {handle=backspace_handle}
mode_keymaps[2][{127}] = {handle=backspace_handle}
mode_keymaps[6][{127}] = {handle=backspace_handle}

-- Enter
function enter_handle(e)
    if e.mode == 2 then
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
    elseif e.mode == 6 then
        commands:process(e)
    end
end
mode_keymaps[2][{13}] = {handle=enter_handle}
mode_keymaps[6][{13}] = {handle=enter_handle}

-- Forward Slash
function forward_slash_handle(e)
    e.last_mode = e.mode
    commands:start_entry(e, ":x/")
end
mode_keymaps[1][{47}] = {handle=forward_slash_handle}
mode_keymaps[3][{47}] = {handle=forward_slash_handle}

-- Colon
function colon_handle(e)
    e.last_mode = e.mode
    commands:start_entry(e, ":")
end
mode_keymaps[1][{58}] = {handle=colon_handle}
mode_keymaps[3][{58}] = {handle=colon_handle}

-- Ctrl + J
function ctrl_j_handle(e)
    if e.active_cursor.line < #e.active_window.contents then
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
mode_keymaps[1][{10}] = {handle=ctrl_j_handle}

-- Ctrl + K
function ctrl_k_handle(e)
    if e.active_cursor.line > 1 then
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
mode_keymaps[1][{11}] = {handle=ctrl_k_handle}

-- V
function v_handle(e)
    e.mode = 3
    for i, c in ipairs(e.cursors) do
        c:zero_range()
        c.range = true
    end
end
mode_keymaps[1][{118}] = {handle=v_handle}

-- Tab
function tab_handle(e)
    insert_mode_default(e, "    ")
end
mode_keymaps[1][{9}] = {handle=v_handle}
mode_keymaps[2][{9}] = {handle=tab_handle}
mode_keymaps[3][{9}] = {handle=esc_handle}

-- Ctrl+U
function ctrl_u_handle(e)
    if #e.cursors > 1 then
        -- Sort
        table.sort(e.cursors, e.compare_cursors)
        
        for i, c in ipairs(e.cursors) do
            if c == e.active_cursor then
                if i ~= 1 then
                    e.active_cursor = e.cursors[i - 1]
                else
                    e.active_cursor = e.cursors[#e.cursors]
                end
                return
            end
        end
    end
end
mode_keymaps[1][{21}] = {handle=ctrl_u_handle}
mode_keymaps[3][{21}] = {handle=ctrl_u_handle}

-- Ctrl+D
function ctrl_d_handle(e)
    if #e.cursors > 1 then
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
mode_keymaps[1][{4}] = {handle=ctrl_d_handle}
mode_keymaps[3][{4}] = {handle=ctrl_d_handle}

-- Q
function q_handle(e)
    if #e.cursors > 1 then
        table.remove(e.cursors, 1)
    end
end
mode_keymaps[1][{113}] = {handle=q_handle}

-- Shift+H
function shift_h_handle(e)
    for i, c in ipairs(e.cursors) do
        char_horizontal, _, _ = rex.find(e.active_window.contents[c.line], "[^\\s]")
        c:move_abs(char_horizontal, nil, e)
    end
end
mode_keymaps[1][{72}] = {handle=shift_h_handle}

-- S
function s_handle(e)
    x_handle(e)
    i_handle(e)
end
mode_keymaps[1][{115}] = {handle=s_handle}

-- I
function i_handle(e)
    for i, c in ipairs(e.cursors) do
        if e.active_window.contents[c.line]:len() == 0 then
            e.active_window.contents[c.line] = " "
        end
    end
    e.mode = 2
end
mode_keymaps[1][{105}] = {handle=i_handle}

-- A
function a_handle(e)
    --If at end of line
    for i, c in ipairs(e.cursors) do
        if c.horizontal == e.active_window.contents[c.line]:len() then
            e.active_window.contents[c.line] = e.active_window.contents[c.line] .. " "
        end
        c:move(1, 0, e)
    end
    e.mode = 2
end
mode_keymaps[1][{97}] = {handle=a_handle}

-- H
function h_handle(e)
    for i, c in ipairs(e.cursors) do
        c:move(-e.numerical_mode_data, 0, e)
    end
end
mode_keymaps[1][{104}] = {handle=h_handle}
mode_keymaps[3][{104}] = {handle=h_handle}
mode_keymaps[4][{104}] = {handle=h_handle,late_handle=esc_handle}

-- L
function l_handle(e)
    for i, c in ipairs(e.cursors) do
        c:move(e.numerical_mode_data, 0, e)
    end
end
mode_keymaps[1][{108}] = {handle=l_handle}
mode_keymaps[3][{108}] = {handle=l_handle}
mode_keymaps[4][{108}] = {handle=l_handle,late_handle=esc_handle}
 
-- J
function j_handle(e)
    for i, c in ipairs(e.cursors) do
        c:move(0, e.numerical_mode_data, e)
    end
end
mode_keymaps[1][{106}] = {handle=j_handle}
mode_keymaps[3][{106}] = {handle=j_handle}
mode_keymaps[4][{106}] = {handle=j_handle,late_handle=esc_handle}

-- K
function k_handle(e)
    for i, c in ipairs(e.cursors) do
        c:move(0, -e.numerical_mode_data, e)
    end
end
mode_keymaps[1][{107}] = {handle=k_handle}
mode_keymaps[3][{107}] = {handle=k_handle}
mode_keymaps[4][{107}] = {handle=k_handle,late_handle=esc_handle}

-- X
function x_handle(e)
    for i, c in ipairs(e.cursors) do
        c:set_contents(e.active_window.contents, "")
        
        -- Make sure cursor isn't out of bounds
        c:sort_sides()
        c:zero_range()
        c:move(0, 0, e)
        c.real_horizontal = c.horizontal
    end
end
mode_keymaps[1][{120}] = {handle=x_handle}
mode_keymaps[3][{120}] = {handle=x_handle,late_handle=esc_handle}
mode_keymaps[5][{120}] = {handle=x_handle}

-- O
function o_handle(e)
    if e.mode == 1 then
        table.insert(e.active_window.contents, e.active_cursor.line + 1, " ")
        e.mode = 2
        e.active_cursor:move(0, 1, e)
    elseif e.mode == 3 then
        for i, c in ipairs(e.cursors) do
            c:swap_sides()
        end
    end
end
mode_keymaps[1][{111}] = {handle=o_handle}
mode_keymaps[3][{111}] = {handle=o_handle}

-- Shift+O
function shift_o_handle(e)
    table.insert(e.active_window.contents, e.active_cursor.line, " ")
    e.mode = 2
    e.active_cursor:move(0, 0, e)
end
mode_keymaps[1][{79}] = {handle=shift_o_handle}

-- D
function d_handle_immed(e)
    x_handle(e)
    for i, c in ipairs(e.cursors) do
        c.range = false
        c:zero_range()
    end
    esc_handle(e)
end
function d_handle(e)
    if e.mode == 5 then
        for i=#e.cursors,1,-1 do
            table.remove(e.active_window.contents, e.cursors[i].line)
            e.cursors[i]:move(0, 0, e)
        end
        e.mode = 0
    elseif e.mode == 1 then
        e.mode = 5
        e.verb_mode_data = d_handle_immed
        for i, c in ipairs(e.cursors) do
            c:zero_range()
            c.range = true
        end
    end
end
mode_keymaps[1][{100}] = {handle=d_handle}
mode_keymaps[3][{100}] = {handle=x_handle}
mode_keymaps[5][{100}] = {handle=d_handle}

-- F
function f_handle_wfk(e, val)
    for i, c in ipairs(e.cursors) do
        remaining_line = e.active_window.contents[c.line]:sub(c.horizontal+1)
        offset, _, _ = rex.find(remaining_line, val)
        if offset ~= nil then
            c:move(offset, 0, e)
        end
    end
    if e.last_mode == 5 then
        e.mode = 3
        e.verb_mode_data(e)
    else
        esc_handle(e)
    end
end
function f_handle(e)
    e.last_mode = e.mode
    e.mode = 7
    e.wfk_mode_data = f_handle_wfk
end
mode_keymaps[1][{102}] = {handle=f_handle}
mode_keymaps[3][{102}] = {handle=f_handle}
mode_keymaps[5][{102}] = {handle=f_handle}

-- Shift+F
function shift_f_handle_wfk(e, val)
    for i, c in ipairs(e.cursors) do
        remaining_line = string.reverse(e.active_window.contents[c.line]:sub(1, c.horizontal-1))
        offset, _, _ = rex.find(remaining_line, val)
        if offset ~= nil then
            c:move(-offset, 0, e)
        end
    end
    if e.last_mode == 5 then
        e.mode = 3
        e.verb_mode_data(e)
    else
        esc_handle(e)
    end
end
function shift_f_handle(e)
    e.last_mode = e.mode
    e.mode = 7
    e.wfk_mode_data = shift_f_handle_wfk
end
mode_keymaps[1][{70}] = {handle=shift_f_handle}
mode_keymaps[3][{70}] = {handle=shift_f_handle}
mode_keymaps[5][{70}] = {handle=shift_f_handle}

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
    e.last_mode = e.mode
    e.mode = 7
    e.wfk_mode_data = r_handle_wfk
end
mode_keymaps[1][{114}] = {handle=r_handle}
mode_keymaps[3][{114}] = {handle=r_handle}

-- Shift+A
function shift_a_handle(e)
    dollar_handle(e)
    a_handle(e)
end
mode_keymaps[1][{65}] = {handle=shift_a_handle}

-- Shift+I
function shift_i_handle(e)
    zero_handle(e)
    i_handle(e)
end
mode_keymaps[1][{73}] = {handle=shift_i_handle}

-- E
--function e_handle(e)
--    if input_mode_key(e, "I") then return end
--    if e.mode == 0 then
--    end
--end

-- G
function g_handle(e)
    -- Given, check each for regex
    if #e.cursors > 1 then
        e.last_mode = e.mode
        commands:start_entry(e, ":g/")
    end
end
mode_keymaps[3][{103}] = {handle=g_handle}

return mode_keymaps
