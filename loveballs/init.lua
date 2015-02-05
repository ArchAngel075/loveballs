--Softbody lib by Shorefire/Steven
--tesselate function by Amadiro/Jonathan Ringstad
local path = ...;

require(path.."/class");

Softbody = newclass("Softbody");
function Softbody:init(typeVar, ...)
  local typeVar = typeVar or "circle"
  local args = {...}
  local points, nodeFrequency, world, x, y, r, s, t
  
  if typeVar == "circle" then
   world, x, y, r, s, t = args[1],args[2],args[3],args[4],args[5],args[6]
  elseif typeVar == "polygon" then
   points, nodeFrequency, world, x, y, r, s, t = args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8]
  end
  
	--create center body
	self.centerBody = love.physics.newBody(world, x, y, "dynamic");
	self.centerShape = love.physics.newCircleShape(r/4);
	self.centerfixture = love.physics.newFixture(self.centerBody, self.centerShape);
	self.centerfixture:setMask(1);

	--create 'nodes' (outer bodies) & connect to center body
	self.nodeShape = love.physics.newCircleShape(6);
	self.nodes = {};

	--CONSTRUCTOR
  if typeVar == "circle" then
    self:constructCircle(world,x,y,r)
  elseif typeVar == "polygon" then
    self:constructFromPoints(world,x,y,nodeFrequency,points)
  end
	--connect nodes to eachother
	for i = 1, #self.nodes do
		if i < #self.nodes then
			local j = love.physics.newDistanceJoint(self.nodes[i].body, self.nodes[i+1].body, self.nodes[i].body:getX(), self.nodes[i].body:getY(),
			self.nodes[i+1].body:getX(), self.nodes[i+1].body:getY(), false);
			self.nodes[i].joint2 = j;
		else
			local j = love.physics.newDistanceJoint(self.nodes[i].body, self.nodes[1].body, self.nodes[i].body:getX(), self.nodes[i].body:getY(),
			self.nodes[1].body:getX(), self.nodes[1].body:getY(), false);
			self.nodes[i].joint3 = j;
		end
	end

	--set tesselation and smoothing
	if s > 2 then
		s = 2;
	end
	self.smooth = s or 2;

	local tess = t or 4;
	self.tess = {};
	for i=1,tess do
		self.tess[i] = {};
	end

	self.dead = false;
end

function Softbody:constructCircle(world, x, y, r)
  local nodes = r/2;

	for node = 1, nodes do
		local angle = (2*math.pi)/nodes*node;
		
		local posx = x+r*math.cos(angle);
		local posy = y+r*math.sin(angle);

		local b = love.physics.newBody(world, posx, posy, "dynamic");
		b:setAngularDamping(50);
		
		local f = love.physics.newFixture(b, self.nodeShape);
		f:setFriction(30);
		f:setRestitution(0);
		
		local j = love.physics.newDistanceJoint(self.centerBody, b, posx, posy, posx, posy, false);
		j:setDampingRatio(0.1);
		j:setFrequency(12*(20/r));

		table.insert(self.nodes, {body = b, fixture = f, joint = j});
	end
end

function Softbody:constructFromPoints(world,px,py,nodeRadius,points)
  --[[
   construct nodes from points {...}
    Format x1,y1,x2,y2,x3,y3,...
    to cosntruct we iterate from point to point creating a node every nodeRadius units and saving them in order.
  --]]
  local nodeRadius = nodeRadius or 8 --default of 8.
  local points = points or error("no points?")

  local nodes = {}
  local pPairs = {}
  --first compile all points into a series of distance to pairs.
  for i = 1,#points,2 do
    local x = points[i]
    local y = points[i+1]
    pPairs[#pPairs+1] = {
     x=x,
     y=y,
    }
  end
  
  --now iterate between points to 
  local loop = true
  local i = 1
  while loop do
    local p1 = pPairs[i]
    local p2 = pPairs[i+1] or false
    if not p2 then loop = false ; p2 = pPairs[1] end -- last point was reached
    local dst = math.sqrt( ( p1.x - p2.x ) * ( p1.x - p2.x ) + ( p1.y - p2.y ) * ( p1.y - p2.y ) )
    
    local angle = math.atan2(p2.y-p1.y,p2.x-p1.x)
    --loop between them
    for dx = 0,dst,nodeRadius do
      nodes[#nodes+1] = {
       x =  dx*math.cos(angle)+p1.x + px ,
       y =  dx*math.sin(angle)+p1.y + py ,
      }
      --later we will add the physics, getting the points is important as is.
    end 
    i = i+1
  end
  
  ---
  local r = nodeRadius
  
  for k,v in pairs(nodes) do
    
    local posx = v.x
    local posy = v.y
    
    local b = love.physics.newBody(world, posx, posy, "dynamic")
		b:setAngularDamping(50)
		
		local f = love.physics.newFixture(b, self.nodeShape)
		f:setFriction(30)
		f:setRestitution(0)
		
		local j = love.physics.newDistanceJoint(self.centerBody, b, posx, posy, posx, posy, false)
		j:setDampingRatio(0.1)
		j:setFrequency(12*(20/r))

		table.insert(self.nodes, {body = b, fixture = f, joint = j})
  end
