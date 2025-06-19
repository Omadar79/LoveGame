--------------------------------------------------------------------------------------
-- GAME INPUT MANAGER
-- A game-specific input management layer that sits between main.lua and the InputHandler
-- This module handles:
-- 1. Game-specific input states (menu, playing, paused)
-- 2. Input bindings for various game actions
-- 3. Unified input registration with the InputHandler
--------------------------------------------------------------------------------------

local InputHandler = require("lib.input_handler")
local DebugConsole = require("lib.debug_console")
local UI = require("ui")

local Input = {
    currentGameState = "menu", -- Default state, will be updated
    bindings = {
        -- Default key bindings that can be overridden
        up = {"w", "up"},
        down = {"s", "down"},
        left = {"a", "left"},
        right = {"d", "right"},
        jump = {"space"},
        attack = {"f"},
        interact = {"e"},
        pause = {"escape"},
        confirm = {"return", "kpenter"},
        back = {"escape", "backspace"}
    }
}

-- Initialize the input system
function Input.init(gameState, player, mainModule)
    -- Store references
    Input.gameState = gameState
    Input.player = player
    Input.mainModule = mainModule or _G  -- Use global environment if not provided
    
    -- Initialize the lower-level input handler
    InputHandler.init(gameState)
    
    -- Register all input handlers
    Input.registerAllHandlers()
    
    -- Set up default callbacks
    Input.registerDefaultCallbacks()
    
    return Input
end

-- Register default callbacks that integrate with common game functions
function Input.registerDefaultCallbacks()
    Input.registerCallbacks({
        -- Menu callbacks
        onMenuConfirm = function()
            if Input.mainModule.startGame then
                Input.mainModule.startGame()
                return true
            end
            return false
        end,
        
        -- Pause menu callbacks
        onResumeGame = function()
            if Input.mainModule.resumeGame then
                Input.mainModule.resumeGame()
                return true
            end
            return false
        end,
        
        -- Game state transition callbacks
        onPauseGame = function()
            if Input.mainModule.gameState == "playing" and not DebugConsole.visible then
                Input.mainModule.gameState = "paused"
                Input.setGameState(Input.mainModule.gameState)
                UI.clear()
                if Input.mainModule.GameUI then
                    Input.mainModule.GameUI.initPauseMenu(function()
                        if Input.mainModule.resumeGame then
                            Input.mainModule.resumeGame()
                        end
                    end)
                end
                return true
            end
            return false
        end
    })
end

-- Update game state in both this module and the InputHandler
function Input.setGameState(newState)
    Input.currentGameState = newState
    InputHandler.setGameState(newState)
    return newState
end

-- Register all input handlers for all game states
function Input.registerAllHandlers()
    -- Clear any existing handlers
    -- InputHandler doesn't have a clear method, but we're overriding all handlers
    
    -- Register menu state handlers
    Input.registerMenuHandlers()
    
    -- Register playing state handlers
    Input.registerPlayingHandlers()
    
    -- Register paused state handlers
    Input.registerPausedHandlers()
    
    -- Register global handlers (work in all states)
    Input.registerGlobalHandlers()
    
    -- Register UI handlers
    Input.registerUIHandlers()
    
    -- Register debug handlers
    Input.registerDebugHandlers()
end

-- Register menu state input handlers
function Input.registerMenuHandlers()
    -- Register key handlers for menu navigation
    for _, key in ipairs(Input.bindings.confirm) do
        InputHandler.registerKeyPressed("menu", key, function()
            -- Delegate to the main game's onMenuConfirm function if it exists
            if Input.callbacks and Input.callbacks.onMenuConfirm then
                return Input.callbacks.onMenuConfirm()
            end
            return false
        end)
    end
    
    for _, key in ipairs(Input.bindings.back) do
        InputHandler.registerKeyPressed("menu", key, function()
            -- Delegate to the main game's onMenuBack function if it exists
            if Input.callbacks and Input.callbacks.onMenuBack then
                return Input.callbacks.onMenuBack()
            end
            return false
        end)
    end
    
    -- Menu navigation
    for _, key in ipairs(Input.bindings.up) do
        InputHandler.registerKeyPressed("menu", key, function()
            -- Handle menu navigation up
            if Input.callbacks and Input.callbacks.onMenuUp then
                return Input.callbacks.onMenuUp()
            end
            return false
        end)
    end
    
    for _, key in ipairs(Input.bindings.down) do
        InputHandler.registerKeyPressed("menu", key, function()
            -- Handle menu navigation down
            if Input.callbacks and Input.callbacks.onMenuDown then
                return Input.callbacks.onMenuDown()
            end
            return false
        end)
    end
end

-- Register playing state input handlers
function Input.registerPlayingHandlers()
    -- Most of these are handled in the update function of the player
    -- But we can handle state transitions here
    
    -- Pause game
    for _, key in ipairs(Input.bindings.pause) do
        InputHandler.registerKeyPressed("playing", key, function()
            if Input.callbacks and Input.callbacks.onPauseGame then
                return Input.callbacks.onPauseGame()
            end
            return false
        end)
    end
    
    -- For actions that need specific press handling (not just checking isDown)
    for _, key in ipairs(Input.bindings.jump) do
        InputHandler.registerKeyPressed("playing", key, function()
            if Input.callbacks and Input.callbacks.onJump then
                return Input.callbacks.onJump()
            end
            return false
        end)
    end
    
    for _, key in ipairs(Input.bindings.attack) do
        InputHandler.registerKeyPressed("playing", key, function()
            if Input.callbacks and Input.callbacks.onAttack then
                return Input.callbacks.onAttack()
            end
            return false
        end)
    end
    
    for _, key in ipairs(Input.bindings.interact) do
        InputHandler.registerKeyPressed("playing", key, function()
            if Input.callbacks and Input.callbacks.onInteract then
                return Input.callbacks.onInteract()
            end
            return false
        end)
    end
