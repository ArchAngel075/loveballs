--Softbody lib by Shorefire/Steven
--tesselate function by Amadiro/Jonathan Ringstad

require "loveballs/class"

Sbody = newclass("Sbody");
function Sbody:init(world, x, y, r, s, tess)
	local world = world;
	self.sourceBody = love.physics.newBody(world, x, y, "dynamic");
	self.sourceShape = love.physics.newCircleShape(r/4);
	self.fixture = love.physics.newFixture(self.sourceBody, self.sourceShape);

	self.nodeShape = love.physics.newCircleShape(6);
	self.nodes = {};

	local nodes = r;

	for node = 1, nodes do
		local angle = (2*math.pi)/nodes*node;
		local posx = x+r*math.cos(angle);
		local posy = y+r*math.sin(angle);
		local b = love.physics.newBody(world, posx, posy, "dynamic");
		local f = love.physics.newFixture(b, self.nodeShape);
		f:setFriction(30);
		f:setRestitution(0);
		b:setAngularDamping(50);
		
		local j = love.physics.newDistanceJoint(self.sourceBody, b, posx, posy, posx, posy, true);
		j:setDampingRatio(0.1);
		j:setFrequency(12*(20/r));

		table.insert(self.nodes, {body = b, fixture = f, joint = j});
	end

	for i = 1, #self.nodes do
		if i < #self.nodes then
			local j = love.physics.newDistanceJoint(self.nodes[i].body, self.nodes[i+1].body, self.nodes[i].body:getX(), self.nodes[i].body:getY(),
			self.nodes[i+1].body:getX(), self.nodes[i+1].body:getY(), false);
			self.nodes[i].joint2 = j;
		end
	end

	local i = #self.nodes;
	local j = love.physics.newDistanceJoint(self.nodes[i].body, self.nodes[1].body, self.nodes[i].body:getX(), self.nodes[i].body:getY(),
	self.nodes[1].body:getX(), self.nodes[1].body:getY(), false);
	self.nodes[i].joint3 = j;

	self.tess = {};
	if not tess then tess = 2; end
	for i=1,tess do
		self.tess[i] = {};
	end

	if s then
		self.smooth = s;
	else
		if r > 25 then
			self.smooth = 6;
		else
			self.smooth = 2;
		end
	end

	self.dead = false;
end

function Sbody:destroy()
	if not self.dead then
		for i = #self.nodes, 1, -1 do
			self.nodes[i].body:destroy();
			self.nodes[i] = nil;
		end

		self.sourceBody:destroy();
		self.dead = true;
	end
end

function Sbody:setFrequency(f)
	for i,v in pairs(self.nodes) do
		v.joint:setFrequency(f);
	end
end

function Sbody:setDamping(d)
	for i,v in pairs(self.nodes) do
		v.joint:setDampingRatio(d);
	end
end

function Sbody:draw(type, width)
	if not self.dead then
		if not width then
			width = 20;
		end
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


		love.graphics.setLineStyle("smooth");
		love.graphics.setLineWidth(width);

		if type == "line" then
			love.graphics.polygon("line", self.tess[#self.tess]);
		else
			love.graphics.polygon("fill", self.tess[#self.tess]);
			love.graphics.polygon("line", self.tess[#self.tess]);
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
