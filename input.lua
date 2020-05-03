local renderer = require "renderer"
local window = require "window"
local keys = require "keys"
local cursor = require "cursor"

local input = {}
-- 0 = Command, 1 = Insert, 2 = Visual (same for all cursors)
-- 3 = Numerical, 4 = Visual-Immediate, 5 = Command Line (for config, etc)
-- 6 = WFK (for commands like f, r, m, etc., which need one key input)
input.mode_names = {"COMMAND", "INSERT", "VISUAL", "NUMERICAL", "V-IMMEDIATE", "C-LINE", "WFK"}
input.mode = 0
input.last_mode = 0
input.numerical_mode_data = 1
input.verb_mode_data = {
    verb = nil,
    adjectives = {}
}
input.wfk_mode_data = nil

input.active_window = nil

-- Cursors, order should be from top to bottom, left to right, no overlapping ranges ideally
input.cursors = {}
input.active_cursor = nil

function input.compare_cursors(a, b)
    if a.line < b.line then
        return true
    elseif a.line == b.line then
        if a.horizontal < b.horizontal then
            return true
        else
            return false
        end
    end
    return false
end

function input:init()
    table.insert(self.cursors, cursor:new())
    self.active_cursor = self.cursors[1]
    self.active_window = renderer.windows[1]
end

function input:loop()
    local c = renderer:getch()
    
    if keys[c] ~= nil then
        keys[c].handle(self)
    else
        self.active_window.status = "Unknown key code: " .. c
    end
end

return input
