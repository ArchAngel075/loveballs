--Softbody lib by Shorefire/Steven
--tesselate function by Amadiro/Jonathan Ringstad
local path = ...;

require(path.."/class");

Softbody = newclass("Softbody");
function Softbody:init(world, x, y, r, s, t)
	--create center body
  self.world = world
	self.centerBody = love.physics.newBody(world, x, y, "dynamic");
	self.centerShape = love.physics.newCircleShape(r/4);
	self.centerfixture = love.physics.newFixture(self.centerBody, self.centerShape);
	self.centerfixture:setMask(1);
  
  --create 'nodes'
  self:constructNodes(x, y, r)
  
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

function Softbody:constructNodes(x, y, r)
  --create 'nodes' (outer bodies) & connect to center body
  local world = self.world
	self.nodeShape = love.physics.newCircleShape(8);
	self.nodes = {};

	local nodes = r/2;

	for node = 1, nodes do
		local angle = (2*math.pi)/nodes*node;
		
		local posx = x+r*math.cos(angle);
		local posy = y+r*math.sin(angle);
    posx, posy = self:rayCastNode(posx,posy,r,angle)

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
end

function Softbody:rayCastNode(nodeX,nodeY,r,angle)
  --takes nodeX,nodeY and casts from center sourceBody
  --returns the first/closest contact
  
  local center = {self.centerBody:getPosition()}
  local px,py = nodeX, nodeY
  local rayCast_array = {}
  
  local loop = true
  local hitList = {}
  
  local function worldRayCastCallback(fixture, x, y, xn, yn, fraction)
    local hit = {}
    
    if fixture == self.centerfixture then return 1 end --special case
    local case2
    for i,o in pairs(self.nodes) do
      if fixture == o.fixture then
        case2 = true
        break
      end
    end
    if case2 then return 1 end
    
    hit.fixture = fixture
    hit.x, hit.y = x, y
    hit.xn, hit.yn = xn, yn
    hit.fraction = fraction

    table.insert(hitList, hit)

    return 1 -- Continues with ray cast through all shapes.
  end
  
  --center[1], center[2], nodeX, nodeY
  
  if math.sqrt( ( center[1] - nodeX ) * ( center[1] - nodeX ) + ( center[2] - nodeY ) * ( center[2] - nodeY ) ) <= 0.0 then
    return px,py
  end
  
  self.world:rayCast( center[1], center[2], nodeX, nodeY, worldRayCastCallback)
  
  if #hitList > 0 then
    --get closest fixture
    local closest = nil
    local closestDX = nil
    for k,v in pairs(hitList) do
      if not closest then
        closestDX = math.sqrt( ( center[1] - nodeX ) * ( center[1] - nodeX ) + ( center[2] - nodeY ) * ( center[2] - nodeY ) )
        closest = k
      else
        local dx = math.sqrt( ( center[1] - v.x ) * ( center[1] - v.x ) + ( center[2] - v.y ) * ( center[2] - v.y ) )
        if dx < closestDX then
          closestDX = dx
          closest = k
        end
      end
    end
    --print(hitList[closest])
    px,py = hitList[closest].x,hitList[closest].y
  end
  return px,py
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

function Softbody:getRadius()
  return self.centerShape:getRadius()*4
end

function Softbody:setRadius(r)
  if self.dead then
		return;
	end
  
	for i = #self.nodes, 1, -1 do
		self.nodes[i].body:destroy();
		self.nodes[i] = nil;
	end
  
  self.centerShape:setRadius(r/4)
  
  self:constructNodes(self.centerBody:getX(), self.centerBody:getY(), r)
  
  local tess = t or 4;
	self.tess = {};
	for i=1,tess do
		self.tess[i] = {};
	end
  
  self:update()
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
		for i,v in ipairs(self.nodes) do
			love.graphics.circle("line", v.body:getX(), v.body:getY(), self.nodeShape:getRadius());
		end
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
