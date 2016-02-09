## Gesture Recognizer for Corona SDK

Gesture Recognizer for Corona SDK extends the touching functionality of the framework, giving additional options for handling touch events in regard of a ```DisplayObject```.

The tests were written using [busted] unit testing framework for Lua.

### How to use it

Require the module and create a new instance, passing the ```Runtime```:
```lua
local gestures = require("gestures").new(Runtime)
```

Given a ```DisplayObject```
```lua
local hero = makeHero()
```

Add listeners for ```touch```...:
```lua
gestures:addEventListener("touch", hero, function(event)
    local factor = 0
    if event.direction == "right" then
        factor = 1
    elseif event.direction == "left" then
        factor = -1
    end
    hero.x = hero.x + (hero:getMovementSpeed() * factor)
end)
```

...and ```swipe``` events:
```lua
gestures:addEventListener("swipe", hero, function(event)
    if event.direction == "rightUp" then
        hero:jumpRight()
    elseif event.direction == "rightDown" then
        hero:diveRight()
    elseif event.direction == "leftUp" then
        hero:jumpLeft()
    elseif event.direction == "leftDown" then
        hero:diveLeft()
    end
end)
```

### This is a work in progress. There's a lot to do, such as:

* Make it possible to fine-tune the events recognition parameters through configuration;
* Add simple ```swipeLeft``` and ```swipeRight``` events, as a complement to the existing ```swipeLeftDown```, ```swipeLeftUp```, ```swipeRightDown``` and ```swipeRightUp``` events;

### License

The code is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[busted]: http://olivinelabs.com/busted/