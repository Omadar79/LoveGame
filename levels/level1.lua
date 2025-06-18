return {
    background = "level1_bg.png", -- This file should be in images/backgrounds/ folder
    width = 3000,                 -- Level width in pixels
    height = 1500,                -- Level height in pixels
    
    -- Static objects in the level
    objects = {
        -- Example platform
        {
            type = "platform",
            x = 500,
            y = 600,
            width = 300,
            height = 50
        },
        -- Example collectible
        {
            type = "collectible",
            x = 800,
            y = 400
        }
        -- Add more objects as needed
    },
    
    -- Level-specific properties
    properties = {
        gravity = 800,
        background_color = {0.2, 0.3, 0.8}
    }
}
