local cursor = {}

cursor.prototype = {}
cursor.prototype.line = 1
cursor.prototype.horizontal = 1
cursor.prototype.real_horizontal = 1

cursor.prototype.alt_line = 1
cursor.prototype.alt_horizontal = 1
cursor.prototype.alt_real_horizontal = 1

cursor.prototype.range = false

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
    
    if not self.range then
        self:zero_range()
    end
end

function cursor.prototype:move_abs(x, y, e)
    if x ~= nil then
        self.horizontal = x
        self.real_horizontal = x
    end
    if y ~= nil then
        self.line = y
    end
    
    if not self.range then
        self:zero_range()
    end
end

function cursor.prototype:swap_sides()
    self.line, self.alt_line = self.alt_line, self.line
    self.horizontal, self.alt_horizontal = self.alt_horizontal, self.horizontal
    self.real_horizontal, self.alt_real_horizontal = self.alt_real_horizontal, self.real_horizontal
end

function cursor.prototype:sort_sides()
    if self.line > self.alt_line then
        self:swap_sides()
    elseif self.line == self.alt_line and self.horizontal > self.alt_horizontal then
        self:swap_sides()
    end
end

function cursor.prototype:zero_range()
    self.alt_line = self.line 
    self.alt_horizontal = self.horizontal
    self.alt_real_horizontal = self.real_horizontal
end

-- Return {line, horizontal}
function cursor.prototype:range_minimum()
    if self.line == self.alt_line then
        return {self.line, math.min(self.horizontal, self.alt_horizontal)}
    elseif self.line < self.alt_line then
        return {self.line, self.horizontal}
    elseif self.line > self.alt_line then
        return {self.alt_line, self.alt_horizontal}
    end
end
function cursor.prototype:range_maximum()
    if self.line == self.alt_line then
        return {self.line, math.max(self.horizontal, self.alt_horizontal)}
    elseif self.line > self.alt_line then
        return {self.line, self.horizontal}
    elseif self.line < self.alt_line then
        return {self.alt_line, self.alt_horizontal}
    end
end

function cursor.prototype:in_range(line, horizontal)
    local range_beginning = self:range_minimum()
    local range_end = self:range_maximum()
    
    if line < range_beginning[1] or line > range_end[1] then
        return false
    elseif line == range_beginning[1] and horizontal < range_beginning[2] then
        return false
    elseif line == range_end[1] and horizontal > range_end[2] then
        return false
    end
    
    return true
end

function cursor.prototype:get_line_range(line)
    local range_beginning = self:range_minimum()
    local range_end = self:range_maximum()
    
    if line < range_beginning[1] or line > range_end[1] then
        return nil
    elseif line > range_beginning[1] and line < range_end[1] then
        return {1,-1}
    elseif line == range_beginning[1] and line == range_end[1] then
        return {range_beginning[2], range_end[2]}
    else
        if line == range_beginning[1] then
            return {range_beginning[2], -1}
        elseif line == range_end[1] then
            return {1, range_end[2]}
        end
    end
    return nil
end

function cursor.prototype:get_contents(file)
    local range_beginning = self:range_minimum()
    local range_end = self:range_maximum()
    if range_beginning[1] == range_end[1] then
        -- On same line
        return file[range_beginning[1]]:sub(range_beginning[2], range_end[2])
    else
        -- range_beginning[1] < range_end[1]
        local out_text = ""
        for i=range_beginning[1],range_end[1] do
            if i == range_beginning[1] then
                out_text = file[i]:sub(range_beginning[2]) .. "\n"
            elseif i == range_end[1] then
                out_text = out_text .. file[i]:sub(1, range_end[2])
            else
                out_text = out_text .. file[i] .. "\n"
            end
        end
        return out_text
    end
end


return cursor
