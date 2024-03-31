local module = {}

module.new = function(FilterDescendantsInstances:{any}?, FilterType:Enum.RaycastFilterType?, IgnoreWater:boolean?, RespectCanCollide:boolean?, CollisionGroup:string?, BruteForceAllSlow:boolean?)
	local rcp = RaycastParams.new()
	
	if FilterDescendantsInstances ~= nil then
		rcp.FilterDescendantsInstances = FilterDescendantsInstances
	end
	if FilterType ~= nil then
		rcp.FilterType = FilterType
	end
	if IgnoreWater ~= nil then
		rcp.IgnoreWater = IgnoreWater
	end
	if RespectCanCollide ~= nil then
		rcp.RespectCanCollide = RespectCanCollide
	end
	if CollisionGroup ~= nil then
		rcp.CollisionGroup = CollisionGroup
	end
	if BruteForceAllSlow ~= nil then
		rcp.BruteForceAllSlow = BruteForceAllSlow
	end
	
	return rcp
end

module.OnlyTerrain = module.new({workspace.Terrain}, Enum.RaycastFilterType.Include, true)

return module