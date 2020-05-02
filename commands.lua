local renderer = require "renderer"
local rex = require "rex_pcre2" -- lrexlib
local cursor = require "cursor"

local commands = {}

function commands:process(e)
    -- Should probably have some sort of cline_mode_data, rather than using status
    if e.active_window.status:sub(1,1) == ":" then
        if commands[e.active_window.status:sub(2)] ~= nil then
            -- Should split by space and pass parameters
            commands[e.active_window.status:sub(2)].handle(e)
        end
    elseif e.active_window.status:sub(1,1) == "/" then
        e.active_window.status = "searching..."
    end
end

commands["q"] = {handle=function(e)
    renderer:exit()
    os.exit()
end}

return commands
