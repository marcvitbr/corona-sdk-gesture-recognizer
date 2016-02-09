package.path = package.path .. ";../?.lua"

describe("When testing the gestures module", function()
    local runtime
    local gesturesModule
    local gestures
    local oneSecond = 1
    local wasSwipeRightUpEventFired = false
    local someObject = { x = 10, y = 14 }

    local clock = os.clock
    local sleepFor = function(n)
      local t0 = clock()
      while clock() - t0 <= n do end
    end

    setup(function()
        runtime = mock(require("mock.runtime"))

        gesturesModule = require("src.gestures")
        gestures = gesturesModule.new(runtime)

        _G.Runtime = {}
        _G.Runtime.gestures = gestures
    end)

    teardown(function()
        runtime = nil
        gestures = nil
        gesturesModule = nil
    end)

    it("Should add a global touch event listener, when created", function()
        assert.spy(runtime.addEventListener).was_called_with(runtime, "touch", gesturesModule.onTouchScreen)
    end)

    it("Should add a global frame update event listener, when created", function()
        assert.spy(runtime.addEventListener).was_called_with(runtime, "enterFrame", gesturesModule.onUpdate)
    end)

    it("Should initialize touching control variables, when created", function()
        assert.are.equal(0, gestures.touchStartX)
        assert.are.equal(0, gestures.touchStartY)
        assert.are.equal(0, gestures.touchCurrentX)
        assert.are.equal(0, gestures.touchCurrentY)
        assert.are.equal(false, gestures.isTouchingScreen)
    end)

    it("Should create an empty table for gesture subscribers", function()
        assert.is_not_true(gestures.subscribers == nil)
    end)

    it("Should insert a function into subscribers table when calling addEventListener with 'move' event key", function()
        gestures:addEventListener("move", someObject, function(event) end)
        assert.are.equal(1, gestures:getSubscribersCountFor("move"))
    end)

    it("Should return 0 when calling getSubscribersCountFor with non-existing key", function()
        assert.are.equal(0, gestures:getSubscribersCountFor("SOME_KEY"))
    end)

    it("Should return empty table when calling getSubscribersFor with non-existing key", function()
        local emptySubscribers = gestures:getSubscribersFor("SOME_KEY")
        assert.is_not_true(emptySubscribers == nil)
        assert.are.equal(0, #emptySubscribers)
    end)

    it("Should return a table with subscribers of an event when calling getSubscribersFor", function()
        local subscribers = gestures:getSubscribersFor("move")
        assert.are.equal(1, gestures:getSubscribersCountFor("move"))
    end)

    it("Should handle the 'began' phase of a touch event", function()
        local event = { phase = "began", time = 1, x = 10, y = 15 }

        gestures.onTouchScreen(event)

        assert.is_true(gestures.isTouchingScreen)
        assert.are.equal(event.x, gestures.touchStartX)
        assert.are.equal(event.x, gestures.touchCurrentX)
        assert.are.equal(event.y, gestures.touchStartY)
        assert.are.equal(event.y, gestures.touchCurrentY)
        assert.are.equal(event.time, gestures.touchStartTime)
        assert.are.equal(0, gestures.touchTotalTime)
    end)

    it("Should handle the 'moved' phase of a touch event", function()
        local event = { phase = "moved", x = 13, y = 18 }

        gestures.onTouchScreen(event)

        assert.are.equal(event.x, gestures.touchCurrentX)
        assert.are.equal(event.y, gestures.touchCurrentY)
    end)

    it("Should handle the 'ended' phase of a touch event", function()
        local event = { phase = "ended", time = 10, x = 55, y = 66 }

        gestures.onTouchScreen(event)

        assert.is_not_true(gestures.isTouchingScreen)

        local deltaTimeBetweenEndAndStartTouchTimes = 9
        assert.are.equal(deltaTimeBetweenEndAndStartTouchTimes, gestures.touchTotalTime)
    end)

    it("Should fire the 'touch' event, with direction 'right'", function()
        local wasTouchRightEventFired = false

        gestures:addEventListener("touch", someObject,
            function(event)
                if event.direction == "right" then
                    wasTouchRightEventFired = true
                end
            end)

        gestures.onTouchScreen({ time=1, phase="began", x=someObject.x + 100, y=100 })

        gestures.onUpdate()

        assert.is_true(wasTouchRightEventFired)
    end)

    it("Should fire the 'touch' event, with direction 'left'", function()
        local wasTouchLeftEventFired = false

        gestures:addEventListener("touch", someObject,
            function(event)
                if event.direction == "left" then
                    wasTouchLeftEventFired = true
                end
            end)

        gestures.onTouchScreen({ time=1, phase="began", x=someObject.x - 100, y=100 })

        gestures.onUpdate()

        assert.is_true(wasTouchLeftEventFired)
    end)

    it("Should NOT fire the 'swipe' event, when it takes more than 500ms to complete", function()
        gestures:addEventListener("swipe", someObject,
            function(event)
                if event.direction == "rightUp" then
                    wasSwipeRightUpEventFired = true
                end
            end)

        wasSwipeRightUpEventFired = false

        gestures.onTouchScreen({ time=1, phase = "began", x = 100, y = 100 })
        gestures.onTouchScreen({ time=200, phase = "moved", x = 200, y = 80 })
        gestures.onTouchScreen({ time=400, phase = "moved", x = 300, y = 40 })

        local longTimeThatInvalidatesSwipeEvent = 800
        gestures.onTouchScreen({ time = longTimeThatInvalidatesSwipeEvent, phase = "ended", x = 400, y = 10 })

        sleepFor(oneSecond)

        assert.is_not_true(wasSwipeRightUpEventFired)
    end)

    it("Should NOT fire the 'swipe' event, with direction 'right', if the gesture is too short", function()
        local wasSwipeRightEventFired = false

        gestures:addEventListener("swipe", someObject,
            function(event)
                if event.direction == "right" then
                    wasSwipeRightEventFired = true
                end
            end)

        local constantTouchY = 100

        gestures.onTouchScreen({ time=1, phase = "began", x = 100, y = constantTouchY })
        gestures.onTouchScreen({ time=100, phase = "moved", x = 120, y = constantTouchY })
        gestures.onTouchScreen({ time=250, phase = "moved", x = 140, y = constantTouchY })
        gestures.onTouchScreen({ time=400, phase = "ended", x = 160, y = constantTouchY })

        assert.is_not_true(wasSwipeRightEventFired)
    end)

    it("Should fire the 'swipe' event, with direction 'right'", function()
        local wasSwipeRightEventFired = false

        gestures:addEventListener("swipe", someObject,
            function(event)
                if event.direction == "right" then
                    wasSwipeRightEventFired = true
                end
            end)

        local constantTouchY = 100

        gestures.onTouchScreen({ time=1, phase = "began", x = 100, y = constantTouchY })
        gestures.onTouchScreen({ time=100, phase = "moved", x = 200, y = constantTouchY })
        gestures.onTouchScreen({ time=250, phase = "moved", x = 300, y = constantTouchY })
        gestures.onTouchScreen({ time=400, phase = "ended", x = 400, y = constantTouchY })

        assert.is_true(wasSwipeRightEventFired)
    end)

    it("Should NOT fire the 'swipe' event, with direction 'left', if the gesture is too short", function()
        local wasSwipeLeftEventFired = false

        gestures:addEventListener("swipe", someObject,
            function(event)
                if event.direction == "left" then
                    wasSwipeLeftEventFired = true
                end
            end)

        local constantTouchY = 100

        gestures.onTouchScreen({ time=1, phase = "began", x = 160, y = constantTouchY })
        gestures.onTouchScreen({ time=100, phase = "moved", x = 140, y = constantTouchY })
        gestures.onTouchScreen({ time=250, phase = "moved", x = 120, y = constantTouchY })
        gestures.onTouchScreen({ time=400, phase = "ended", x = 100, y = constantTouchY })

        assert.is_not_true(wasSwipeLeftEventFired)
    end)

    it("Should fire the 'swipe' event, with direction 'left'", function()
        local wasSwipeLeftEventFired = false

        gestures:addEventListener("swipe", someObject,
            function(event)
                if event.direction == "left" then
                    wasSwipeLeftEventFired = true
                end
            end)

        local constantTouchY = 100

        gestures.onTouchScreen({ time=1, phase = "began", x = 400, y = constantTouchY })
        gestures.onTouchScreen({ time=100, phase = "moved", x = 300, y = constantTouchY })
        gestures.onTouchScreen({ time=250, phase = "moved", x = 200, y = constantTouchY })
        gestures.onTouchScreen({ time=400, phase = "ended", x = 100, y = constantTouchY })

        assert.is_true(wasSwipeLeftEventFired)
    end)

    it("Should fire the 'swipe' event, with direction 'rightUp'", function()
        gestures.onTouchScreen({ time = 1, phase = "began", x = 100, y = 100 })
        gestures.onTouchScreen({ time = 100, phase = "moved", x = 200, y = 80 })
        gestures.onTouchScreen({ time = 300, phase = "moved", x = 300, y = 40 })

        local enoughTimeToValidateSwipeEvent = 500
        gestures.onTouchScreen({ time=enoughTimeToValidateSwipeEvent, phase = "ended", x = 400, y = 10 })

        sleepFor(oneSecond)

        assert.is_true(wasSwipeRightUpEventFired)
    end)

    it("Should fire the 'swipe' event, with direction 'rightDown'", function()
        local wasSwipeRightDownEventFired = false

        gestures:addEventListener("swipe", someObject,
            function(event)
                if event.direction == "rightDown" then
                    wasSwipeRightDownEventFired = true
                end
            end)

        gestures.onTouchScreen({ time = 1, phase = "began", x = 100, y = 100 })
        gestures.onTouchScreen({ time = 100, phase = "moved", x = 200, y = 120 })
        gestures.onTouchScreen({ time = 200, phase = "moved", x = 300, y = 140 })
        gestures.onTouchScreen({ time = 300, phase = "ended", x = 400, y = 190 })

        sleepFor(oneSecond)

        assert.is_true(wasSwipeRightDownEventFired)
    end)

    it("Should fire the 'swipe' event, with direction 'leftUp'", function()
        local wasSwipeLeftUpEventFired = false

        local someObject = { x = 10, y = 14 }

        gestures:addEventListener("swipe", someObject,
            function(event)
                if event.direction == "leftUp" then
                    wasSwipeLeftUpEventFired = true
                end
            end)

        gestures.onTouchScreen({ time = 1, phase = "began", x = 400, y = 100 })
        gestures.onTouchScreen({ time = 100, phase = "moved", x = 300, y = 80 })
        gestures.onTouchScreen({ time = 200, phase = "moved", x = 200, y = 60 })
        gestures.onTouchScreen({ time = 300, phase = "ended", x = 100, y = 20 })

        sleepFor(oneSecond)

        assert.is_true(wasSwipeLeftUpEventFired)
    end)

    it("Should fire the 'swipe' event, with direction 'leftDown'", function()
        local wasSwipeLeftDownEventFired = false

        local someObject = { x = 10, y = 14 }

        gestures:addEventListener("swipe", someObject,
            function(event)
                if event.direction == "leftDown" then
                    wasSwipeLeftDownEventFired = true
                end
            end)

        gestures.onTouchScreen({ time = 1, phase = "began", x = 400, y = 20 })
        gestures.onTouchScreen({ time = 100, phase = "moved", x = 300, y = 40 })
        gestures.onTouchScreen({ time = 200, phase = "moved", x = 200, y = 60 })
        gestures.onTouchScreen({ time = 300, phase = "ended", x = 100, y = 100 })

        sleepFor(oneSecond)

        assert.is_true(wasSwipeLeftDownEventFired)
    end)
end)
