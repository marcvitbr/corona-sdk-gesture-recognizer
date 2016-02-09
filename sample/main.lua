display.setDefault("background", 1,1,1)
display.setDefault("fillColor", 0,0,0)
display.setStatusBar(display.HiddenStatusBar)

local physics = require("physics")
physics.start()
physics.setDrawMode("hybrid")

local hero = require("hero").new(display, physics)
hero:prepareForPhysics()
hero:setMovementSpeed(10)

local gestures = require("gestures").new(Runtime)

gestures:addEventListener("touch", hero, function(event)
    local factor = 0

    if event.direction == "right" then
        factor = 1
    elseif event.direction == "left" then
        factor = -1
    end

    hero.x = hero.x + (hero:getMovementSpeed() * factor)
end)

gestures:addEventListener("swipe", hero, function(event)
    if event.direction == "rightUp" then
        hero:jumpRight()
    elseif event.direction == "rightDown" then
        hero:diveRight()
    elseif event.direction == "leftUp" then
        hero:jumpLeft()
    elseif event.direction == "leftDown" then
        hero:diveLeft()
    elseif event.direction == "right" then
        hero:dashRight()
    elseif event.direction == "left" then
        hero:dashLeft()
    end
end)

local composer = require("composer")
composer.gotoScene(
    "stage_1",
    {
        params =
        {
            heroReference = hero
        }
    })
