local renderer = require "renderer"
local window = require "window"

local input = {}

function input:loop()
    local c = renderer:getch()
    if c < 256 then
        --c = string.char(c)
        renderer.windows[1].contents = renderer.windows[1].contents .. c .. " "
    end
end

return input
