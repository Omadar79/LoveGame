--------------------------------------------------------------------------------------
-- MODULAR DEBUG CONSOLE FOR LÖVE
-- A self-contained debug console for LÖVE projects that can be easily reused in any project.
-- This console allows you to execute commands, view debug variables, and interact with the game state.
--
-- HOW TO USE:
-- 1. Copy this file to your project's 'lib' directory
-- 2. In your main.lua:
--    local DebugConsole = require("lib.debug_console")
--
-- 3. IN YOUR love.load:
--    DebugConsole.init()
--    -- Register variables you want to monitor
--    DebugConsole.registerVariable("playerPos", {x=0, y=0}, "Player position")
--    DebugConsole.registerVariable("gameState", "menu", "Current game state")
--    
--    -- Register custom commands
--    DebugConsole.registerCommand("mycommand", "Description of my command", 
--        function(args)
--            DebugConsole.print("Command executed with " .. #args .. " arguments")
--        end)
--  
-- 4. IN YOUR love.update:
--    DebugConsole.update(dt)
--    -- Update variables you're tracking
--    DebugConsole.updateVariable("playerPos", {x=player.x, y=player.y})
--    DebugConsole.updateVariable("gameState", currentGameState)
--
-- 5. IN YOUR love.draw:
--    -- Draw everything else first, then:
--    DebugConsole.draw()
--
-- FEATURES:
-- - Toggle with ~ (tilde) key
-- - Command history (up/down arrows)
-- - Variable tracking
-- - Custom commands
-- - FPS and memory usage monitoring
--------------------------------------------------------------------------------------

local DebugConsole = {
    visible = false,
    history = {},
    input = "",
    cursorPosition = 0,
    historyPosition = 0,
    commandHistory = {},
    commands = {},
    -- Store debug variables internally instead of assuming globals
    debugVariables = {},
    defaultTextColor = {1, 1, 1, 1},
    callbackRegistry = {}  -- New: Store callbacks from the main program
}

function DebugConsole.init()
    DebugConsole.font = love.graphics.newFont(14)
    DebugConsole.smallFont = love.graphics.newFont(10)
    DebugConsole.lineHeight = DebugConsole.font:getHeight() * 1.2
    DebugConsole.maxLines = 15
    DebugConsole.padding = 5
    DebugConsole.inputPrefix = "> "
    
    DebugConsole.background = {0.1, 0.1, 0.2, 0.8}
    DebugConsole.textColor = {1, 1, 1, 1}
    DebugConsole.commandColor = {0.4, 1, 0.4, 1}
    DebugConsole.errorColor = {1, 0.4, 0.4, 1}
    DebugConsole.infoColor = {0.4, 0.8, 1, 1}
    
    -- Register basic commands
    DebugConsole.registerCommand("help", "Lists all available commands", 
        function() 
            DebugConsole.print("Available commands:")
            for cmd, info in pairs(DebugConsole.commands) do
                DebugConsole.print("  " .. cmd .. " - " .. info.description)
            end
        end)

    DebugConsole.registerCommand("clear", "Clears the console output", 
        function() 
            DebugConsole.history = {}
        end)
        
    -- Original handlers are stored here when console is visible
    DebugConsole.originalHandlers = {
        keypressed = nil,
        textinput = nil
    }
    
    -- Add resize handler
    DebugConsole.onResize()
    
    return DebugConsole
end

function DebugConsole.onResize()
    DebugConsole.width = love.graphics.getWidth()
    DebugConsole.height = math.min(DebugConsole.maxLines * DebugConsole.lineHeight + DebugConsole.padding * 4, 
                               love.graphics.getHeight() / 2)
end

-- New: Register a global variable for tracking
function DebugConsole.registerVariable(name, value, description)
    DebugConsole.debugVariables[name] = {
        value = value,
        description = description or "",
        watched = false
    }
end

-- New: Update a registered variable
function DebugConsole.updateVariable(name, value)
    if DebugConsole.debugVariables[name] then
        DebugConsole.debugVariables[name].value = value
    else
        DebugConsole.registerVariable(name, value)
    end
end

-- New: Register a callback function that will be called when certain commands are executed
function DebugConsole.registerCallback(name, callback)
    DebugConsole.callbackRegistry[name] = callback
end

function DebugConsole.registerCommand(name, description, handler)
    DebugConsole.commands[name] = {
        description = description,
        handler = handler
    }
end

function DebugConsole.toggle()
    DebugConsole.visible = not DebugConsole.visible
    
    -- Check if we have InputHandler integrated
    local InputHandler = package.loaded["lib.input_handler"]
    
    if DebugConsole.visible then
        -- Store original handlers if we're not using input handler
        if not InputHandler then
            DebugConsole.originalHandlers.keypressed = love.keypressed
            DebugConsole.originalHandlers.textinput = love.textinput
            
            -- Replace with console handlers
            love.keypressed = function(key)
                DebugConsole.keypressed(key)
            end
            
            love.textinput = function(text)
                DebugConsole.textinput(text)
            end
        end
        
        -- Notify InputHandler that debug console is open
        if InputHandler then
            InputHandler.DEBUG_MODE = true
        end
    else
        -- Restore original handlers if we're not using input handler
        if not InputHandler then
            if DebugConsole.originalHandlers.keypressed then
                love.keypressed = DebugConsole.originalHandlers.keypressed
            end
            
            if DebugConsole.originalHandlers.textinput then
                love.textinput = DebugConsole.originalHandlers.textinput
            end
        end
        
        -- Notify InputHandler that debug console is closed
        if InputHandler then
            InputHandler.DEBUG_MODE = false
        end
    end
end

function DebugConsole.print(text, color)
    table.insert(DebugConsole.history, {
        text = text,
        color = color or DebugConsole.textColor
    })
    
    -- Limit history size
    while #DebugConsole.history > 100 do
        table.remove(DebugConsole.history, 1)
    end
end

function DebugConsole.executeCommand(commandText)
    -- Add to command history
    table.insert(DebugConsole.commandHistory, commandText)
    if #DebugConsole.commandHistory > 20 then
        table.remove(DebugConsole.commandHistory, 1)
    end
    DebugConsole.historyPosition = #DebugConsole.commandHistory + 1
    
    -- Print the command
    DebugConsole.print(DebugConsole.inputPrefix .. commandText, DebugConsole.commandColor)
    
    -- Parse command
    local args = {}
    for arg in commandText:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    if #args == 0 then return end
    
    local commandName = args[1]
    table.remove(args, 1)
    
    -- Execute command
    if DebugConsole.commands[commandName] then
        DebugConsole.commands[commandName].handler(args)
    else
        DebugConsole.print("Unknown command: " .. commandName, DebugConsole.errorColor)
    end
end

function DebugConsole.keypressed(key)
    if key == "escape" and DebugConsole.visible then
        DebugConsole.toggle()
        return
    end
    
    if key == "`" or key == "~" then
        DebugConsole.toggle()
        return
    end
    
    if not DebugConsole.visible then
        -- Pass key press to original handler if console is hidden
        if DebugConsole.originalHandlers.keypressed then
            DebugConsole.originalHandlers.keypressed(key)
        end
        return
    end
    
    if key == "return" or key == "kpenter" then
        if DebugConsole.input ~= "" then
            DebugConsole.executeCommand(DebugConsole.input)
            DebugConsole.input = ""
            DebugConsole.cursorPosition = 0
        end
    elseif key == "backspace" then
        if DebugConsole.cursorPosition > 0 then
            DebugConsole.input = string.sub(DebugConsole.input, 1, DebugConsole.cursorPosition - 1) .. 
                             string.sub(DebugConsole.input, DebugConsole.cursorPosition + 1)
            DebugConsole.cursorPosition = DebugConsole.cursorPosition - 1
        end
    elseif key == "delete" then
        DebugConsole.input = string.sub(DebugConsole.input, 1, DebugConsole.cursorPosition) .. 
                         string.sub(DebugConsole.input, DebugConsole.cursorPosition + 2)
    elseif key == "left" then
        DebugConsole.cursorPosition = math.max(0, DebugConsole.cursorPosition - 1)
    elseif key == "right" then
        DebugConsole.cursorPosition = math.min(string.len(DebugConsole.input), DebugConsole.cursorPosition + 1)
    elseif key == "up" then
        if DebugConsole.historyPosition > 1 then
            DebugConsole.historyPosition = DebugConsole.historyPosition - 1
            DebugConsole.input = DebugConsole.commandHistory[DebugConsole.historyPosition]
            DebugConsole.cursorPosition = string.len(DebugConsole.input)
        end
    elseif key == "down" then
        if DebugConsole.historyPosition < #DebugConsole.commandHistory then
            DebugConsole.historyPosition = DebugConsole.historyPosition + 1
            DebugConsole.input = DebugConsole.commandHistory[DebugConsole.historyPosition]
            DebugConsole.cursorPosition = string.len(DebugConsole.input)
        elseif DebugConsole.historyPosition == #DebugConsole.commandHistory then
            DebugConsole.historyPosition = DebugConsole.historyPosition + 1
            DebugConsole.input = ""
            DebugConsole.cursorPosition = 0
        end
    elseif key == "home" then
        DebugConsole.cursorPosition = 0
    elseif key == "end" then
        DebugConsole.cursorPosition = string.len(DebugConsole.input)
    end
end

function DebugConsole.textinput(text)
    if not DebugConsole.visible then
        -- Pass text input to original handler if console is hidden
        if DebugConsole.originalHandlers.textinput then
            DebugConsole.originalHandlers.textinput(text)
        end
        return
    end
    
    -- Don't add the tilde character when using it to open console
    if text == "`" or text == "~" then
        return
    end
    
    -- Insert text at cursor position
    DebugConsole.input = string.sub(DebugConsole.input, 1, DebugConsole.cursorPosition) .. text .. 
                     string.sub(DebugConsole.input, DebugConsole.cursorPosition + 1)
    DebugConsole.cursorPosition = DebugConsole.cursorPosition + string.len(text)
end

function DebugConsole.update(dt)
    -- Blink cursor
    if love.timer.getTime() % 1 > 0.5 then
        DebugConsole.showCursor = true
    else
        DebugConsole.showCursor = false
    end
end

-- Helper function to format variable values for display
function DebugConsole.formatVarValue(value)
    local displayValue = tostring(value)
    if type(value) == "table" then
        -- Try to format tables nicely if they're simple
        if value.x and value.y then
            displayValue = string.format("{x=%.1f, y=%.1f}", value.x, value.y)
        elseif #value <= 4 then
            -- Small arrays
            local elements = {}
            for i, v in ipairs(value) do
                elements[i] = tostring(v)
            end
            displayValue = "{" .. table.concat(elements, ", ") .. "}"
        else
            -- Default for other tables
            displayValue = "{table}"
        end
    elseif type(value) == "function" then
        displayValue = "{function}"
    elseif type(value) == "number" then
        -- Format numbers to one decimal place
        displayValue = string.format("%.1f", value)
    end
    return displayValue
end

function DebugConsole.draw()
    -- When not visible, just draw minimal debug info at top
    if not DebugConsole.visible then
        local y = 5
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setFont(DebugConsole.smallFont)
        
        -- Draw FPS info
        love.graphics.print("FPS: " .. love.timer.getFPS(), 5, y)
        y = y + DebugConsole.smallFont:getHeight()
        
        -- Draw watched debug variables
        local hasWatched = false
        for name, info in pairs(DebugConsole.debugVariables) do
            if info.watched then
                hasWatched = true
                local displayValue = DebugConsole.formatVarValue(info.value)
                love.graphics.print(name .. ": " .. displayValue, 5, y)
                y = y + DebugConsole.smallFont:getHeight()
            end
        end
        
        -- If we're not watching any specific variables, show a few by default
        if not hasWatched then
            local count = 0
            for name, info in pairs(DebugConsole.debugVariables) do
                local displayValue = DebugConsole.formatVarValue(info.value)
                love.graphics.print(name .. ": " .. displayValue, 5, y)
                y = y + DebugConsole.smallFont:getHeight()
                
                count = count + 1
                if count >= 3 then break end -- Only show 3 variables when collapsed
            end
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    
    -- Draw console background
    love.graphics.setColor(DebugConsole.background)
    love.graphics.rectangle("fill", 0, 0, DebugConsole.width, DebugConsole.height)
    
    -- Draw history
    love.graphics.setFont(DebugConsole.font)
    local y = DebugConsole.height - DebugConsole.lineHeight * 2 - DebugConsole.padding
    
    -- Calculate which history entries to show
    local startIdx = math.max(1, #DebugConsole.history - DebugConsole.maxLines + 1)
    for i = startIdx, #DebugConsole.history do
        local entry = DebugConsole.history[i]
        love.graphics.setColor(entry.color)
        love.graphics.print(entry.text, DebugConsole.padding, y)
        y = y - DebugConsole.lineHeight
    end
    
    -- Draw input line
    love.graphics.setColor(DebugConsole.textColor)
    y = DebugConsole.height - DebugConsole.lineHeight - DebugConsole.padding
    love.graphics.print(DebugConsole.inputPrefix .. DebugConsole.input, DebugConsole.padding, y)
    
    -- Draw cursor
    if DebugConsole.showCursor then
        local cursorX = DebugConsole.padding + DebugConsole.font:getWidth(DebugConsole.inputPrefix .. 
                     string.sub(DebugConsole.input, 1, DebugConsole.cursorPosition))
        love.graphics.line(cursorX, y, cursorX, y + DebugConsole.lineHeight)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Add default commands that work with any project
DebugConsole.registerCommand("fps", "Show current FPS", 
    function() 
        DebugConsole.print("Current FPS: " .. love.timer.getFPS())
    end)

DebugConsole.registerCommand("memory", "Show memory usage", 
    function() 
        local usage = collectgarbage("count")
        DebugConsole.print(string.format("Memory usage: %.2f KB (%.2f MB)", usage, usage/1024))
    end)

DebugConsole.registerCommand("vars", "List all debug variables", 
    function() 
        DebugConsole.print("Debug variables:")
        for name, info in pairs(DebugConsole.debugVariables) do
            local value = info.value
            local valueStr = DebugConsole.formatVarValue(value)
            local watchStatus = info.watched and " [WATCHED]" or ""
            
            DebugConsole.print("  " .. name .. " = " .. valueStr .. watchStatus)
        end
    end)
    
DebugConsole.registerCommand("gc", "Run garbage collection", 
    function() 
        local before = collectgarbage("count")
        collectgarbage("collect")
        local after = collectgarbage("count")
        DebugConsole.print(string.format("Garbage collected: %.2f KB", before - after))
    end)
    
DebugConsole.registerCommand("watch", "Watch a variable continuously (watch varname)", 
    function(args) 
        if #args < 1 then
            DebugConsole.print("Usage: watch <varname>", DebugConsole.errorColor)
            return
        end
        
        local varName = args[1]
        if not DebugConsole.debugVariables[varName] then
            DebugConsole.print("Variable '" .. varName .. "' not found", DebugConsole.errorColor)
            return
        end
        
        DebugConsole.debugVariables[varName].watched = true
        DebugConsole.print("Now watching '" .. varName .. "'")
    end)
    
DebugConsole.registerCommand("unwatch", "Stop watching a variable (unwatch varname)", 
    function(args) 
        if #args < 1 then
            DebugConsole.print("Usage: unwatch <varname>", DebugConsole.errorColor)
            return
        end
        
        local varName = args[1]
        if not DebugConsole.debugVariables[varName] then
            DebugConsole.print("Variable '" .. varName .. "' not found", DebugConsole.errorColor)
            return
        end
        
        DebugConsole.debugVariables[varName].watched = false
        DebugConsole.print("Stopped watching '" .. varName .. "'")
    end)
    
DebugConsole.registerCommand("system", "Show system information", 
    function() 
        DebugConsole.print("System Information:")
        DebugConsole.print("  LÖVE version: " .. love._version)
        DebugConsole.print("  OS: " .. love.system.getOS())
        DebugConsole.print("  Window size: " .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight())
        DebugConsole.print("  Renderer: " .. love.graphics.getRendererInfo())
        DebugConsole.print("  Processor cores: " .. love.system.getProcessorCount())
    end)
    
-- Command to inspect table contents
DebugConsole.registerCommand("inspect", "Inspect table contents (inspect varname)", 
    function(args) 
        if #args < 1 then
            DebugConsole.print("Usage: inspect <varname>", DebugConsole.errorColor)
            return
        end
        
        local varName = args[1]
        if not DebugConsole.debugVariables[varName] then
            DebugConsole.print("Variable '" .. varName .. "' not found", DebugConsole.errorColor)
            return
        end
        
        local value = DebugConsole.debugVariables[varName].value
        if type(value) ~= "table" then
            DebugConsole.print("Variable '" .. varName .. "' is not a table", DebugConsole.errorColor)
            return
        end
        
        DebugConsole.print("Contents of " .. varName .. ":")
        for k, v in pairs(value) do
            local valueStr = DebugConsole.formatVarValue(v)
            DebugConsole.print("  " .. tostring(k) .. " = " .. valueStr)
        end
    end)

return DebugConsole