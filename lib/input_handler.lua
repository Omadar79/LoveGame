--------------------------------------------------------------------------------------
-- INPUT HANDLER
-- A modular input handling system that manages all user input based on game state
--------------------------------------------------------------------------------------

local InputHandler = {
    currentGameState = "menu", -- Default state
    handlers = {},
    keysPressed = {},
    keysDown = {},
    mouseButtons = {},
    mouseX = 0,
    mouseY = 0,
    scrollX = 0,
    scrollY = 0,
    DEBUG_MODE = false
}

-- Initialize the input handler
function InputHandler.init(initialGameState)
    InputHandler.currentGameState = initialGameState or "menu"
    
    -- Setup default state handlers
    InputHandler.handlers = {
        -- Menu state input handlers
        menu = {
            keypressed = {},
            keyreleased = {},
            mousepressed = {},
            mousereleased = {},
            mousemoved = {},
            wheelmoved = {}
        },
        
        -- Playing state input handlers
        playing = {
            keypressed = {},
            keyreleased = {},
            mousepressed = {},
            mousereleased = {},
            mousemoved = {},
            wheelmoved = {}
        },
        
        -- Paused state input handlers
        paused = {
            keypressed = {},
            keyreleased = {},
            mousepressed = {},
            mousereleased = {},
            mousemoved = {},
            wheelmoved = {}
        },
        
        -- Global handlers (always active regardless of game state)
        global = {
            keypressed = {},
            keyreleased = {},
            mousepressed = {},
            mousereleased = {},
            mousemoved = {},
            wheelmoved = {}
        }
    }
    
    -- Set up default LÖVE handlers
    love.keypressed = function(key, scancode, isRepeat)
        InputHandler.handleKeyPressed(key, scancode, isRepeat)
    end
    
    love.keyreleased = function(key, scancode)
        InputHandler.handleKeyReleased(key, scancode)
    end
    
    love.mousepressed = function(x, y, button, isTouch, presses)
        InputHandler.handleMousePressed(x, y, button, isTouch, presses)
    end
    
    love.mousereleased = function(x, y, button, isTouch, presses)
        InputHandler.handleMouseReleased(x, y, button, isTouch, presses)
    end
    
    love.mousemoved = function(x, y, dx, dy, isTouch)
        InputHandler.mouseX = x
        InputHandler.mouseY = y
        InputHandler.handleMouseMoved(x, y, dx, dy, isTouch)
    end
    
    love.wheelmoved = function(x, y)
        InputHandler.scrollX = InputHandler.scrollX + x
        InputHandler.scrollY = InputHandler.scrollY + y
        InputHandler.handleWheelMoved(x, y)
    end
    
    -- Register debug console toggle (available in any game state)
    local DebugConsole = require("lib.debug_console")
    InputHandler.registerGlobalKeyPressed("`", function()
        if DebugConsole then
            DebugConsole.toggle()
            return true -- Signal that this key was handled
        end
        return false
    end)
    
    -- Also register the tilde key as an alternative
    InputHandler.registerGlobalKeyPressed("~", function()
        if DebugConsole then
            DebugConsole.toggle()
            return true -- Signal that this key was handled
        end
        return false
    end)
    
    -- Register escape key to pause/unpause when playing
    InputHandler.registerKeyPressed("playing", "escape", function()
        InputHandler.setGameState("paused")
        return true
    end)
    
    return InputHandler
end

-- Set the current game state
function InputHandler.setGameState(newState)
    InputHandler.currentGameState = newState
    -- We return the new state in case something needs to know it changed
    return newState
end

-- Reset all input states (useful when changing screens/states)
function InputHandler.reset()
    InputHandler.keysPressed = {}
    InputHandler.keysDown = {}
    InputHandler.mouseButtons = {}
    InputHandler.scrollX = 0
    InputHandler.scrollY = 0
end

