local UI = {
    elements = {},
    fonts = {},
    currentDialog = nil,
    isMousePressed = false,
    isMouseReleased = false,
    mouseX = 0,
    mouseY = 0
}

-- Initialize the UI system
function UI.init()
    -- Load fonts
    UI.fonts.small = love.graphics.newFont(14)
    UI.fonts.medium = love.graphics.newFont(18)
    UI.fonts.large = love.graphics.newFont(24)
    UI.fonts.title = love.graphics.newFont(36)
    
    -- Store original font for restoration
    UI.defaultFont = love.graphics.getFont()
    
    -- Setup input tracking
    love.mousepressed = function(x, y, button)
        if button == 1 then  -- Left mouse button
            UI.isMousePressed = true
            UI.mouseX = x
            UI.mouseY = y
        end
    end
    
    love.mousereleased = function(x, y, button)
        if button == 1 then  -- Left mouse button
            UI.isMouseReleased = true
            UI.mouseX = x
            UI.mouseY = y
        end
    end
end

-- Update UI elements
function UI.update(dt)
    -- Update all UI elements
    for _, element in ipairs(UI.elements) do
        if element.update then
            element:update(dt)
        end
    end
    
    -- Process clicks
    if UI.isMousePressed then
        for _, element in ipairs(UI.elements) do
            if element.checkClick and element:checkClick(UI.mouseX, UI.mouseY) then
                -- Element was clicked
            end
        end
        UI.isMousePressed = false
    end
    
    -- Process releases
    if UI.isMouseReleased then
        for _, element in ipairs(UI.elements) do
            if element.checkRelease and element:checkRelease(UI.mouseX, UI.mouseY) then
                -- Element was released
            end
        end
        UI.isMouseReleased = false
    end
    
    -- Update dialog if active
    if UI.currentDialog and UI.currentDialog.update then
        UI.currentDialog:update(dt)
    end
end

-- Draw all UI elements
function UI.draw()
    -- Draw all UI elements
    for _, element in ipairs(UI.elements) do
        if element.draw then
            element:draw()
        end
    end
    
    -- Draw dialog on top if active
    if UI.currentDialog and UI.currentDialog.draw then
        UI.currentDialog:draw()
    end
end

-- Clear all UI elements
function UI.clear()
    UI.elements = {}
end

-- Create a button
function UI.createButton(x, y, width, height, text, onClick)
    local button = {
        x = x,
        y = y,
        width = width,
        height = height,
        text = text,
        onClick = onClick,
        
        hover = false,
        pressed = false,
        
        colors = {
            normal = {0.4, 0.4, 0.4, 1.0},
            hover = {0.5, 0.5, 0.5, 1.0},
            pressed = {0.3, 0.3, 0.3, 1.0},
            text = {1, 1, 1, 1}
        }
    }
    
    button.update = function(self, dt)
        local mx, my = love.mouse.getPosition()
        self.hover = mx >= self.x and mx <= self.x + self.width and
                     my >= self.y and my <= self.y + self.height
    end
    
    button.checkClick = function(self, x, y)
        if x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height then
            self.pressed = true
            return true
        end
        return false
    end
    
    button.checkRelease = function(self, x, y)
        if self.pressed then
            self.pressed = false
            if x >= self.x and x <= self.x + self.width and
               y >= self.y and y <= self.y + self.height then
                if self.onClick then
                    self.onClick()
                end
                return true
            end
        end
        return false
    end
    
    button.draw = function(self)
        -- Choose color based on state
        local color
        if self.pressed then
            color = self.colors.pressed
        elseif self.hover then
            color = self.colors.hover
        else
            color = self.colors.normal
        end
        
        -- Draw button
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
        
        -- Draw border
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
        
        -- Draw text
        love.graphics.setColor(self.colors.text)
        love.graphics.setFont(UI.fonts.medium)
        local textWidth = UI.fonts.medium:getWidth(self.text)
        local textHeight = UI.fonts.medium:getHeight()
        local textX = self.x + (self.width - textWidth) / 2
        local textY = self.y + (self.height - textHeight) / 2
        love.graphics.print(self.text, textX, textY)
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    table.insert(UI.elements, button)
    return button
