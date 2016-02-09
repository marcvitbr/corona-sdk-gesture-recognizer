local Hero = {}

local jumpXForce = 5
local jumpYForce = -10
local dashXForce = 10

function Hero.new(displayHandler, physicsHandler)
    local hero = displayHandler.newRect(0, 0, 30, 30)

    hero.physicsHandler = physicsHandler

    function hero:prepareForPhysics()
        local physicsHandler = self.physicsHandler

        if not physicsHandler then return end

        physicsHandler.addBody(self, {density=1.0, friction=1.0, bounce=0.0})

        self.isFixedRotation = true

        self.collision = function(selfOnCollision, event)
            if event.phase == "began" then
                if event.other.type == "ground" then
                    selfOnCollision.isOnTheGround = true
                end
            end
        end

        self:addEventListener("collision", self)
    end

    function hero:setPosition(x, y)
        self.x = x
        self.y = y
    end

    function hero:setMovementSpeed(speed)
        self.movement_speed = speed
    end

    function hero:getMovementSpeed()
        return self.movement_speed
    end

    function hero:jumpRight()
        self:applyLinearImpulse(jumpXForce, jumpYForce, self.x, self.y)
    end

    function hero:diveRight()
    end

    function hero:jumpLeft()
        self:applyLinearImpulse(jumpXForce*-1, jumpYForce, self.x, self.y)
    end

    function hero:diveLeft()
    end

    function hero:dashRight()
        self:applyLinearImpulse(dashXForce, 1, self.x, self.y)
    end

    function hero:dashLeft()
        self:applyLinearImpulse(dashXForce*-1, 1, self.x, self.y)
    end

    return hero
end

return Hero
