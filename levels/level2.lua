return {
    -- Option 1: Use a background image 
    -- background = "level1_bg.png", -- This file should be in images/backgrounds/ folder
    
    -- Option 2: Use a solid color background (R,G,B,A) values from 0-1
    backgroundColor = {0.2, 0.3, 0.8, 1.0},
    
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
    }
}