end

-- Create a panel
function UI.createPanel(x, y, width, height, backgroundColor)
    local panel = {
        x = x,
        y = y,
        width = width,
        height = height,
        backgroundColor = backgroundColor or {0.2, 0.2, 0.2, 0.8},
        borderColor = {0.5, 0.5, 0.5, 1.0},
        children = {}
    }
    
    panel.draw = function(self)
        -- Draw panel background
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
        
        -- Draw panel border
        love.graphics.setColor(self.borderColor)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
        
        -- Draw children
        for _, child in ipairs(self.children) do
            if child.draw then
                child:draw()
            end
        end
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    panel.addChild = function(self, child)
        table.insert(self.children, child)
        return child
    end
    
    table.insert(UI.elements, panel)
    return panel
end

-- Create a text element
function UI.createText(x, y, text, fontName, color)
    local textElement = {
        x = x,
        y = y,
        text = text,
        font = UI.fonts[fontName or "medium"],
        color = color or {1, 1, 1, 1}
    }
    
    textElement.draw = function(self)
        love.graphics.setFont(self.font)
        love.graphics.setColor(self.color)
        love.graphics.print(self.text, self.x, self.y)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(UI.defaultFont)
    end
    
    textElement.setText = function(self, newText)
        self.text = newText
    end
    
    table.insert(UI.elements, textElement)
    return textElement
end

-- Create a health bar
function UI.createHealthBar(x, y, width, height, currentHealth, maxHealth)
    local healthBar = {
        x = x,
        y = y,
        width = width,
        height = height,
        currentHealth = currentHealth or 100,
        maxHealth = maxHealth or 100,
        backgroundColor = {0.2, 0.2, 0.2, 0.8},
        healthColor = {0.2, 0.8, 0.2, 1.0},
        lowHealthColor = {0.8, 0.2, 0.2, 1.0},
        borderColor = {0.5, 0.5, 0.5, 1.0}
    }
    
    healthBar.draw = function(self)
        -- Draw background
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 3, 3)
        
        -- Calculate health width
        local healthWidth = (self.currentHealth / self.maxHealth) * self.width
        
        -- Choose color based on health amount
        if self.currentHealth / self.maxHealth < 0.3 then
            love.graphics.setColor(self.lowHealthColor)
        else
            love.graphics.setColor(self.healthColor)
        end
        
        -- Draw health
        love.graphics.rectangle("fill", self.x, self.y, healthWidth, self.height, 3, 3)
        
        -- Draw border
        love.graphics.setColor(self.borderColor)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 3, 3)
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    healthBar.setHealth = function(self, health)
        self.currentHealth = math.max(0, math.min(self.maxHealth, health))
    end
    
    table.insert(UI.elements, healthBar)
    return healthBar
end

