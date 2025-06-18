local Console = {
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
function Console.init()
    Console.font = love.graphics.newFont(14)
      -- Register default commands
    Console.registerCommand("help", function(args)
        Console.log("Available commands:")
        for cmd, info in pairs(Console.commands) do
            Console.log("  " .. cmd .. " - " .. info.description)
        end
    end, "Show available commands")
    
    Console.registerCommand("clear", function()
        Console.history = {}
    end, "Clear console output")
    
    -- Player info commands
    Console.registerCommand("player", function(args)
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
    Console.registerCommand("game", function(args)
        if args[1] == "state" then
            return "Game state: " .. _G.gameState
        else
            return "Usage: game [state]"
        end
    end, "Show game information")
    
    -- Register keyboard input handlers
    love.keypressed = function(key, scancode, isrepeat)
        Console.handleKeyPress(key, scancode, isrepeat)
    end
    
    love.textinput = function(text)
        Console.handleTextInput(text)
    end
    
    -- Print welcome message
    Console.log("Debug Console initialized. Press ~ to toggle.")
    Console.log("Type 'help' for available commands.")
end

-- Register a new console command
function Console.registerCommand(name, func, description)
    Console.commands[name] = {
        func = func,
        description = description or "No description available."
    }
end

-- Toggle console visibility
function Console.toggle()
    Console.visible = not Console.visible
end

-- Add a message to the console
function Console.log(message, color)
    color = color or Console.textColor
    table.insert(Console.history, {text = message, color = color})
    
    -- Trim history to max lines
    while #Console.history > Console.maxLines do
        table.remove(Console.history, 1)
    end
end

-- Add debug info to the console
function Console.addDebugInfo(label, value)
    Console.log(label .. ": " .. tostring(value))
end

-- Execute a command
function Console.execute(commandLine)
    if commandLine == "" then return end
    
    -- Add to history
    table.insert(Console.commandHistory, commandLine)
    if #Console.commandHistory > 50 then
        table.remove(Console.commandHistory, 1)
    end
    Console.commandHistoryIndex = #Console.commandHistory + 1
    
    -- Log the command
    Console.log("> " .. commandLine, Console.commandColor)
    
    -- Parse command and arguments
    local parts = {}
    for part in commandLine:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    local command = parts[1]
    table.remove(parts, 1)
    
    -- Execute command if it exists
    if Console.commands[command] then
        local success, result = pcall(function() 
            return Console.commands[command].func(parts) 
        end)
        
        if not success then
            Console.log("Error: " .. tostring(result), Console.errorColor)
        elseif result then
            Console.log(tostring(result))
        end
    else
        Console.log("Unknown command: " .. command, Console.errorColor)
    end
    
    -- Clear input
    Console.inputText = ""
    Console.cursorPos = 0
end

-- Handle key presses
function Console.handleKeyPress(key, scancode, isrepeat)
    -- Toggle console with tilde (~)
    if key == "`" or key == "backquote" or key == "grave" then
        Console.toggle()
        return
    end
    
    -- Only process other keys when console is visible
    if not Console.visible then return end
    
    if key == "return" or key == "kpenter" then
        Console.execute(Console.inputText)
    elseif key == "backspace" then
        if Console.cursorPos > 0 then
            Console.inputText = string.sub(Console.inputText, 1, Console.cursorPos - 1) .. 
                              string.sub(Console.inputText, Console.cursorPos + 1)
            Console.cursorPos = Console.cursorPos - 1
        end
    elseif key == "delete" then
        Console.inputText = string.sub(Console.inputText, 1, Console.cursorPos) .. 
                          string.sub(Console.inputText, Console.cursorPos + 2)
    elseif key == "left" then
        Console.cursorPos = math.max(0, Console.cursorPos - 1)
    elseif key == "right" then
        Console.cursorPos = math.min(#Console.inputText, Console.cursorPos + 1)
    elseif key == "home" then
        Console.cursorPos = 0
    elseif key == "end" then
        Console.cursorPos = #Console.inputText
    elseif key == "up" then
        -- Navigate command history
        if #Console.commandHistory > 0 then
            Console.commandHistoryIndex = math.max(1, Console.commandHistoryIndex - 1)
            Console.inputText = Console.commandHistory[Console.commandHistoryIndex] or ""
            Console.cursorPos = #Console.inputText
        end
    elseif key == "down" then
        -- Navigate command history
        if Console.commandHistoryIndex < #Console.commandHistory then
            Console.commandHistoryIndex = Console.commandHistoryIndex + 1
            Console.inputText = Console.commandHistory[Console.commandHistoryIndex] or ""
        else
            Console.commandHistoryIndex = #Console.commandHistory + 1
            Console.inputText = ""
        end
        Console.cursorPos = #Console.inputText
    elseif key == "tab" then
        -- TODO: Command completion could go here
    end
end

-- Handle text input
function Console.handleTextInput(text)
    if not Console.visible then return end
    
    -- Insert text at cursor position
    Console.inputText = string.sub(Console.inputText, 1, Console.cursorPos) .. 
                      text .. 
                      string.sub(Console.inputText, Console.cursorPos + 1)
    Console.cursorPos = Console.cursorPos + #text
end

-- Update console state
function Console.update(dt)
    -- Nothing to update for now
end

-- Show player debug info
function Console.showPlayerDebugInfo()
    if not Console.visible then return end
    
    -- Display player debug info
    if Console._playerState then
        local y = 5
        love.graphics.setFont(Console.font)
        love.graphics.setColor(Console.textColor)
        
        -- Show in a compact form at the top
        local debugInfo = ""
        if Console._playerState then debugInfo = debugInfo .. Console._playerState .. " | " end
        if Console._playerFacing then debugInfo = debugInfo .. Console._playerFacing .. " | " end
        if Console._playerPosition then debugInfo = debugInfo .. Console._playerPosition end
        
        love.graphics.print(debugInfo, 5, y)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Draw the console
function Console.draw()
    -- If console not visible, still show compact debug info
    if not Console.visible then 
        Console.showPlayerDebugInfo()
        return 
    end
    
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(Console.font)
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local consoleHeight = screenHeight * Console.height
    
    -- Draw console background
    love.graphics.setColor(Console.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, screenWidth, consoleHeight)
    
    -- Draw border
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", 0, 0, screenWidth, consoleHeight)
    love.graphics.line(0, consoleHeight - 25, screenWidth, consoleHeight - 25)
    
    -- Draw history
    local lineHeight = Console.font:getHeight() + 2
    local y = consoleHeight - 35 - lineHeight * #Console.history
    
    for i, line in ipairs(Console.history) do
        love.graphics.setColor(line.color)
        love.graphics.print(line.text, 10, y)
        y = y + lineHeight
    end
    
    -- Draw input field
    love.graphics.setColor(Console.textColor)
    love.graphics.print("> " .. Console.inputText, 10, consoleHeight - 20)
    
    -- Draw cursor
    local cursorX = 10 + Console.font:getWidth("> " .. string.sub(Console.inputText, 1, Console.cursorPos))
    love.graphics.rectangle("fill", cursorX, consoleHeight - 20, 2, Console.font:getHeight())
    
    -- Reset color and font
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(oldFont)
end

return Console
