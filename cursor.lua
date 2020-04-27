local cursor = {}

cursor.prototype = {}
cursor.prototype.line = 1
cursor.prototype.horizontal = 1
cursor.prototype.length = 1

cursor.mt = {}
cursor.mt.__index = cursor.prototype

function cursor:new(o)
    o = o or {}
    setmetatable(o, cursor.mt)
    return o
end

function cursor:move(dx, dy)
    --self.horizontal = self.horizontal + dx
    --self.line = self.line + dy
    --if self.line < 1 then
    --    self.line = 1
    --end
    --if self.horizontal < 1 then
    --    self.horizontal = 1
    --end
end

return cursor
