local curses = require "curses"
local window = require "window"

local renderer = {}
renderer.windows = {}

function renderer:init()
    -- Rather than using curses window management system, everything will be drawn with self.scr
    self.scr = curses.initscr()
    
    curses.cbreak()
    curses.echo(false)
    curses.nl(false)
    curses.curs_set(0)
    curses.start_color()
    
    -- Color pairs
    curses.init_pair(1, curses.COLOR_WHITE, curses.COLOR_BLUE)
    curses.init_pair(2, curses.COLOR_WHITE, curses.COLOR_RED)
    
    self.scr:immedok(true)
    --self.scr:keypad(true)
    self.scr:clear()
    
    -- Default window, always present at startup...
    -- Either opened file or scratch window
    table.insert(self.windows, window:new())

    -- self.scr:mvaddstr(0,0,"babbit")
end

function renderer:getch()
    local c = self.scr:getch()
    return c
end

function renderer:redraw(e)
    -- Right now only one window is supported
    self.scr:clear()
    
    -- Draw mode
    mode_string = curses.chstr(string.len(e.mode_names[e.mode + 1] .. " MODE"))
    mode_string:set_str(0, e.mode_names[e.mode + 1] .. " MODE", curses.A_BOLD)
    _, width = self.scr:getmaxyx()
    self.scr:mvaddchstr(1, math.floor(width/2 - mode_string:len()/2), mode_string)
    
    -- Draw status
    self.scr:mvaddstr(1, 1, self.windows[1].status)

    -- Draw C-LINE mode cursor
    if e.mode == 5 then
        self.scr:mvaddstr(1, e.active_window.status:len() + 1, "|")
    end
    
    -- Draw column numbers
    --for i = 1,50 do
    --    self.scr:mvaddstr(3, 4 + i, tostring(math.abs(i - e.cursors[1].horizontal)))
    --end
    
    -- Draw lines
    for i, v in ipairs(self.windows[1].contents) do
        if math.abs(i - e.active_cursor.line) ~= 0 then
            self.scr:mvaddstr(i + 2, 2, tostring(math.abs(i - e.cursors[1].line)))
        else
            self.scr:mvaddstr(i + 2, 1, string.char(126) .. tostring(i))
        end
        
        --if string.len(v) < 1  then
        --    v = " "
        --end

        cs = curses.chstr(string.len(v))
        
        --cs:set_str(0, v, curses.A_NORMAL)
        
        if i == e.active_cursor.line and false then
            cs:set_str(0, v, curses.A_BOLD)
        else
            cs:set_str(0, v, curses.A_NORMAL)
        end
        
        for k, c in ipairs(e.cursors) do
            if c:get_line_range(i) ~= nil then
                -- Draw selection
                local range = c:get_line_range(i)
                cs:set_str(range[1]-1, string.sub(v,range[1],range[2]), curses.color_pair(1))
                
                -- Draw cursor head
                if c.line == i then
                    if c == e.active_cursor then
                        if e.mode ~= 1 or true then
                            cs:set_str(c.horizontal-1, string.sub(v,c.horizontal,c.horizontal), curses.color_pair(2))
                        else
                            cs:set_str(c.horizontal-1, string.sub(v,c.horizontal,c.horizontal), curses.A_UNDERLINE)
                        end
                    else
                        cs:set_str(c.horizontal-1, string.sub(v,c.horizontal,c.horizontal), curses.A_REVERSE)
                    end
                end
            end
        end
        
        self.scr:mvaddchstr(i + 2, 5,cs)
        
        ::continue::
    end
end

function renderer:exit()
    self.scr:clear()
    curses.endwin()
end

return renderer
