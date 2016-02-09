local composer = require("composer")
local scene = composer.newScene()

local hero = {}

function scene:create(event)
    local sceneGroup = self.view
    local params = event.params

    hero = params.heroReference
    hero:setPosition(
        display.contentCenterX,
        display.contentHeight - hero.contentHeight - 30)

    local ground = display.newRect(0, display.contentHeight, display.contentWidth, 50)
    ground.anchorX = 0
    ground.anchorY = 1
    ground:setFillColor(0, 0, 0)
    physics.addBody(ground, "static", {density=9999, friction=1.0, bounce=0.0})

    local platform1 = display.newRect(200, 250, 100, 30)
    platform1:setFillColor(0, 0, 0)
    physics.addBody(platform1, "static", {density=9999, friction=1.0, bounce=0.0})

    sceneGroup:insert(hero)
    sceneGroup:insert(ground)
    sceneGroup:insert(platform1)
end

scene:addEventListener("create", scene)

return scene