local renderer = require "renderer"

local keys = {}

function esc_handle(input_state)
    input_state.mode = 0
end
keys[27] = {handle=esc_handle} -- Escape

function i_handle(input_state)
    if input_state.mode == 0 then
        input_state.mode = 1
    elseif input_state.mode == 1 then
        renderer.windows[1].contents[1] = renderer.windows[1].contents[1] .. "i"
    end
end
keys[105] = {handle=i_handle} -- Insert

return keys
