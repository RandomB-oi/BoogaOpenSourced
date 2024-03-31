local RegionUtil = {}

local CollectionService = game:GetService("CollectionService")

RegionUtil.IsPointInsideBox = function(point:Vector3, cf:CFrame, size:Vector3)
	local relative = CFrame.new(point):ToObjectSpace(cf)
	local min = -size/2
	local max = min + size
	return 
		relative.X < max.X and relative.X > min.X and 
		relative.Y < max.Y and relative.Y > min.Y and 
		relative.Z < max.Z and relative.Z > min.Z
end

RegionUtil.GetRegions = function(point:Vector3)
	local regions = {}
	for _, part in CollectionService:GetTagged("Region") do
		if RegionUtil.IsPointInsideBox(point, part.CFrame, part.Size) then
			if not table.find(regions, part.Name) then
				table.insert(regions, part.Name)
			end
		end
	end
	return regions
end

RegionUtil.InsideRegion = function(point:Vector3, region:string)
	for _, part in CollectionService:GetTagged("Region") do
		if RegionUtil.IsPointInsideBox(point, part.CFrame, part.Size) then
			if part.Name == region then
				return true
			end
		end
	end
end

return RegionUtil