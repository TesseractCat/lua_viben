local window = {}

window.prototype = {}

-- STUB
window.prototype.subwindows = {}
-- 0 = NONE, 1 = HOZ, 2 = VERT
window.prototype.splitdir = 0

window.prototype.cursors = {}

window.prototype.path = "./default.txt"
window.prototype.contents = {
    "This is a scratch file",
    "Use this file to enter any text you want",
    "a",
    "Here is an example function:",
    "function rabbits(int babbit, int crabbit) {",
    "    print('rabbit man')",
    "}"
}

window.prototype.status = "- R/W -"

window.mt = {}
window.mt.__index = window.prototype

function window:new(o)
    o = o or {}
    setmetatable(o, window.mt)
    return o
end

function window.prototype:split(dir)
    self.splitdir = dir
    table.insert(self.subwindows, window:new())
    table.insert(self.subwindows, window:new())
end

function window.prototype:get_length()
    local length = 0
    for i, c in ipairs(self.contents) do
        length = length + c:len()
    end
    return length
end

function window.prototype:get_contents_as_string()
    return table.concat(self.contents, "\n")
end

return window