-- Create a dialog box
function UI.createDialog(title, message, options)
    -- Create a modal dialog box
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local width = math.min(screenWidth * 0.8, 500)
    local height = 200
    
    local x = (screenWidth - width) / 2
    local y = (screenHeight - height) / 2
    
    local dialog = {
        title = title,
        message = message,
        options = options or {{"OK", function() UI.closeDialog() end}},
        x = x,
        y = y,
        width = width,
        height = height
    }
    
    dialog.update = function(self, dt)
        -- Handle button interactions
    end
    
    dialog.draw = function(self)
        -- Dim the background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        
        -- Draw dialog background
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
        
        -- Draw dialog border
        love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
        
        -- Draw title
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(UI.fonts.large)
        love.graphics.print(self.title, self.x + 20, self.y + 20)
        
        -- Draw message
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.printf(self.message, self.x + 20, self.y + 60, self.width - 40)
        
        -- Draw buttons
        local buttonWidth = 100
        local buttonHeight = 40
        local buttonY = self.y + self.height - 60
        local buttonSpacing = 20
        local totalButtonWidth = #self.options * buttonWidth + (#self.options - 1) * buttonSpacing
        local startX = self.x + (self.width - totalButtonWidth) / 2
        
        for i, option in ipairs(self.options) do
            local buttonX = startX + (i - 1) * (buttonWidth + buttonSpacing)
            
            -- Button background
            if UI.mouseX >= buttonX and UI.mouseX <= buttonX + buttonWidth and
               UI.mouseY >= buttonY and UI.mouseY <= buttonY + buttonHeight then
                love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
                
                if UI.isMouseReleased then
                    option[2]() -- Call the button's callback
                end
            else
                love.graphics.setColor(0.3, 0.3, 0.3, 1.0)
            end
            
            love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 5, 5)
            
            -- Button text
            love.graphics.setColor(1, 1, 1, 1)
            local textWidth = UI.fonts.medium:getWidth(option[1])
            local textHeight = UI.fonts.medium:getHeight()
            love.graphics.print(option[1], buttonX + (buttonWidth - textWidth) / 2, buttonY + (buttonHeight - textHeight) / 2)
        end
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    UI.currentDialog = dialog
    return dialog
end

-- Close the current dialog
function UI.closeDialog()
    UI.currentDialog = nil
end

-- Create an inventory slot UI element
function UI.createInventorySlot(x, y, size, item)
    local slot = {
        x = x,
        y = y,
        size = size,
        item = item,
        selected = false,
        backgroundColor = {0.3, 0.3, 0.3, 0.8},
        selectedColor = {0.5, 0.5, 0.2, 0.8},
        borderColor = {0.5, 0.5, 0.5, 1.0},
        onClick = nil
    }
    
    slot.draw = function(self)
        -- Draw background
        if self.selected then
            love.graphics.setColor(self.selectedColor)
        else
            love.graphics.setColor(self.backgroundColor)
        end
        love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)
        
        -- Draw border
        love.graphics.setColor(self.borderColor)
        love.graphics.rectangle("line", self.x, self.y, self.size, self.size)
        
        -- Draw item if present
        if self.item and self.item.image then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(self.item.image, self.x + self.size/2, self.y + self.size/2, 
                              0, 1, 1, self.item.image:getWidth()/2, self.item.image:getHeight()/2)
            
            -- If stackable, show count
            if self.item.count and self.item.count > 1 then
                love.graphics.setFont(UI.fonts.small)
                love.graphics.print(tostring(self.item.count), self.x + self.size - 15, self.y + self.size - 15)
            end
        end
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    slot.checkClick = function(self, x, y)
        if x >= self.x and x <= self.x + self.size and
           y >= self.y and y <= self.y + self.size then
            if self.onClick then
                self.onClick(self)
            end
            return true
        end
        return false
    end
    
    slot.setItem = function(self, newItem)
        self.item = newItem
    end
    
    slot.select = function(self, isSelected)
        self.selected = isSelected
    end
    
    table.insert(UI.elements, slot)
    return slot
end

-- Create a progress bar UI element
function UI.createProgressBar(x, y, width, height, progress, maxProgress, color)
    local progressBar = {
        x = x,
        y = y,
        width = width,
        height = height,
        progress = progress or 0,
        maxProgress = maxProgress or 100,
        color = color or {0.2, 0.6, 0.8, 1.0},
        backgroundColor = {0.2, 0.2, 0.2, 0.8},
        borderColor = {0.5, 0.5, 0.5, 1.0}
    }
    
    progressBar.draw = function(self)
        -- Draw background
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 3, 3)
        
        -- Calculate progress width
        local progressWidth = (self.progress / self.maxProgress) * self.width
        
        -- Draw progress
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", self.x, self.y, progressWidth, self.height, 3, 3)
        
        -- Draw border
        love.graphics.setColor(self.borderColor)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 3, 3)
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    progressBar.setProgress = function(self, newProgress)
        self.progress = math.max(0, math.min(self.maxProgress, newProgress))
    end
    
    table.insert(UI.elements, progressBar)
    return progressBar
end

return UI
