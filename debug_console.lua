local DebugConsole = {
    visible = false,
    history = {},
    commandHistory = {},
    commandHistoryIndex = 0,
    maxLines = 20,
    inputText = "",
    cursorPos = 0,
    backgroundColor = {0.1, 0.1, 0.1, 0.8},
    textColor = {1, 1, 1, 1},
    commandColor = {0.5, 1, 0.5, 1},
    errorColor = {1, 0.5, 0.5, 1},
    font = nil,
    height = 0.4, -- Percentage of screen height
    commands = {}
}

-- Initialize the console
function DebugConsole.init()
    DebugConsole.font = love.graphics.newFont(14)
    
    -- Register default commands
    DebugConsole.registerCommand("help", function(args)
        DebugConsole.log("Available commands:")
        for cmd, info in pairs(DebugConsole.commands) do
            DebugConsole.log("  " .. cmd .. " - " .. info.description)
        end
    end, "Show available commands")
    
    DebugConsole.registerCommand("clear", function()
        DebugConsole.history = {}
    end, "Clear console output")
    
    -- Player info commands
    DebugConsole.registerCommand("player", function(args)
        if not _G.player then
            return "Player not initialized yet"
        end
        
        if args[1] == "pos" or args[1] == "position" then
            return string.format("Player position: %.1f, %.1f", _G.player.x, _G.player.y)
        elseif args[1] == "health" then
            return string.format("Player health: %d/%d", _G.player.health, _G.player.maxHealth)
        elseif args[1] == "state" then
            return "Player state: " .. _G.player.currentState
        elseif args[1] == "speed" and args[2] then
            local newSpeed = tonumber(args[2])
            if newSpeed then
                _G.player.speed = newSpeed
                return "Player speed set to " .. newSpeed
            else
                return "Invalid speed value"
            end
        else
            return "Usage: player [pos|health|state|speed <value>]"
        end
    end, "Show or modify player information")
    
    -- Game state commands
    DebugConsole.registerCommand("game", function(args)
        if args[1] == "state" then
            return "Game state: " .. _G.gameState
        else
            return "Usage: game [state]"
        end
    end, "Show game information")
    
    -- Save original key handlers
    DebugConsole._originalKeypressed = love.keypressed
    DebugConsole._originalTextinput = love.textinput
    
    -- Register keyboard input handlers
    love.keypressed = function(key, scancode, isrepeat)
        -- Handle console toggle key specially
        if key == "`" or key == "backquote" or key == "grave" then
            DebugConsole.toggle()
            return  -- Don't pass tilde key to input
        end
        
        -- Handle other keys for console
        if DebugConsole.visible then
            DebugConsole.handleKeyPress(key, scancode, isrepeat)
        elseif DebugConsole._originalKeypressed then
            -- Pass to original handler if console is hidden
            DebugConsole._originalKeypressed(key, scancode, isrepeat)
        end
    end
    
    love.textinput = function(text)
        if DebugConsole.visible then
            -- We already blocked the tilde in keypressed, but double check here
            if text ~= "`" and text ~= "~" then
                DebugConsole.handleTextInput(text)
            end
        elseif DebugConsole._originalTextinput then
            -- Pass to original handler if console is hidden
            DebugConsole._originalTextinput(text)
        end
    end
    
    -- Print welcome message
    DebugConsole.log("Debug Console initialized. Press ~ to toggle.")
    DebugConsole.log("Type 'help' for available commands.")
end

-- Register a new console command
function DebugConsole.registerCommand(name, func, description)
    DebugConsole.commands[name] = {
        func = func,
        description = description or "No description available."
    }
end

-- Toggle console visibility
function DebugConsole.toggle()
    DebugConsole.visible = not DebugConsole.visible
end

-- Add a message to the console
function DebugConsole.log(message, color)
    color = color or DebugConsole.textColor
    table.insert(DebugConsole.history, {text = message, color = color})
    
    -- Trim history to max lines
    while #DebugConsole.history > DebugConsole.maxLines do
        table.remove(DebugConsole.history, 1)
    end
end

-- Add debug info to the console
function DebugConsole.addDebugInfo(label, value)
    DebugConsole.log(label .. ": " .. tostring(value))
end

-- Execute a command
function DebugConsole.execute(commandLine)
    if commandLine == "" then return end
    
    -- Add to history
    table.insert(DebugConsole.commandHistory, commandLine)
    if #DebugConsole.commandHistory > 50 then
        table.remove(DebugConsole.commandHistory, 1)
    end
    DebugConsole.commandHistoryIndex = #DebugConsole.commandHistory + 1
    
    -- Log the command
    DebugConsole.log("> " .. commandLine, DebugConsole.commandColor)
    
    -- Parse command and arguments
    local parts = {}
    for part in commandLine:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    local command = parts[1]
    table.remove(parts, 1)
    
    -- Execute command if it exists
    if DebugConsole.commands[command] then
        local success, result = pcall(function() 
            return DebugConsole.commands[command].func(parts) 
        end)
        
        if not success then
            DebugConsole.log("Error: " .. tostring(result), DebugConsole.errorColor)
        elseif result then
            DebugConsole.log(tostring(result))
        end
    else
        DebugConsole.log("Unknown command: " .. command, DebugConsole.errorColor)
    end
    
    -- Clear input
    DebugConsole.inputText = ""
    DebugConsole.cursorPos = 0
