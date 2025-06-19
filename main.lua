local Player = require("player")
local Level = require("level")
local UI = require("ui")
local GameUI = require("game_ui")
local DebugConsole = require("lib.debug_console")
local Input = require("input")

-- Game state variables
local gameState = "menu"  -- Can be "menu", "playing", "paused"
local uiCallbacks = {}

function love.load()
    -- Initialize player as nil (will be created when game starts)
    player = nil

	-- Load level (either directly or from a file)
    currentLevel = Level.new(require("levels/level2"))
    
    -- Initialize UI system
    UI.init()
    
    -- Initialize debug console and register variables
    DebugConsole.init()
    DebugConsole.registerVariable("playerPosition", {x=0, y=0})
    DebugConsole.registerVariable("gameState", gameState)
    
    -- Initialize our input system with the game state and pass the main module (_G)
    -- This allows the Input module to access key functions like startGame and resumeGame
    Input.init(gameState, nil, _G)

    -- Load main menu UI
    GameUI.initMainMenu(function()
        startGame()
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
				-- Handle events based on type
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				elseif name == "keypressed" then
					-- Let the input system handle this - it will properly route to DebugConsole if visible
					Input.handleKeyPressed(a, b, c)
				elseif name == "keyreleased" then
					-- Let the input system handle this - it will properly route to DebugConsole if visible
					Input.handleKeyReleased(a, b)
				elseif name == "mousepressed" then
					-- Let input system handle mouse events - it will check DebugConsole.visible internally
					if not Input.handleMousePressed(a, b, c, d, e) then
						-- If not handled and we have a default handler, use it
						if love.mousepressed then
							love.mousepressed(a, b, c, d, e)
						end
					end
				elseif name == "mousereleased" then
					-- Let input system handle mouse events - it will check DebugConsole.visible internally
					if not Input.handleMouseReleased(a, b, c, d, e) then
						-- If not handled and we have a default handler, use it
						if love.mousereleased then
							love.mousereleased(a, b, c, d, e)
						end
					end
				elseif name == "mousemoved" then
					-- Pass to input system
					Input.handleMouseMoved(a, b, c, d, e)
				elseif name == "wheelmoved" then
					-- Pass to input system
					Input.handleWheelMoved(a, b)
				else
					-- Use default handler for other events
					if love.handlers[name] then
						love.handlers[name](a, b, c, d, e, f)
					end
				end
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
    -- Update input system
    Input.update(dt)
    
    -- Only update game elements if playing and player exists
    if gameState == "playing" and player then
        player:update(dt, currentLevel, InputHandler)
        currentLevel:update(dt, player)
        
        -- Update UI with player data
        if uiCallbacks.updateHealth then
            uiCallbacks.updateHealth()
        end
    end
    
    -- Update UI
    UI.update(dt)
    
    -- Update debug console and variables
    DebugConsole.update(dt)
    if player then
        DebugConsole.updateVariable("playerPosition", {x = math.floor(player.x), y = math.floor(player.y)})
    end
    DebugConsole.updateVariable("gameState", gameState)
end

function love.draw()
    -- Draw game world
	currentLevel:draw()
    
    -- Draw player only when game is playing
    if gameState == "playing" then
        local offsetX = love.graphics.getWidth()/2 - currentLevel.camera.x
        local offsetY = love.graphics.getHeight()/2 - currentLevel.camera.y
        player:draw(offsetX, offsetY)
    end
    
    -- Draw UI elements (on top of game world)
    UI.draw()
    
    -- Draw debug console (on top of everything)
    DebugConsole.draw()
end

-- Override love.textinput to route through our input handler or debug console
function love.textinput(text)
    if DebugConsole.visible then
        DebugConsole.textinput(text)
    end
end

-- Add direct mouse handlers for debug console
function love.mousepressed(x, y, button, isTouch, presses)
    if DebugConsole.visible then
        -- Debug console could handle mouse events here
        return true
    end
end

function love.mousereleased(x, y, button, isTouch, presses)
    if DebugConsole.visible then
        -- Debug console could handle mouse events here
        return true
    end
end

function love.wheelmoved(x, y)
    if DebugConsole.visible then
        -- Let debug console handle wheel movement for scrolling
        return DebugConsole.wheelmoved(x, y)
    end
end

-- Function to start the game - centralizes game start logic
function startGame()
    -- Create player when game starts
    player = Player.new(400, 300)
    
    -- Start game callback
    gameState = "playing"
    Input.setGameState(gameState)
    UI.clear()
    uiCallbacks = GameUI.initGameUI(player)
end

-- Function to resume the game from pause
function resumeGame()
    gameState = "playing"
    Input.setGameState(gameState)
    UI.clear()
    uiCallbacks = GameUI.initGameUI(player)
end
