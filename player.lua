local Player = {}

function Player.new(x, y)
    local self = {
        x = x or 0,
        y = y or 0,
        speed = 200,
        scale = .25,
        currentState = "idle",
        animations = {},
        currentAnimation = nil
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


function Player:update(dt)
    local moving = false
    local shooting = false
    local melee = false

    -- Input handling
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
    end

    if love.keyboard.isDown("d", "right") then
        self.x = self.x + self.speed * dt
        moving = true
    end
    
    -- Combat inputs (you can change these keys)
    if love.keyboard.isDown("space") then
        shooting = true
    end

    if love.keyboard.isDown("f") then
        melee = true
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
    
    -- Keep player on screen
    self.x = math.max(0, math.min(love.graphics.getWidth(), self.x))
    self.y = math.max(0, math.min(love.graphics.getHeight(), self.y))
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


function Player:draw()
    if not self.currentAnimation then return end
    
    local currentImage = self.currentAnimation.frames[self.currentAnimation.currentFrame]
    if currentImage then
        love.graphics.draw(currentImage, self.x, self.y, 0, self.scale, self.scale, currentImage:getWidth()/2, currentImage:getHeight()/2)
    end
    
    -- Debug: Show current state
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("State: " .. self.currentState, 10, 10)
end

return Player