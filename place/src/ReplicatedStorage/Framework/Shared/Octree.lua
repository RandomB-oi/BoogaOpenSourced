local Cell = {}
Cell.__index = Cell

local Class = require(script.Parent.Parent.Class)

local IsDebug = false

Cell.new = function(x,y,z, w,h,l)
	local self = setmetatable({}, Cell)

	self.X = x
	self.Y = y
	self.Z = z
	
	self.W = w
	self.H = h
	self.L = l


	if IsDebug then
		self.DebugPart = Instance.new("Part")
		self.DebugPart.Anchored = true
		self.DebugPart.Size = Vector3.new(w, h, l) - Vector3.one
		self.DebugPart.Position = Vector3.new(x, y, z)
		self.DebugPart.CanCollide = false
		self.DebugPart.CanTouch = false
		self.DebugPart.CanQuery = false
		self.DebugPart.Transparency = 0.9
		self.DebugPart.Color = Color3.new(0, 1, 0)
		self.DebugPart.Material = Enum.Material.Neon
		self.DebugPart.Parent = workspace
	end

	return self
end

function Cell:WithinBounds(model : PVInstance)
	local point = model:GetPivot().Position
	if self.MaxHeight and point.Y >= self.MaxHeight then return false end
	if self.MinHeight and point.Y <= self.MinHeight then return false end

	return 
		point.X >= self.X - self.W/2 and point.Y >= self.Y - self.H/2 and point.Z >= self.Z - self.L/2 and 
		point.X <  self.X + self.W/2 and point.Y <  self.Y + self.H/2 and point.Z <  self.Z + self.L/2
end

function Cell:Intersects(range)
	return not (
		range.X - range.W/2 > self.X + self.W/2 or 
			range.X + self.W/2 < self.X - self.W/2 or 

			range.Y - range.H/2 > self.Y + self.H/2 or 
			range.Y + self.H/2 < self.Y - self.H/2 or

			range.Z - range.L/2 > self.Z + self.L/2 or 
			range.Z + self.L/2 < self.Z - self.L/2
	)
end

function Cell:Destroy()
	if self.DebugPart then
		self.DebugPart:Destroy()
	end
	if self.DebugAttachment then
		self.DebugAttachment:Destroy()
	end
end

local Octree = {}
Octree.__index = Octree

Octree.Octrees = {} -- must be manually defined

Octree.new = function(boundary, minCellCapacity : number, maxDepth : number, depth : number)
	local self = setmetatable({}, Octree)
	self.Boundary = boundary
	self.MinCellCapacity = minCellCapacity
	self.Models = {}
	self.ModelCount = 0
	self.Divided = false

	self.MaxDepth = maxDepth
	self.Depth = depth or 0

	return self
end