end

-- Handle key presses
function DebugConsole.handleKeyPress(key, scancode, isrepeat)
    -- Only process other keys when console is visible
    if not DebugConsole.visible then return end
    
    if key == "return" or key == "kpenter" then
        DebugConsole.execute(DebugConsole.inputText)
    elseif key == "backspace" then
        if DebugConsole.cursorPos > 0 then
            DebugConsole.inputText = string.sub(DebugConsole.inputText, 1, DebugConsole.cursorPos - 1) .. 
                              string.sub(DebugConsole.inputText, DebugConsole.cursorPos + 1)
            DebugConsole.cursorPos = DebugConsole.cursorPos - 1
        end
    elseif key == "delete" then
        DebugConsole.inputText = string.sub(DebugConsole.inputText, 1, DebugConsole.cursorPos) .. 
                          string.sub(DebugConsole.inputText, DebugConsole.cursorPos + 2)
    elseif key == "left" then
        DebugConsole.cursorPos = math.max(0, DebugConsole.cursorPos - 1)
    elseif key == "right" then
        DebugConsole.cursorPos = math.min(#DebugConsole.inputText, DebugConsole.cursorPos + 1)
    elseif key == "home" then
        DebugConsole.cursorPos = 0
    elseif key == "end" then
        DebugConsole.cursorPos = #DebugConsole.inputText
    elseif key == "up" then
        -- Navigate command history
        if #DebugConsole.commandHistory > 0 then
            DebugConsole.commandHistoryIndex = math.max(1, DebugConsole.commandHistoryIndex - 1)
            DebugConsole.inputText = DebugConsole.commandHistory[DebugConsole.commandHistoryIndex] or ""
            DebugConsole.cursorPos = #DebugConsole.inputText
        end
    elseif key == "down" then
        -- Navigate command history
        if DebugConsole.commandHistoryIndex < #DebugConsole.commandHistory then
            DebugConsole.commandHistoryIndex = DebugConsole.commandHistoryIndex + 1
            DebugConsole.inputText = DebugConsole.commandHistory[DebugConsole.commandHistoryIndex] or ""
        else
            DebugConsole.commandHistoryIndex = #DebugConsole.commandHistory + 1
            DebugConsole.inputText = ""
        end
        DebugConsole.cursorPos = #DebugConsole.inputText
    elseif key == "tab" then
        -- TODO: Command completion could go here
    end
end

-- Handle text input
function DebugConsole.handleTextInput(text)
    if not DebugConsole.visible then return end
    
    -- Insert text at cursor position
    DebugConsole.inputText = string.sub(DebugConsole.inputText, 1, DebugConsole.cursorPos) .. 
                      text .. 
                      string.sub(DebugConsole.inputText, DebugConsole.cursorPos + 1)
    DebugConsole.cursorPos = DebugConsole.cursorPos + #text
end

-- Update console state
function DebugConsole.update(dt)
    -- Nothing to update for now
end

-- Show player debug info
function DebugConsole.showPlayerDebugInfo()
    if not DebugConsole.visible then return end
    
    -- Display player debug info
    if DebugConsole._playerState then
        local y = 5
        love.graphics.setFont(DebugConsole.font)
        love.graphics.setColor(DebugConsole.textColor)
        
        -- Show in a compact form at the top
        local debugInfo = ""
        if DebugConsole._playerState then debugInfo = debugInfo .. DebugConsole._playerState .. " | " end
        if DebugConsole._playerFacing then debugInfo = debugInfo .. DebugConsole._playerFacing .. " | " end
        if DebugConsole._playerPosition then debugInfo = debugInfo .. DebugConsole._playerPosition end
        
        love.graphics.print(debugInfo, 5, y)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Draw the console
function DebugConsole.draw()
    -- If console not visible, still show compact debug info
    if not DebugConsole.visible then 
        DebugConsole.showPlayerDebugInfo()
        return 
    end
    
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(DebugConsole.font)
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local consoleHeight = screenHeight * DebugConsole.height
    
    -- Draw console background
    love.graphics.setColor(DebugConsole.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, screenWidth, consoleHeight)
    
    -- Draw border
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", 0, 0, screenWidth, consoleHeight)
    love.graphics.line(0, consoleHeight - 25, screenWidth, consoleHeight - 25)
    
    -- Draw history
    local lineHeight = DebugConsole.font:getHeight() + 2
    local y = consoleHeight - 35 - lineHeight * #DebugConsole.history
    
    for i, line in ipairs(DebugConsole.history) do
        love.graphics.setColor(line.color)
        love.graphics.print(line.text, 10, y)
        y = y + lineHeight
    end
    
    -- Draw input field
    love.graphics.setColor(DebugConsole.textColor)
    love.graphics.print("> " .. DebugConsole.inputText, 10, consoleHeight - 20)
    
    -- Draw cursor
    local cursorX = 10 + DebugConsole.font:getWidth("> " .. string.sub(DebugConsole.inputText, 1, DebugConsole.cursorPos))
    love.graphics.rectangle("fill", cursorX, consoleHeight - 20, 2, DebugConsole.font:getHeight())
    
    -- Reset color and font
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(oldFont)
end

return DebugConsole
