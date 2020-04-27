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
    
    table.insert(self.windows, window:new())

    -- self.scr:mvaddstr(0,0,"babbit")
end

function renderer:getch()
    local c = self.scr:getch()
    return c
end

function renderer:redraw()
    -- Right now only one window is supported
    self.scr:clear()
    for i, v in ipairs(self.windows[1].contents) do
        cs = curses.chstr(string.len(v))
        cs:set_str(0, v, curses.A_NORMAL)
        self.scr:mvaddchstr(i,0,cs)
    end
end

function renderer:exit()
    self.scr:clear()
    curses.endwin()
end

return renderer