end

-- Register paused state input handlers
function Input.registerPausedHandlers()
    -- Resume game
    for _, key in ipairs(Input.bindings.pause) do
        InputHandler.registerKeyPressed("paused", key, function()
            if Input.callbacks and Input.callbacks.onResumeGame then
                return Input.callbacks.onResumeGame()
            end
            return false
        end)
    end
    
    -- Confirm selection
    for _, key in ipairs(Input.bindings.confirm) do
        InputHandler.registerKeyPressed("paused", key, function()
            if Input.callbacks and Input.callbacks.onPauseConfirm then
                return Input.callbacks.onPauseConfirm()
            end
            return false
        end)
    end
    
    -- Back/cancel
    for _, key in ipairs(Input.bindings.back) do
        InputHandler.registerKeyPressed("paused", key, function()
            if Input.callbacks and Input.callbacks.onPauseBack then
                return Input.callbacks.onPauseBack()
            end
            return false
        end)
    end
    
    -- Menu navigation
    for _, key in ipairs(Input.bindings.up) do
        InputHandler.registerKeyPressed("paused", key, function()
            if Input.callbacks and Input.callbacks.onPauseMenuUp then
                return Input.callbacks.onPauseMenuUp()
            end
            return false
        end)
    end
    
    for _, key in ipairs(Input.bindings.down) do
        InputHandler.registerKeyPressed("paused", key, function()
            if Input.callbacks and Input.callbacks.onPauseMenuDown then
                return Input.callbacks.onPauseMenuDown()
            end
            return false
        end)
    end
end

-- Register global input handlers (work in all states)
function Input.registerGlobalHandlers()
    -- Debug console toggle
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
    
    -- Debug keys
    InputHandler.registerGlobalKeyPressed("f3", function()
        if DebugConsole then
            DebugConsole.print("FPS: " .. love.timer.getFPS(), {0.2, 1, 0.2, 1})
            return true
        end
        return false
    end)
end

-- Register UI input handlers
function Input.registerUIHandlers()
    -- Register left mouse button handlers for UI interaction
    InputHandler.registerGlobalMousePressed(1, function(x, y)
        if UI and UI.handleMousePressed then
            return UI.handleMousePressed(x, y, 1)
        end
        return false
    end)
    
    InputHandler.registerGlobalMouseReleased(1, function(x, y)
        if UI and UI.handleMouseReleased then
            return UI.handleMouseReleased(x, y, 1)
        end
        return false
    end)
end

-- Register debug input handlers
function Input.registerDebugHandlers()
    -- Add any debug-specific input handlers here
    -- Example: Toggle hitboxes display, etc.
end

-- Register debug input handlers
function Input.registerDebugHandlers()
    -- Add any debug-specific input handlers here
    -- Example: Toggle hitboxes display, etc.
end

-- Register callbacks from the main game
function Input.registerCallbacks(callbacks)
    Input.callbacks = callbacks
end

-- Helper function to get a movement vector for the player based on current input
function Input.getMovementVector()
    -- Just delegate to the InputHandler
    return InputHandler.getMovementVector()
end

-- Update function to be called from main.lua
function Input.update(dt)
    InputHandler.update(dt)
end

-- Methods to check input state
function Input.isDown(action)
    -- Map the action to its bound keys and check if any are down
    local keys = Input.bindings[action]
    if not keys then return false end
    
    for _, key in ipairs(keys) do
        if InputHandler.isDown(key) then
            return true
        end
    end
    return false
end

function Input.wasPressed(action)
    -- Map the action to its bound keys and check if any were just pressed
    local keys = Input.bindings[action]
    if not keys then return false end
    
    for _, key in ipairs(keys) do
        if InputHandler.wasPressed(key) then
            return true
        end
    end
    return false
end

-- Method to rebind a key
function Input.rebindKey(action, newKeys)
    if type(newKeys) == "string" then
        newKeys = {newKeys}
    end
    Input.bindings[action] = newKeys
end

-- Function to get mouse position
function Input.getMousePosition()
    return love.mouse.getPosition()
end
-- Function to check if a mouse button is down
function Input.isMouseDown(button)
    return InputHandler.isMouseDown(button)
end

-- Low-level event handler functions that can be called directly from love.run
-- These delegate to InputHandler but could be customized here if needed
function Input.handleKeyPressed(key, scancode, isRepeat)
    return InputHandler.handleKeyPressed(key, scancode, isRepeat)
end

function Input.handleKeyReleased(key, scancode)
    return InputHandler.handleKeyReleased(key, scancode)
end

function Input.handleMousePressed(x, y, button, isTouch, presses)
    return InputHandler.handleMousePressed(x, y, button, isTouch, presses)
end

function Input.handleMouseReleased(x, y, button, isTouch, presses)
    return InputHandler.handleMouseReleased(x, y, button, isTouch, presses)
end

function Input.handleMouseMoved(x, y, dx, dy, isTouch)
    return InputHandler.handleMouseMoved(x, y, dx, dy, isTouch)
end

function Input.handleWheelMoved(x, y)
    return InputHandler.handleWheelMoved(x, y)
end

return Input
