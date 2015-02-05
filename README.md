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
       world = love.physics.newWorld(0, 9.81*16, true)

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
             --(I set soft1's tesselate count to low, and the 'smoothing' to high, giving a cool effect, similar to loco roco)
        
        local mags = 50 --Magnitude of points for quick resizing
        
        local soft1_p = {
          -mags,-mags ,
           mags,-mags ,
           mags,mags  ,
          -mags,mags  ,
        }
        
        local mag = 4 -- scale these points by this number.
        
        local soft4_p = {
          -12*mag, -26*mag ,
            0*mag, -16*mag ,
           12*mag, -26*mag ,
           12*mag,  04*mag ,
          -12*mag,  04*mag ,
        }

        --polygons :
        --[[
          typeVar, points, nodeFrequency, world, x, y, r, s, t
          
          typeVar : Sets what type (circle/polygon) the softBody is to designate which constructor to use.
          
          points : the points to construct the shape from.
          
          nodeFrequency : frequency of placement of nodes along the perimiter of shape.
          
          r : radius of the center circle.
        --]]
        
       soft1 = Softbody:new("polygon", soft1_p, 16, world, 400, 400, 64, 1, 1)
       
       soft2 = Softbody:new("polygon", soft1_p, 16, world, 550, 345, 64, 1, 1)
       
       soft3 = Softbody:new("circle" ,world, 400, 250, 64, 1, 1)
       
       soft4 = Softbody:new("polygon", soft4_p, 16, world, 650, 345, 64, 12, 1)
       
       soft1:setFrequency(4)
       soft2:setFrequency(2)
       soft3:setFrequency(4)
       soft4:setFrequency(3)
       
    end

    function love.update(dt)
       world:update(dt)
       soft1:update()
       soft2:update()
       soft3:update()
       soft4:update()
    end

    function love.draw()
       love.graphics.setColor(220, 120, 200)
       --Now lets draw them
        soft1:draw()
        soft2:draw()
        soft3:draw()
        soft4:draw()
       
       love.graphics.setColor(255,255,255,255)
       
    end
```

Forum: http://love2d.org/forums/viewtopic.php?f=5&t=78882&p=174733#p174733
Video: https://www.youtube.com/watch?v=tzRvRyXI2z8
