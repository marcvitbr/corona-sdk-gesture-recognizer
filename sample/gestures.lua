local Gestures = {}
local Gestures_mt = { __index = Gestures }

local swipeGapAtX = 100
local swipeGapAtY = 50
local swipeTimeBetweenStartAndEnd = 500

local function dealWithBeganTouchPhase(gestures, event)
    gestures.touchStartX = event.x
    gestures.touchCurrentX = event.x

    gestures.touchStartY = event.y
    gestures.touchCurrentY = event.y

    gestures.touchStartTime = event.time
    gestures.touchTotalTime = 0

    gestures.isTouchingScreen = true
end

local function dealWithMovedTouchPhase(gestures, event)
    gestures.touchCurrentX = event.x
    gestures.touchCurrentY = event.y
end

local function iterateThroughSubscribersOf(eventKey, callback)
    local gestures = Runtime.gestures
    local moveSubscribers = gestures:getSubscribersFor(eventKey)
    local count = #moveSubscribers
    for i=1, count do
        local subscriber = moveSubscribers[i]
        callback(subscriber)
    end
end

local function fireEventWithData(eventKey, data)
    iterateThroughSubscribersOf(eventKey, function(subscriber)
        subscriber.listener(data)
    end)
end

local function swipedRight(gestures, event)
    return event.x > gestures.touchStartX + swipeGapAtX
end

local function swipedLeft(gestures, event)
    return event.x < gestures.touchStartX - swipeGapAtX
end

local function swipedRightUp(gestures, event)
    return event.x > gestures.touchStartX + swipeGapAtX
            and event.y < gestures.touchStartY - swipeGapAtY
end

local function swipedRightDown(gestures, event)
    return event.x > gestures.touchStartX + swipeGapAtX
            and event.y > gestures.touchStartY + swipeGapAtY
end

local function swipedLeftUp(gestures, event)
    return event.x < gestures.touchStartX - swipeGapAtX
            and event.y < gestures.touchStartY - swipeGapAtY
end

local function swipedLeftDown(gestures, event)
    return event.x < gestures.touchStartX - swipeGapAtX
            and event.y > gestures.touchStartY + swipeGapAtY
end

local function tookTooLongToEndSwipe(gestures)
    return gestures.touchTotalTime > swipeTimeBetweenStartAndEnd
end

local function dealWithEndedTouchPhase(gestures, event)
    gestures.isTouchingScreen = false

    gestures.touchCurrentX = event.x
    gestures.touchCurrentY = event.y
    gestures.touchTotalTime = event.time - gestures.touchStartTime

    if tookTooLongToEndSwipe(gestures) then return end

    if swipedRight(gestures, event) then
        fireEventWithData("swipe", { direction = "right" })
    end

    if swipedLeft(gestures, event) then
        fireEventWithData("swipe", { direction = "left" })
    end

    if swipedRightUp(gestures, event) then
        fireEventWithData("swipe", { direction = "rightUp" })
    end

    if swipedRightDown(gestures, event) then
        fireEventWithData("swipe", { direction = "rightDown" })
    end

    if swipedLeftUp(gestures, event) then
        fireEventWithData("swipe", { direction = "leftUp" })
    end

    if swipedLeftDown(gestures, event) then
        fireEventWithData("swipe", { direction = "leftDown" })
    end
end

function Gestures.onTouchScreen(event)
    local gestures = Runtime.gestures
    if event.phase == "began" then
        dealWithBeganTouchPhase(gestures, event)
    elseif event.phase == "moved" then
        dealWithMovedTouchPhase(gestures, event)
    elseif event.phase == "ended" then
        dealWithEndedTouchPhase(gestures, event)
    end
end

local function isTouchingRightToSubscribersObject(gestures, subscriber)
    if subscriber == nil or subscriber.object == nil then return false end
    return gestures.touchCurrentX > subscriber.object.x
end

local function isTouchingLeftToSubscribersObject(gestures, subscriber)
    if subscriber == nil or subscriber.object == nil then return false end
    return gestures.touchCurrentX < subscriber.object.x
end

function Gestures.onUpdate(event)
    local gestures = Runtime.gestures
    if gestures.isTouchingScreen then
        iterateThroughSubscribersOf("touch", function(subscriber)
            if isTouchingRightToSubscribersObject(gestures, subscriber) then
                subscriber.listener({ direction = "right" })
            elseif isTouchingLeftToSubscribersObject(gestures, subscriber) then
                subscriber.listener({ direction = "left" })
            end
        end)
    end
end

function Gestures.new(runtime)
    local gestures = {}

    gestures.subscribers = {}
    gestures.touchStartX = 0
    gestures.touchStartY = 0
    gestures.touchCurrentX = 0
    gestures.touchCurrentY = 0
    gestures.isTouchingScreen = false

    setmetatable(gestures, Gestures_mt)

    runtime.gestures = gestures
    runtime.addEventListener(runtime, "touch", Gestures.onTouchScreen)
    runtime.addEventListener(runtime, "enterFrame", Gestures.onUpdate)

    return gestures
end

function Gestures:addEventListener(eventKey, objectReference, listenerReference)
    if self.subscribers[eventKey] == nil then
        self.subscribers[eventKey] = {}
    end

    local data = {
        object = objectReference,
        listener = listenerReference
    }

    table.insert(self.subscribers[eventKey], data)
end

function Gestures:getSubscribersCountFor(eventKey)
    return self.subscribers[eventKey] and #self.subscribers[eventKey] or 0
end

function Gestures:getSubscribersFor(eventKey)
    return self.subscribers[eventKey] or {}
end

return Gestures