local renderer = require "renderer"
local window = require "window"
local keys = require "keys"

local input = {}
-- 0 = Command, 1 = Insert, 2 = Visual (same for all cursors)
input.mode = 0
input.cursors = {}

function input:loop()
    local c = renderer:getch()
    
    if keys[c] ~= nil then
        keys[c].handle(self)
    end
end

return input
