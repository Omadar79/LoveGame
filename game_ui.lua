-- Create a basic UI setup for the game
local UI = require("ui")

-- Initialize game UI
local function initGameUI(player)
    -- Health bar in top left corner
    local healthBar = UI.createHealthBar(20, 20, 200, 20, 100, 100)
    
    -- Health text
    local healthText = UI.createText(20, 45, "Health: 100/100", "small")
    
    -- Update function for health display
    local updateHealth = function()
        local health = player.health or 100  -- Default if not defined
        local maxHealth = player.maxHealth or 100
        healthBar:setHealth(health)
        healthText:setText("Health: " .. health .. "/" .. maxHealth)
    end
    
    -- Call initially
    updateHealth()
    
    -- Return functions to update UI
    return {
        updateHealth = updateHealth
    }
end

-- Initialize pause menu
local function initPauseMenu(resumeCallback)
    -- Clear existing UI
    UI.clear()
    
    -- Create semi-transparent panel
    local width = 300
    local height = 400
    local x = (love.graphics.getWidth() - width) / 2
    local y = (love.graphics.getHeight() - height) / 2
    
    local panel = UI.createPanel(x, y, width, height)
    
    -- Title
    UI.createText(x + width/2 - 50, y + 30, "PAUSED", "large")
    
    -- Buttons
    local buttonWidth = 200
    local buttonHeight = 50
    local buttonX = x + (width - buttonWidth) / 2
    
    -- Resume button
    UI.createButton(
        buttonX, 
        y + 100, 
        buttonWidth, 
        buttonHeight, 
        "Resume Game",
        resumeCallback
    )
    
    -- Settings button
    UI.createButton(
        buttonX, 
        y + 170, 
        buttonWidth, 
        buttonHeight, 
        "Settings",
        function() 
            -- Show settings dialog
            UI.createDialog(
                "Settings",
                "Settings options would go here.",
                {{"Back", function() UI.closeDialog() end}}
            )
        end
    )
    
    -- Quit button
    UI.createButton(
        buttonX, 
        y + 240, 
        buttonWidth, 
        buttonHeight, 
        "Quit Game",
        function()
            UI.createDialog(
                "Confirm",
                "Are you sure you want to quit?",
                {
                    {"Yes", function() love.event.quit() end},
                    {"No", function() UI.closeDialog() end}
                }
            )
        end
    )
end

-- Initialize main menu
local function initMainMenu(startCallback)
    -- Clear existing UI
    UI.clear()
    
    -- Game title
    local title = UI.createText(
        love.graphics.getWidth() / 2 - 100,
        100,
        "LOVE GAME",
        "title",
        {1, 0.8, 0.2, 1}
    )
    
    -- Start button
    UI.createButton(
        love.graphics.getWidth() / 2 - 100,
        250,
        200,
        50,
        "Start Game",
        startCallback
    )
    
    -- Settings button
    UI.createButton(
        love.graphics.getWidth() / 2 - 100,
        320,
        200,
        50,
        "Settings",
        function()
            UI.createDialog(
                "Settings",
                "Settings options would go here.",
                {{"Back", function() UI.closeDialog() end}}
            )
        end
    )
    
    -- Quit button
    UI.createButton(
        love.graphics.getWidth() / 2 - 100,
        390,
        200,
        50,
        "Quit",
        function() love.event.quit() end
    )
end

return {
    initGameUI = initGameUI,
    initPauseMenu = initPauseMenu,
    initMainMenu = initMainMenu
}