-- Register a function to be called when a key is pressed in a specific game state
function InputHandler.registerKeyPressed(state, key, callback)
    if InputHandler.handlers[state] and InputHandler.handlers[state].keypressed then
        InputHandler.handlers[state].keypressed[key] = callback
    end
end

-- Register a function to be called when a key is released in a specific game state
function InputHandler.registerKeyReleased(state, key, callback)
    if InputHandler.handlers[state] and InputHandler.handlers[state].keyreleased then
        InputHandler.handlers[state].keyreleased[key] = callback
    end
end

-- Register a function to be called when a key is pressed regardless of game state
function InputHandler.registerGlobalKeyPressed(key, callback)
    InputHandler.handlers.global.keypressed[key] = callback
end

-- Register a function to be called when a key is released regardless of game state
function InputHandler.registerGlobalKeyReleased(key, callback)
    InputHandler.handlers.global.keyreleased[key] = callback
end

-- Register a function to be called when a mouse button is pressed regardless of game state
function InputHandler.registerGlobalMousePressed(button, callback)
    InputHandler.handlers.global.mousepressed[button] = callback
end

-- Register a function to be called when a mouse button is released regardless of game state
function InputHandler.registerGlobalMouseReleased(button, callback)
    InputHandler.handlers.global.mousereleased[button] = callback
end

-- Register a function to be called when a mouse button is pressed in a specific game state
function InputHandler.registerMousePressed(state, button, callback)
    if InputHandler.handlers[state] and InputHandler.handlers[state].mousepressed then
        InputHandler.handlers[state].mousepressed[button] = callback
    end
end

-- Register a function to be called when a mouse button is released in a specific game state
function InputHandler.registerMouseReleased(state, button, callback)
    if InputHandler.handlers[state] and InputHandler.handlers[state].mousereleased then
        InputHandler.handlers[state].mousereleased[button] = callback
    end
end

-- Handle key press events
function InputHandler.handleKeyPressed(key, scancode, isRepeat)
    -- Track key state
    InputHandler.keysPressed[key] = true
    InputHandler.keysDown[key] = true
    
    local handled = false
    
    -- First check global handlers
    if InputHandler.handlers.global.keypressed[key] then
        handled = InputHandler.handlers.global.keypressed[key](scancode, isRepeat) or handled
    end
    
    -- Then check state-specific handlers if not handled by global
    if not handled and InputHandler.handlers[InputHandler.currentGameState] and 
       InputHandler.handlers[InputHandler.currentGameState].keypressed[key] then
        handled = InputHandler.handlers[InputHandler.currentGameState].keypressed[key](scancode, isRepeat) or handled
    end
    
    -- If Debug Console is active, let it handle keys
    if not handled and InputHandler.DEBUG_MODE then
        local DebugConsole = require("lib.debug_console")
        if DebugConsole and DebugConsole.visible then
            DebugConsole.keypressed(key, scancode, isRepeat)
            handled = true
        end
    end
    
    return handled
end

-- Handle key release events
function InputHandler.handleKeyReleased(key, scancode)
    InputHandler.keysDown[key] = false
    
    local handled = false
    
    -- First check global handlers
    if InputHandler.handlers.global.keyreleased[key] then
        handled = InputHandler.handlers.global.keyreleased[key](scancode) or handled
    end
    
    -- Then check state-specific handlers
    if not handled and InputHandler.handlers[InputHandler.currentGameState] and 
       InputHandler.handlers[InputHandler.currentGameState].keyreleased[key] then
        handled = InputHandler.handlers[InputHandler.currentGameState].keyreleased[key](scancode) or handled
    end
    
    return handled
end

-- Handle mouse press events
function InputHandler.handleMousePressed(x, y, button, isTouch, presses)
    InputHandler.mouseButtons[button] = true
    
    local handled = false
    
    -- First check global handlers
    if InputHandler.handlers.global.mousepressed[button] then
        handled = InputHandler.handlers.global.mousepressed[button](x, y, isTouch, presses) or handled
    end
    
    -- Then check state-specific handlers
    if not handled and InputHandler.handlers[InputHandler.currentGameState] and 
       InputHandler.handlers[InputHandler.currentGameState].mousepressed[button] then
        handled = InputHandler.handlers[InputHandler.currentGameState].mousepressed[button](x, y, isTouch, presses) or handled
    end
    
    return handled
