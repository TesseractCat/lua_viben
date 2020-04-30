local cursor = {}

cursor.prototype = {}
cursor.prototype.line = 1
cursor.prototype.horizontal = 1
cursor.prototype.real_horizontal = 1

cursor.prototype.alt_line = 1
cursor.prototype.alt_horizontal = 1

cursor.mt = {}
cursor.mt.__index = cursor.prototype

function cursor:new(o)
    o = o or {}
    setmetatable(o, cursor.mt)
    return o
end

function cursor.prototype:move(dx, dy, e)
    self.horizontal = self.real_horizontal + dx
    self.line = self.line + dy
    if self.line < 1 then
        self.line = 1
    end
    if self.horizontal < 1 then
        self.horizontal = 1
    end
    if self.line > #e.active_window.contents then
        self.line = #e.active_window.contents
    end
    if self.horizontal > string.len(e.active_window.contents[self.line]) then
        self.horizontal = string.len(e.active_window.contents[self.line])
    end
    if string.len(e.active_window.contents[self.line]) == 0 then
        self.horizontal = 1
    end
    
    if dx ~= 0 then
        self.real_horizontal = self.horizontal
    end
end

return cursor
