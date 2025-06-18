local Level = {}

function Level.new(levelData)
    local self = {
        backgroundImage = nil,
        backgroundColor = nil,
        objects = {},
        width = 0,
        height = 0,
        camera = {
            x = 0,
            y = 0,
            scale = 1
        }
    }
      -- Load background if specified
    if levelData.background then
        self.backgroundImage = love.graphics.newImage("images/backgrounds/" .. levelData.background)
        self.width = levelData.width or self.backgroundImage:getWidth()
        self.height = levelData.height or self.backgroundImage:getHeight()
    elseif levelData.backgroundColor then
        -- Use solid color background
        self.backgroundColor = levelData.backgroundColor
        self.width = levelData.width or love.graphics.getWidth()
        self.height = levelData.height or love.graphics.getHeight()
    else
        -- Default level size if no background
        self.width = levelData.width or love.graphics.getWidth()
        self.height = levelData.height or love.graphics.getHeight()
    end
    
    -- Load level objects
    if levelData.objects then
        for _, objData in ipairs(levelData.objects) do
            -- Here you would instantiate different objects based on type
            -- For example: enemies, platforms, collectibles, etc.
            table.insert(self.objects, objData)
        end
    end
    
    setmetatable(self, {__index = Level})
    return self
end

function Level:update(dt, player)
    -- Center camera on player with boundaries
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Camera follows player but stays within level boundaries
    self.camera.x = math.max(screenWidth/2, math.min(self.width - screenWidth/2, player.x))
    self.camera.y = math.max(screenHeight/2, math.min(self.height - screenHeight/2, player.y))
    
    -- Update level objects
    for _, obj in ipairs(self.objects) do
        if obj.update then
            obj:update(dt)
        end
    end
end

function Level:draw()
    -- Calculate camera offset for drawing
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local offsetX = screenWidth/2 - self.camera.x
    local offsetY = screenHeight/2 - self.camera.y
    
    -- Draw background
    if self.backgroundImage then
        -- Option 1: Simple centered background
        love.graphics.draw(self.backgroundImage, offsetX, offsetY)
        
        -- Option 2: Tiled background (uncomment if needed)
        --[[
        local bgWidth = self.backgroundImage:getWidth()
        local bgHeight = self.backgroundImage:getHeight()
        for x = 0, self.width, bgWidth do
            for y = 0, self.height, bgHeight do
                love.graphics.draw(self.backgroundImage, x + offsetX, y + offsetY)
            end
        end
        --]]
    elseif self.backgroundColor then
        -- Fill screen with solid background color
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
    
    -- Draw level objects with camera offset
    for _, obj in ipairs(self.objects) do
        if obj.draw then
            obj:draw(offsetX, offsetY)
        end
    end
end

-- Function to check if a point is within the level boundaries
function Level:isInBounds(x, y)
    return x >= 0 and x <= self.width and y >= 0 and y <= self.height
end

return Level