end

-- Handle mouse release events
function InputHandler.handleMouseReleased(x, y, button, isTouch, presses)
    InputHandler.mouseButtons[button] = false
    
    local handled = false
    
    -- First check global handlers
    if InputHandler.handlers.global.mousereleased[button] then
        handled = InputHandler.handlers.global.mousereleased[button](x, y, isTouch, presses) or handled
    end
    
    -- Then check state-specific handlers
    if not handled and InputHandler.handlers[InputHandler.currentGameState] and 
       InputHandler.handlers[InputHandler.currentGameState].mousereleased[button] then
        handled = InputHandler.handlers[InputHandler.currentGameState].mousereleased[button](x, y, isTouch, presses) or handled
    end
    
    return handled
end

-- Handle mouse movement
function InputHandler.handleMouseMoved(x, y, dx, dy, isTouch)
    local handled = false
    
    -- First check global handlers
    if InputHandler.handlers.global.mousemoved.any then
        handled = InputHandler.handlers.global.mousemoved.any(x, y, dx, dy, isTouch) or handled
    end
    
    -- Then check state-specific handlers
    if not handled and InputHandler.handlers[InputHandler.currentGameState] and 
       InputHandler.handlers[InputHandler.currentGameState].mousemoved.any then
        handled = InputHandler.handlers[InputHandler.currentGameState].mousemoved.any(x, y, dx, dy, isTouch) or handled
    end
    
    return handled
end

-- Handle mouse wheel movement
function InputHandler.handleWheelMoved(x, y)
    local handled = false
    
    -- First check global handlers
    if InputHandler.handlers.global.wheelmoved.any then
        handled = InputHandler.handlers.global.wheelmoved.any(x, y) or handled
    end
    
    -- Then check state-specific handlers
    if not handled and InputHandler.handlers[InputHandler.currentGameState] and 
       InputHandler.handlers[InputHandler.currentGameState].wheelmoved.any then
        handled = InputHandler.handlers[InputHandler.currentGameState].wheelmoved.any(x, y) or handled
    end
    
    return handled
end

-- Check if a key was just pressed this frame
function InputHandler.wasPressed(key)
    return InputHandler.keysPressed[key] == true
end

-- Check if a key is currently held down
function InputHandler.isDown(key)
    return InputHandler.keysDown[key] == true
end

-- Check if a mouse button is currently down
function InputHandler.isMouseDown(button)
    return InputHandler.mouseButtons[button] == true
end

-- Get movement input as a normalized vector (for character movement)
function InputHandler.getMovementVector()
    local dx, dy = 0, 0
    
    -- Only process movement in playing state
    if InputHandler.currentGameState ~= "playing" then
        return dx, dy
    end
    
    -- Check common movement keys
    if InputHandler.keysDown["w"] or InputHandler.keysDown["up"] then
        dy = dy - 1
    end
    if InputHandler.keysDown["s"] or InputHandler.keysDown["down"] then
        dy = dy + 1
    end
    if InputHandler.keysDown["a"] or InputHandler.keysDown["left"] then
        dx = dx - 1
    end
    if InputHandler.keysDown["d"] or InputHandler.keysDown["right"] then
        dx = dx + 1
    end
    
    -- Normalize if we're moving diagonally
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx = dx / length
        dy = dy / length
    end
    
    return dx, dy
end

-- Called in love.update to reset per-frame input states
function InputHandler.update(dt)
    -- Reset keys that were pressed this frame
    InputHandler.keysPressed = {}
    
    -- Reset scroll values
    InputHandler.scrollX = 0
    InputHandler.scrollY = 0
end

return InputHandler
