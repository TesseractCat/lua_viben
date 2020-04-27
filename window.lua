local window = {}

window.prototype = {}
window.prototype.subwindows = {}
-- 0 = NONE, 1 = HOZ, 2 = VERT
-- STUB
window.prototype.splitdir = 0

window.prototype.cursors = {}

window.prototype.path = "./default.txt"
window.prototype.contents = {"Blank file"}

window.mt = {}
window.mt.__index = window.prototype

function window:new(o)
    o = o or {}
    setmetatable(o, window.mt)
    return o
end

function window:split(dir)
    self.splitdir = dir
    table.insert(self.subwindows, window:new())
    table.insert(self.subwindows, window:new())
end

return window