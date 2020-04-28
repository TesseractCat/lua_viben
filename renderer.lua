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
    self.scr:immedok(true)
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
    
    -- Draw lines
    for i, v in ipairs(self.windows[1].contents) do
        self.scr:mvaddstr(i + 2, 1, tostring(i))
        
        if string.len(v) < 1  then
            v = " "
        end

        cs = curses.chstr(string.len(v))
        
        --cs:set_str(0, v, curses.A_NORMAL)
        
        if i == e.cursors[1].line then
            cs:set_str(0, v, curses.A_BOLD)
        else
            cs:set_str(0, v, curses.A_DIM)
        end
        
        for k, c in ipairs(e.cursors) do
            if c.line == i and string.sub(v,c.horizontal,c.horizontal) ~= nil then
                if e.mode == 0 then
                    cs:set_ch(c.horizontal-1, string.sub(v,c.horizontal,c.horizontal), curses.A_REVERSE)
                elseif e.mode == 1 then
                    cs:set_ch(c.horizontal-1, string.sub(v,c.horizontal,c.horizontal), curses.A_REVERSE)--curses.A_UNDERLINE)
                end
            end
        end
        
        self.scr:mvaddchstr(i + 2, 4,cs)
        
        ::continue::
    end
end

function renderer:exit()
    self.scr:clear()
    curses.endwin()
end

return renderer
