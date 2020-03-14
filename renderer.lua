local curses = require "curses"
local window = require "window"

local renderer = {}
renderer.windows = {}
renderer.cursed_windows = {}

function renderer:init()
    self.scr = curses.initscr()
    curses.cbreak()
    curses.echo(false)
    curses.nl(false)
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
    self.scr:mvaddstr(1,1,self.windows[1].contents)
end

function renderer:exit()
    self.scr:clear()
    curses.endwin()
end

return renderer
