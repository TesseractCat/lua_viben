local renderer = require "renderer"
local rex = require "rex_pcre2" -- lrexlib
local cursor = require "cursor"

local commands = {}

function commands:process(e)
    -- Should probably have some sort of cline_mode_data, rather than using status
    if e.active_window.status:sub(1,1) == ":" then
        if commands[e.active_window.status:sub(2)] ~= nil then
            -- Should split by space and pass parameters
            self[e.active_window.status:sub(2)].handle(e)
        else
            e.active_window.status = "Unknown command"
        end
    elseif e.active_window.status:sub(1,1) == "/" and e.active_window.status:len() > 1 then
        self:search(e,e.active_window.status:sub(2))
    end
end

function commands:search(e, pattern)
    --e.active_window.status = "Searching..."
    local pattern = rex.new(pattern)
    local subject = e.active_window:get_contents_as_string()
    
    local cursor_ranges = {}
    local offset = 1
    
    --e.active_window.status = ""
    
    -- Find all matches start and end positions
    while pattern:tfind(subject, offset) ~= nil do
        local start_pos, end_pos = pattern:tfind(subject, offset)
        --local length = (end_pos - start_pos) + 1
        offset = end_pos + 1
        
        table.insert(cursor_ranges, {start_pos, end_pos})
        --e.active_window.status = e.active_window.status .. table.concat({start_pos, end_pos}, ", ") .. " | "
    end
    
    e.active_window.status = tostring(#cursor_ranges) .. " matches found."
    
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
    end
    
    e.mode = 2
end

commands["q"] = {handle=function(e)
    renderer:exit()
    os.exit()
end}

return commands
