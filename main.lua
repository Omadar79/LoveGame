
local Player = require("player")
local Level = require("level")
local UI = require("ui")
local GameUI = require("game_ui")

-- Game state variables
local gameState = "menu"  -- Can be "menu", "playing", "paused"
local uiCallbacks = {}

function love.load()
    -- Create player at center of screen
    player = Player.new(400, 300)

	-- Load level (either directly or from a file)
    currentLevel = Level.new(require("levels/level1"))
    
    -- Initialize UI system
    UI.init()
    
    -- Load main menu UI
    GameUI.initMainMenu(function()
        -- Start game callback
        gameState = "playing"
        UI.clear()
        uiCallbacks = GameUI.initGameUI(player)
    end)


end

function love.run()
	if love.load then 
        love.load(love.arg.parseGameArguments(arg), arg) 
    end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then 
        love.timer.step() 
    end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt (deltaTime), as we'll be passing it to update
		if love.timer then 
            dt = love.timer.step() 
        end

		-- Call update 
		if love.update then 
            love.update(dt) 
        end -- will pass 0 if love.timer is disabled

        -- Call draw
		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then 
                love.draw() 
            end

			love.graphics.present()
		end

        -- If we have a thread, we can yield to it.
		if love.timer then 
            love.timer.sleep(0.001) 
        end
	end
end

function love.update(dt)
    -- Handle input for game state changes
    if gameState == "playing" and love.keyboard.isDown("escape") then
        gameState = "paused"
        UI.clear()
        GameUI.initPauseMenu(function()
            gameState = "playing"
            UI.clear()
            uiCallbacks = GameUI.initGameUI(player)
        end)
    end

    -- Only update game elements if playing
    if gameState == "playing" then
        player:update(dt, currentLevel)
        currentLevel:update(dt, player)
        
        -- Update UI with player data
        if uiCallbacks.updateHealth then
            uiCallbacks.updateHealth()
        end
    end
    
    -- Update UI
    UI.update(dt)
end

function love.draw()
    -- Draw game world
	currentLevel:draw()
    
    -- Draw player with camera offset
    local offsetX = love.graphics.getWidth()/2 - currentLevel.camera.x
    local offsetY = love.graphics.getHeight()/2 - currentLevel.camera.y
    player:draw(offsetX, offsetY)
    
    -- Draw UI elements (on top of game world)
    UI.draw()
end
