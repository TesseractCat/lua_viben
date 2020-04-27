local curses = require "curses"
local clock = os.clock
local renderer = require "renderer"
local input = require "input"
local window = require "window"

local function main()
    -- Init
    input:init()
    renderer:init()

    -- Initial draw
    renderer:redraw(input)
    
    while true do
        input:loop()
        renderer:redraw(input)
    end

    renderer:exit()
end


main()
