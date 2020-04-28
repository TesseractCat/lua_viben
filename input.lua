local renderer = require "renderer"
local window = require "window"
local keys = require "keys"
local cursor = require "cursor"

local input = {}
-- 0 = Command, 1 = Insert, 2 = Visual (same for all cursors)
-- 3 = Numerical, 4 = Verb-Adj
input.mode_names = {"COMMAND", "INSERT", "VISUAL", "NUMERICAL", "VERB-ADJ"}
input.mode = 0
input.active_window = nil

-- Primary cursor should always be at idx = 1, order means nothing
input.cursors = {}

function input:init()
    table.insert(self.cursors, cursor:new())
    self.active_window = renderer.windows[1]
end

function input:loop()
    local c = renderer:getch()
    
    if keys[c] ~= nil then
        keys[c].handle(self)
    else
        self.active_window.contents[1] = self.active_window.contents[1] .. c .. ' '
    end
end

return input
