local curses = require "curses"
local clock = os.clock
local renderer = require "renderer"
local input = require "input"
local window = require "window"

local function main()
    -- Init
    renderer:init()
    
    renderer:redraw()

    while true do
        input:loop()
        renderer:redraw()
    end

    renderer:exit()
    
    print(renderer.windows[1].contents)
end


main()
