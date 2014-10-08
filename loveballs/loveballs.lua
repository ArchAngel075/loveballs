--Softbody lib by Shorefire/Steven
--tesselate function by Amadiro/Jonathan Ringstad

require "loveballs/class"

Sbody = newclass("Sbody");
function Sbody:init(world, x, y, r, s)
	local world = world;
	self.sourceBody = love.physics.newBody(world, x, y, "dynamic");
	self.source = love.physics.newCircleShape(r/4);
	self.fixture = love.physics.newFixture(self.sourceBody, self.source);

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
		
		local j = love.physics.newDistanceJoint(self.sourceBody, b, x, y, posx, posy, true);
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

	if s then
		self.smooth = s;
	else
		if r > 25 then
			self.smooth = 6;
		else
			self.smooth = 2;
		end
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

function Sbody:draw(type)
	local pos = {};
	for i = 1, #self.nodes, self.smooth do
		v = self.nodes[i];
		table.insert(pos, v.body:getX());
		table.insert(pos, v.body:getY());
	end

	for i=1,2 do
		pos = tesselate(pos);
	end

	love.graphics.setLineStyle("smooth");
	love.graphics.setLineWidth(20);

	if type == "line" then
		love.graphics.polygon("line", pos);
	else
		love.graphics.polygon("fill", pos);
		love.graphics.polygon("line", pos);
	end
end

--tesselate function by Amadiro/Jonathan Ringstad
function tesselate(vertices)
   MIX_FACTOR = .5
   new_vertices = {}
   for i=1,#vertices,2 do

      -- push original vertex
      table.insert(new_vertices, vertices[i])
      table.insert(new_vertices, vertices[i+1])

      if not (i+1 == #vertices) then
	 -- push new vertex: x'_n = (x_n + x_(n+1) / 2)
	 -- x coordinate
	 table.insert(new_vertices, (vertices[i] + vertices[i+2])/2)
	 -- y coordinate
	 table.insert(new_vertices, (vertices[i+1] + vertices[i+3])/2)
      else
	 -- x coordinate
	 table.insert(new_vertices, (vertices[i] + vertices[1])/2)
	 -- y coordinate
	 table.insert(new_vertices, (vertices[i+1] + vertices[2])/2)
      end
   end
   
   -- re-position old new_vertices
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
   return new_vertices
end
