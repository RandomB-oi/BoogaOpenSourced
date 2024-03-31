local Rectangle = {}
Rectangle.__index = Rectangle

local Class = require(script.Parent.Parent.Class)

local IsDebug = false

Rectangle.new = function(x,y, w,h, minHeight, maxHeight)
	local self = setmetatable({}, Rectangle)

	self.X = x
	self.Y = y
	self.W = w
	self.H = h

	self.MinHeight = minHeight
	self.MaxHeight = maxHeight

	if IsDebug then
		self.DebugPart = Instance.new("Part")
		self.DebugPart.Anchored = true
		self.DebugPart.Size = Vector3.new(w, 4, h) - Vector3.new(1, 0, 1)
		self.DebugPart.Position = Vector3.new(x, 0, y)
		self.DebugPart.CanCollide = false
		self.DebugPart.CanTouch = false
		self.DebugPart.CanQuery = false
		self.DebugPart.Transparency = 0.9
		self.DebugPart.Color = Color3.new(0, 1, 0)
		self.DebugPart.Material = Enum.Material.Neon
		self.DebugPart.Parent = workspace

		--local att = Instance.new("Attachment", self.DebugPart)
		--self.DebugAttachment = att
	end

	return self
end

function Rectangle:WithinBounds(model : PVInstance)
	local point = model:GetPivot().Position
	if self.MaxHeight and point.Y >= self.MaxHeight then return false end
	if self.MinHeight and point.Y <= self.MinHeight then return false end

	return 
		point.X >= self.X - self.W/2 and point.Z >= self.Y - self.H/2 and 
		point.X <  self.X + self.W/2 and point.Z <  self.Y + self.H/2
end

function Rectangle:Intersects(range)
	return not (
		range.X - range.W/2 > self.X + self.W/2 or 
			range.X + self.W/2 < self.X - self.W/2 or 
			range.Y - range.H/2 > self.Y + self.H/2 or 
			range.Y + self.H/2 < self.Y - self.H/2
	)
end

function Rectangle:Destroy()
	if self.DebugPart then
		self.DebugPart:Destroy()
	end
	if self.DebugAttachment then
		self.DebugAttachment:Destroy()
	end
end

local QuadTree = {}
QuadTree.__index = QuadTree

QuadTree.QuadTrees = {} -- must be manually defined

QuadTree.new = function(boundary, minCellCapacity : number, maxDepth : number, depth : number)
	local self = setmetatable({}, QuadTree)
	self.Boundary = boundary
	self.MinCellCapacity = minCellCapacity
	self.Models = {}
	self.ModelCount = 0
	self.Divided = false

	self.MaxDepth = maxDepth
	self.Depth = depth or 0

	return self
end

function QuadTree:Subdivide()
	local boundary = self.Boundary

	self.Divided = true
	self.NE = QuadTree.new(Rectangle.new(boundary.X - boundary.W/4, boundary.Y - boundary.H/4, boundary.W/2, boundary.H/2, boundary.MinHeight, boundary.MaxHeight), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	self.NW = QuadTree.new(Rectangle.new(boundary.X + boundary.W/4, boundary.Y - boundary.H/4, boundary.W/2, boundary.H/2, boundary.MinHeight, boundary.MaxHeight), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	self.SE = QuadTree.new(Rectangle.new(boundary.X - boundary.W/4, boundary.Y + boundary.H/4, boundary.W/2, boundary.H/2, boundary.MinHeight, boundary.MaxHeight), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	self.SW = QuadTree.new(Rectangle.new(boundary.X + boundary.W/4, boundary.Y + boundary.H/4, boundary.W/2, boundary.H/2, boundary.MinHeight, boundary.MaxHeight), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	
	for model in self.Models do
		self.NE:Insert(model)
		self.NW:Insert(model)
		self.SE:Insert(model)
		self.SW:Insert(model)
	end
end

function QuadTree:Update()
	if self.ModelCount <= self.MinCellCapacity then
		if self.Divided then
			self.Divided = false
			self.NE.Boundary:Destroy()
			self.NE = nil
			self.NW.Boundary:Destroy()
			self.NW = nil
			self.SE.Boundary:Destroy()
			self.SE = nil
			self.SW.Boundary:Destroy()
			self.SW = nil
		end
	end
end

function QuadTree:QueryBox(range, isValidCallback, found)
	local found = found or {}
	if not self.Boundary:Intersects(range) then
		return found
	end

	for model in self.Models do
		if not self:SubTreesContain(model) and range:WithinBounds(model) then
			if not (isValidCallback and isValidCallback(model) or not isValidCallback) then continue end
			table.insert(found, model)
		end
	end

	if self.Divided then
		self.NW:QueryBox(range, isValidCallback, found)
		self.NE:QueryBox(range, isValidCallback, found)
		self.SW:QueryBox(range, isValidCallback, found)
		self.SE:QueryBox(range, isValidCallback, found)
	end

	return found
end

function QuadTree:SubTreesContain(model : PVInstance)
	if self.Divided then
		return not not (self.NE.Models[model] or self.NW.Models[model] or self.SE.Models[model] or self.SW.Models[model])
	end
end

function QuadTree:Insert(model : PVInstance)
	if not self.Boundary:WithinBounds(model) then
		return false
	end

	self.Models[model] = true
	self.ModelCount += 1

	--if IsDebug then
	--	local beam = Instance.new("Beam", model.PrimaryPart)
	--	beam.Name = "QUADTREEBEAM"
	--	beam.FaceCamera = true
	--	beam.Attachment0 = self.Boundary.DebugAttachment
	--	local att = Instance.new("Attachment", model.PrimaryPart)
	--	att.Name = "QUADTREEATT"
	--	beam.Attachment1 = att
	--end

	if self.ModelCount > self.MinCellCapacity and self.Depth < self.MaxDepth then
		if not self.Divided then
			self:Subdivide()
		end

		if self.NE:Insert(model) then return end
		if self.NW:Insert(model) then return end
		if self.SE:Insert(model) then return end
		if self.SW:Insert(model) then return end
	end

	return true
end

function QuadTree:Remove(model)
	if self.Models[model] then
		self.Models[model] = nil
		self.ModelCount -= 1

		--if IsDebug then
		--	local beam = model:FindFirstChild("QUADTREEBEAM", true)
		--	local att = model:FindFirstChild("QUADTREEATT", true)
		--	if beam then
		--		beam:Destroy()
		--	end
		--	if att then
		--		att:Destroy()
		--	end
		--end

		if self.Divided then
			self.NE:Remove(model)
			self.NW:Remove(model)
			self.SE:Remove(model)
			self.SW:Remove(model)
		end

		self:Update()
	end
end

local module = {}

module.QuadTree = QuadTree
module.Rectangle = Rectangle

module.Init = function()
	Class.RegisterClass("QuadTree", QuadTree)
	Class.RegisterClass("Rectangle", Rectangle)
end


return module