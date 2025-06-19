local Player = {}

function Player.new(x, y)    
    local self = {
        x = x or 0,
        y = y or 0,
        speed = 200,
        scale = .2,
        health = 100,
        maxHealth = 100,
        currentState = "idle",
        animations = {},
        currentAnimation = nil,
        facingDirection = 1, -- 1 for right, -1 for left
        _debugTimer = 0 -- Timer for throttling debug updates
    }

     -- Load all animation types
    self.animations = {
        idle = Player.loadAnimation("idle", 10), -- Adjust frame count
        walk = Player.loadAnimation("walk", 10),
        shoot = Player.loadAnimation("shoot",10),
        walk_shoot = Player.loadAnimation("walk_shoot", 10),
        melee = Player.loadAnimation("melee", 10)
    }
    
    -- Set initial animation
    self.currentAnimation = self.animations[self.currentState]
    
    setmetatable(self, {__index = Player})
    return self
end

function Player.loadAnimation(animName, frameCount)
    local animation = {
        frames = {},
        currentFrame = 1,
        timer = 0,
        frameTime = 0.1,
        loop = true
    }
    
    -- Load frames for this animation
    for i = 1, frameCount  do
        local imagePath = "images/trooper/" .. animName .. "__" .. i .. ".png"
        local frame = love.graphics.newImage(imagePath)
        table.insert(animation.frames, frame)

    end
    
    
    -- Special cases for non-looping animations
    if animName == "melee" or animName == "shoot" then
        animation.loop = false
        animation.frameTime = 0.08 -- Faster for action animations
    end
    
    return animation
end

function Player:setState(newState)
    if self.currentState ~= newState and self.animations[newState] then
        self.currentState = newState
        self.currentAnimation = self.animations[newState]
        self.currentAnimation.currentFrame = 1
        self.currentAnimation.timer = 0

    end

end


function Player:update(dt, level, input)
    local moving = false
    local shooting = false
    local melee = false

    -- Try to get our input module
    local Input = input or package.loaded["input"]
    
    -- Input handling
    if Input then
        -- Get movement vector from input module
        local dx, dy = Input.getMovementVector()
        
        if dx ~= 0 or dy ~= 0 then
            self.x = self.x + dx * self.speed * dt
            self.y = self.y + dy * self.speed * dt
            moving = true
            
            -- Update facing direction based on horizontal movement
            if dx ~= 0 then
                self.facingDirection = (dx > 0) and 1 or -1 -- 1 for right, -1 for left
            end
        end
        
        -- Combat inputs using Input
        if Input.isDown("jump") then
            shooting = true
        end
        
        if Input.isDown("attack") then
            melee = true
        end
    else
        -- Legacy input handling if Input not provided
        if love.keyboard.isDown("w", "up") then
            self.y = self.y - self.speed * dt
            moving = true
        end

        if love.keyboard.isDown("s", "down") then
            self.y = self.y + self.speed * dt
            moving = true
        end
        
        if love.keyboard.isDown("a", "left") then
            self.x = self.x - self.speed * dt
            moving = true
            self.facingDirection = -1 -- Facing left
        end

        if love.keyboard.isDown("d", "right") then
            self.x = self.x + self.speed * dt
            moving = true
            self.facingDirection = 1 -- Facing right
        end
        
        -- Combat inputs (you can change these keys)
        if love.keyboard.isDown("space") then
            shooting = true
        end

        if love.keyboard.isDown("f") then
            melee = true
        end
    end
    
    -- Determine animation state based on actions
    local newState = "idle"
    if melee then
        newState = "melee"
    elseif moving and shooting then
        newState = "walk_shoot"
    elseif shooting then
        newState = "shoot"
    elseif moving then
        newState = "walk"
    end
    
    self:setState(newState)
      -- Update current animation
    self:updateAnimation(dt)
    
    
    if level then
        -- Keep player within level boundaries
        self.x = math.max(0, math.min(level.width, self.x))
        self.y = math.max(0, math.min(level.height, self.y))
    else
        -- Existing screen boundary code
        self.x = math.max(0, math.min(love.graphics.getWidth(), self.x))
        self.y = math.max(0, math.min(love.graphics.getHeight(), self.y))
    end
    
    -- Update debug info in Console
    -- We only do this occasionally to prevent console spam
    if self._debugTimer and self._debugTimer > 0 then
        self._debugTimer = self._debugTimer - dt
    else        self._debugTimer = 0.5  -- Update debug info every half second
          -- Get the debug console module
        local DebugConsole = require("lib.debug_console")
        
        -- Update debug values using the variable registration system
        DebugConsole.updateVariable("playerState", self.currentState)
        DebugConsole.updateVariable("playerFacing", (self.facingDirection == 1 and "Right" or "Left"))
        DebugConsole.updateVariable("playerPosition", {x = math.floor(self.x), y = math.floor(self.y)})
    end
end


function Player:updateAnimation(dt)
    if not self.currentAnimation then 
        return 
    end
    
    self.currentAnimation.timer = self.currentAnimation.timer + dt
    
    if self.currentAnimation.timer >= self.currentAnimation.frameTime then
        self.currentAnimation.timer = 0
        self.currentAnimation.currentFrame = self.currentAnimation.currentFrame + 1
        
        -- Handle animation end
        if self.currentAnimation.currentFrame > #self.currentAnimation.frames then
            if self.currentAnimation.loop then
                self.currentAnimation.currentFrame = 1
            else
                -- Non-looping animation finished, return to appropriate state
                self.currentAnimation.currentFrame = #self.currentAnimation.frames
                if self.currentState == "melee" or self.currentState == "shoot" then
                    self:setState("idle") -- Return to idle after action
                end

            end

        end

    end
end


function Player:draw(offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    if not self.currentAnimation then
         return 
    end
    
    local currentImage = self.currentAnimation.frames[self.currentAnimation.currentFrame]
    if currentImage then
        -- Calculate scale with direction (negative scale flips the image)
        local scaleX = self.scale * self.facingDirection
        local scaleY = self.scale
        
        love.graphics.draw(currentImage, self.x + offsetX, self.y + offsetY, 0, scaleX, scaleY, currentImage:getWidth()/2, currentImage:getHeight()/2)
    end
      -- Debug info is now handled by the Console module
end

return Player