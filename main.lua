local curses = require "curses"
local clock = os.clock
local renderer = require "renderer"
local input = require "input"
local window = require "window"

local function main()
    -- Init
    renderer:init()
    input:init()
    
    -- Read file
    local f = io.open(arg[1], "r")
    renderer.windows[1].contents = {}
    for line in f:lines() do
        table.insert(renderer.windows[1].contents, line)
    end
    f:close()

    -- Initial draw
    renderer:redraw(input)
    
    -- Input loop
    while true do
        input:loop()
        renderer:redraw(input)
    end

    renderer:exit()
end


main()
