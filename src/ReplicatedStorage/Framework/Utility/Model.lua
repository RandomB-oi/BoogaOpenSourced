local ModelUtil = {}

ModelUtil.GetRoot = function(object : PVInstance) : BasePart?
	local partInside = object:FindFirstChildOfClass("BasePart")

	if object:IsA("Tool") then
		return object:FindFirstChild("Handle") or partInside
	end
	if object:IsA("Model") then
		return object.PrimaryPart or partInside
	end
	if object:IsA("BasePart") then
		return object
	end

	return nil
end

ModelUtil.NoCollide = function(object:Instance)
	if object:IsA("BasePart") then
		object.CanCollide = false
	end
	for _,v in object:GetChildren() do
		ModelUtil.NoCollide(v)
	end
end

ModelUtil.Anchor = function(object:Instance)
	if object:IsA("BasePart") then
		object.Anchored = true
	end
	for _,v in object:GetChildren() do
		ModelUtil.Anchor(v)
	end
end
ModelUtil.Unanchor = function(object:Instance)
	if object:IsA("BasePart") then
		object.Anchored = false
	end
	for _,v in object:GetChildren() do
		ModelUtil.Unanchor(v)
	end
end
ModelUtil.PhysicsIgnore = function(object:Instance)
	if object:IsA("BasePart") then
		object.CanQuery = false
		object.CanTouch = false
		--object.CanCollide = false
	end
	for _,v in object:GetChildren() do
		ModelUtil.PhysicsIgnore(v)
	end
end
ModelUtil.RemovePhysics = function(object:Instance)
	ModelUtil.Unanchor(object)
	ModelUtil.NoCollide(object)
	ModelUtil.PhysicsIgnore(object)
end
ModelUtil.Distance = function(object:PVInstance, point:Vector3)
	local normalized = object:GetPivot().Position - point
	local rcp = RaycastParams.new()
	rcp.FilterDescendantsInstances = {object}
	rcp.FilterType = Enum.RaycastFilterType.Include
	rcp.RespectCanCollide = false
	local ray = workspace:Raycast(point, normalized, rcp)
	if ray then
		return ray.Distance
	end
	return normalized.Magnitude
end


return ModelUtil