local renderer = require "renderer"
local rex = require "rex_pcre2" -- lrexlib
local cursor = require "cursor"

local commands = {}
local command_defs = {}

function commands:process(e)
    -- Should probably have some sort of cline_mode_data, rather than using status
    --if e.cline_mode_data:sub(1,1) == ":" then
    --    if commands[e.cline_mode_data:sub(2)] ~= nil then
    --        -- Should split by space and pass parameters
    --        self[e.cline_mode_data:sub(2)].handle(e)
    --    else
    --        e.cline_mode_data = "Unknown command"
    --        e.mode = e.last_mode
    --    end
    --elseif e.cline_mode_data:sub(1,1) == "/" and e.cline_mode_data:len() > 1 then
    --    self:search(e,e.cline_mode_data:sub(2),true)
    --end
    
    for cmd, cmd_func in pairs(command_defs) do
        if e.cline_mode_data:len() >= cmd:len() and e.cline_mode_data:sub(1, cmd:len()) == cmd then
            cmd_func(e,true)
            return
        end
    end
    e.cline_mode_data = "Unknown command"
    e.mode = e.last_mode
end

function commands:keypress(e)
    --if e.cline_mode_data:sub(1,1) == "/" and e.cline_mode_data:len() > 1 then
    --    self:search(e,e.cline_mode_data:sub(2),false)
    --elseif e.cline_mode_data:sub(1,3) == ":g/" then
    --    if e.cline_mode_data:len() > 3 then
    --        self:given(e,e.cline_mode_data:sub(4),false)
    --    else
    --        for i, c in ipairs(e.cursors) do
    --            c.visible = true
    --        end
    --    end
    --end
    for cmd, cmd_func in pairs(command_defs) do
        if e.cline_mode_data:len() >= cmd:len() and e.cline_mode_data:sub(1, cmd:len()) == cmd then
            cmd_func(e,false)
            return
        end
    end
end

function commands:escape(e)
    for i, c in ipairs(e.cursors) do
        c.visible = true
        if e.mode ~= 3 then
            c.range = false
            c:zero_range()
        end
    end
end

command_defs[":x/"] = function(e,final)
    if e.cline_mode_data:len() > 3 then
        commands:search(e,e.cline_mode_data:sub(4),final)
    else
        for i, c in ipairs(e.cursors) do
            c.visible = false
        end
    end
end
command_defs[":g/"] = function(e,final)
    if e.cline_mode_data:len() > 3 then
        commands:given(e,e.cline_mode_data:sub(4),final)
    else
        for i, c in ipairs(e.cursors) do
            c.visible = true
        end
    end
end
command_defs[":q"] = function(e,final)
    if final then
        renderer:exit()
        os.exit()
    end
end

function commands:given(e, pattern, final)
    local status, pattern = pcall(rex.new, pattern)
    
    if status == false then
        return
    end
    
    local all_removed = true
    -- Set all cursors that don't match the pattern to be invisible
    for i, c in ipairs(e.cursors) do
        if pattern:exec(c:get_contents(e.active_window.contents)) == nil then
            c.visible = false
        else
            c.visible = true
            all_removed = false
        end
    end
    
    -- If final, them remove all invisible cursors
    if final then
        -- Don't remove any if all are removed
        if not all_removed then
            for i=#e.cursors,1,-1 do
                if e.cursors[i].visible == false then
                    table.remove(e.cursors, i)
                end
            end
            e.active_cursor = e.cursors[1]
        else
            for i, c in ipairs(e.cursors) do
                c.visible = true
            end
        end
        
        e.mode = 3
    end
end

function commands:search(e, pattern, final)
    local status, pattern = pcall(rex.new, pattern)
    
    if status == false then
        for i, c in ipairs(e.cursors) do
            c.visible = false
        end
        return
    end

    local subject = e.active_window:get_contents_as_string()
    
    local cursor_ranges = {}
    local offset = 1
    
    --e.cline_mode_data = ""
    
    -- Find all matches start and end positions
    while pattern:tfind(subject, offset) ~= nil do
        local start_pos, end_pos, capture_groups = pattern:exec(subject, offset)
        local length = (end_pos - start_pos)
        if length < 0 then
            break
        end
        
        offset = end_pos + 1
        
        if #capture_groups > 0 then
            -- Capture group, use as selection range
            start_pos, end_pos = capture_groups[1], capture_groups[2]
        end
        
        table.insert(cursor_ranges, {start_pos, end_pos})
    end
    
    if final then
        e.cline_mode_data = tostring(#cursor_ranges) .. " matches found."
    end
    
    -- Convert ranges to new cursors
    local cursors = {}
    for i, c in ipairs(cursor_ranges) do
        -- Create new cursor
        local nc = cursor:new()
        nc.range = true
        
        -- Convert start and end positions to line/hoz positions
        nc.alt_line = rex.count(subject:sub(1, c[1]), "\n")+1 -- Count all newlines from beginning to start_pos
        nc.line = rex.count(subject:sub(1, c[2]), "\n")+1
        
        nc.alt_horizontal = c[1] - (subject:sub(1, c[1]):find("\n[^\n]*$") or 0) -- Find last index of newline before start_pos
        nc.alt_real_horizontal = nc.alt_horizontal
        nc.horizontal = c[2] - (subject:sub(1, c[2]):find("\n[^\n]*$") or 0)
        nc.real_horizontal = nc.horizontal
        
        -- Add to table
        table.insert(cursors, nc)
    end
    
    if #cursors > 0 then
        e.cursors = cursors
        e.active_cursor = e.cursors[1]
    else
        for i, c in ipairs(e.cursors) do
            c.visible = false
        end
    end
    
    if final then
        e.mode = 3
    end
end


return commands