function Octree:Subdivide()
	local boundary = self.Boundary

	self.Divided = true
	
	local widthOffset = boundary.W/4
	local heightOffset = boundary.H/4
	local lengthOffset = boundary.L/4
	local newWidth = boundary.W/2
	local newHeight = boundary.H/2
	local newLength = boundary.L/2
	
	self.TNE = Octree.new(Cell.new(boundary.X - boundary.W/4, boundary.Y - boundary.H/4, boundary.Z + boundary.L/4, boundary.W/2, boundary.H/2, boundary.L/2), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	self.TNW = Octree.new(Cell.new(boundary.X + boundary.W/4, boundary.Y - boundary.H/4, boundary.Z + boundary.L/4, boundary.W/2, boundary.H/2, boundary.L/2), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	self.TSE = Octree.new(Cell.new(boundary.X - boundary.W/4, boundary.Y + boundary.H/4, boundary.Z + boundary.L/4, boundary.W/2, boundary.H/2, boundary.L/2), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	self.TSW = Octree.new(Cell.new(boundary.X + boundary.W/4, boundary.Y + boundary.H/4, boundary.Z + boundary.L/4, boundary.W/2, boundary.H/2, boundary.L/2), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	
	self.BNE = Octree.new(Cell.new(boundary.X - boundary.W/4, boundary.Y - boundary.H/4, boundary.Z - boundary.L/4, boundary.W/2, boundary.H/2, boundary.L/2), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	self.BNW = Octree.new(Cell.new(boundary.X + boundary.W/4, boundary.Y - boundary.H/4, boundary.Z - boundary.L/4, boundary.W/2, boundary.H/2, boundary.L/2), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	self.BSE = Octree.new(Cell.new(boundary.X - boundary.W/4, boundary.Y + boundary.H/4, boundary.Z - boundary.L/4, boundary.W/2, boundary.H/2, boundary.L/2), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)
	self.BSW = Octree.new(Cell.new(boundary.X + boundary.W/4, boundary.Y + boundary.H/4, boundary.Z - boundary.L/4, boundary.W/2, boundary.H/2, boundary.L/2), self.MinCellCapacity, self.MaxDepth, self.Depth + 1)

	for model in self.Models do
		self.TNE:Insert(model)
		self.TNW:Insert(model)
		self.TSE:Insert(model)
		self.TSW:Insert(model)
		
		self.BNE:Insert(model)
		self.BNW:Insert(model)
		self.BSE:Insert(model)
		self.BSW:Insert(model)
	end
end

function Octree:Update()
	if self.ModelCount <= self.MinCellCapacity then
		if self.Divided then
			self.Divided = false
			self.TNE.Boundary:Destroy()
			self.TNE = nil
			self.TNW.Boundary:Destroy()
			self.TNW = nil
			self.TSE.Boundary:Destroy()
			self.TSE = nil
			self.TSW.Boundary:Destroy()
			self.TSW = nil

			self.BNE.Boundary:Destroy()
			self.BNE = nil
			self.BNW.Boundary:Destroy()
			self.BNW = nil
			self.BSE.Boundary:Destroy()
			self.BSE = nil
			self.BSW.Boundary:Destroy()
			self.BSW = nil
		end
	end
end

function Octree:QueryBox(range, isValidCallback, found)
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
		self.TNW:QueryBox(range, isValidCallback, found)
		self.TNE:QueryBox(range, isValidCallback, found)
		self.TSW:QueryBox(range, isValidCallback, found)
		self.TSE:QueryBox(range, isValidCallback, found)

		self.BNW:QueryBox(range, isValidCallback, found)
		self.BNE:QueryBox(range, isValidCallback, found)
		self.BSW:QueryBox(range, isValidCallback, found)
		self.BSE:QueryBox(range, isValidCallback, found)
	end

	return found
end

function Octree:SubTreesContain(model : PVInstance)
	if self.Divided then
		return not not (
			self.TNE.Models[model] or self.TNW.Models[model] or self.TSE.Models[model] or self.TSW.Models[model] or
			self.BNE.Models[model] or self.BNW.Models[model] or self.BSE.Models[model] or self.BSW.Models[model]
		)
	end
end

function Octree:Insert(model : PVInstance)
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

		if self.TNE:Insert(model) then return end
		if self.TNW:Insert(model) then return end
		if self.TSE:Insert(model) then return end
		if self.TSW:Insert(model) then return end

		if self.BNE:Insert(model) then return end
		if self.BNW:Insert(model) then return end
		if self.BSE:Insert(model) then return end
		if self.BSW:Insert(model) then return end
	end

	return true
end

function Octree:Remove(model)
	if self.Models[model] then
		self.Models[model] = nil
		self.ModelCount -= 1

		if self.Divided then
			self.TNE:Remove(model)
			self.TNW:Remove(model)
			self.TSE:Remove(model)
			self.TSW:Remove(model)
			
			self.BNE:Remove(model)
			self.BNW:Remove(model)
			self.BSE:Remove(model)
			self.BSW:Remove(model)
		end

		self:Update()
	end
end

local module = {}

module.Octree = Octree
module.Cell = Cell

module.Init = function()
	Class.RegisterClass("Octree", Octree)
	Class.RegisterClass("Cell", Cell)
end


return module