end

function Softbody:update()
	--update tesselation (for drawing)
	local pos = {};
	for i = 1, #self.nodes, self.smooth do
		v = self.nodes[i];

		table.insert(pos, v.body:getX());
		table.insert(pos, v.body:getY());
	end

	tessellate(pos, self.tess[1]);
	for i=1,#self.tess - 1 do
		tessellate(self.tess[i], self.tess[i+1]);
	end
end

function Softbody:destroy()
	if self.dead then
		return;
	end

	for i = #self.nodes, 1, -1 do
		self.nodes[i].body:destroy();
		self.nodes[i] = nil;
	end

	self.sourceBody:destroy();
	self.dead = true;
end

function Softbody:setFrequency(f)
	for i,v in pairs(self.nodes) do
		v.joint:setFrequency(f);
	end
end

function Softbody:setDamping(d)
	for i,v in pairs(self.nodes) do
		v.joint:setDampingRatio(d);
	end
end

function Softbody:setFriction(f)
	for i,v in ipairs(self.nodes) do
		v.fixture:setFriction(0);
	end
end

function Softbody:getPoints()
	return self.tess[#self.tess];
end

function Softbody:draw(type, debug)
	if self.dead then
		return;
	end

	love.graphics.setLineStyle("smooth");
	love.graphics.setLineWidth(self.nodeShape:getRadius()*2);

	if type == "line" then
		love.graphics.polygon("line", self.tess[#self.tess]);
	else
		love.graphics.polygon("fill", self.tess[#self.tess]);
		love.graphics.polygon("line", self.tess[#self.tess]);
	end

	love.graphics.setLineWidth(1);

	if debug then
    local colorNow = {love.graphics.getColor()}
    love.graphics.setColor(255,255,255,255)
		for i,v in ipairs(self.nodes) do
			love.graphics.circle("line", v.body:getX(), v.body:getY(), self.nodeShape:getRadius());
		end
    love.graphics.setColor(colorNow)
	end
end

--tessellate function by Amadiro/Jonathan Ringstad
function tessellate(vertices, new_vertices)
   MIX_FACTOR = .5
   new_vertices[#vertices*2] = 0
   for i=1,#vertices,2 do
      local newindex = 2*i
      -- indexing brackets:
      -- [1, *2*, 3, 4], [5, *6*, 7, 8]
      -- bracket center: 2*i
      -- bracket start: 2*1 - 1
      new_vertices[newindex - 1] = vertices[i];
      new_vertices[newindex] = vertices[i+1]
      if not (i+1 == #vertices) then
	 -- x coordinate
	 new_vertices[newindex + 1] = (vertices[i] + vertices[i+2])/2
	 -- y coordinate
	 new_vertices[newindex + 2] = (vertices[i+1] + vertices[i+3])/2
      else
	 -- x coordinate
	 new_vertices[newindex + 1] = (vertices[i] + vertices[1])/2
	 -- y coordinate
	 new_vertices[newindex + 2] = (vertices[i+1] + vertices[2])/2
      end
   end

   for i = 1,#new_vertices,4 do
      if i == 1 then
   	 -- x coordinate
   	 new_vertices[1] = MIX_FACTOR*(new_vertices[#new_vertices - 1] + new_vertices[3])/2 + (1 - MIX_FACTOR)*new_vertices[1]
   	 -- y coordinate
   	 new_vertices[2] = MIX_FACTOR*(new_vertices[#new_vertices - 0] + new_vertices[4])/2 + (1 - MIX_FACTOR)*new_vertices[2]
      else
   	 -- x coordinate
   	 new_vertices[i] = MIX_FACTOR*(new_vertices[i - 2] + new_vertices[i + 2])/2 + (1 - MIX_FACTOR)*new_vertices[i]
   	 -- y coordinate
   	 new_vertices[i + 1] = MIX_FACTOR*(new_vertices[i - 1] + new_vertices[i + 3])/2 + (1 - MIX_FACTOR)*new_vertices[i + 1]
      end
   end
end
