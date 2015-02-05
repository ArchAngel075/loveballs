loveballs

Original : https://github.com/shorefire/loveballs
=========

A simple love2d softbody lib


A quick example
```lua
      require "loveballs"

    function love.load()
       --I've found these to be optimal settings
       love.physics.setMeter(16)
       world = love.physics.newWorld(0, 16*9.8 , true)

       --Lets make floor, roof, wallLeft ,wallRight objects
       fbody = love.physics.newBody(world, love.graphics.getWidth()/2, love.graphics.getHeight()*0.95)
       fshape = love.physics.newRectangleShape(love.graphics.getWidth(), love.graphics.getHeight()*0.05)
       ffixture = love.physics.newFixture(fbody, fshape)
       
       rbody = love.physics.newBody(world, love.graphics.getWidth()/2, love.graphics.getHeight()-love.graphics.getHeight()*0.95)
       rshape = love.physics.newRectangleShape(love.graphics.getWidth(), love.graphics.getHeight()*0.05)
       rfixture = love.physics.newFixture(rbody, rshape)
       
       wlbody = love.physics.newBody(world, love.graphics.getWidth()*0.05, love.graphics.getHeight()/2)
       wlshape = love.physics.newRectangleShape(love.graphics.getWidth()*0.05, love.graphics.getHeight())
       wlfixture = love.physics.newFixture(wlbody, wlshape)
       
       wrbody = love.physics.newBody(world, love.graphics.getWidth()*0.95, love.graphics.getHeight()/2)
       wrshape = love.physics.newRectangleShape(love.graphics.getWidth()*0.05, love.graphics.getHeight())
       wrfixture = love.physics.newFixture(wrbody, wrshape)

       --Now lets make some soft body's
       --World, X, Y, Radius, Smoothing, tesselate count
      
       soft1 = Softbody:new(world, 500, 650, 64, 4, 1)
       soft2 = Softbody:new(world, 700, 650, 64, 4, 1)
       
    end

    function love.update(dt)
       world:update(dt)
       
      if love.keyboard.isDown"z" then
        soft1:setRadius(
          soft1:getRadius()+1
        )
      end
      
      if love.keyboard.isDown"x" then
        soft1:setRadius(
          soft1:getRadius()-1
        )
      end
       
       soft1:update()
       soft2:update()
    end

    function love.draw()
       love.graphics.setColor(220, 120, 200)
       --Now lets draw them
        soft1:draw()
        soft2:draw()
       love.graphics.setColor(255,255,255,255)
    end
```

Forum: http://love2d.org/forums/viewtopic.php?f=5&t=78882&p=174733#p174733
Video: https://www.youtube.com/watch?v=tzRvRyXI2z8
