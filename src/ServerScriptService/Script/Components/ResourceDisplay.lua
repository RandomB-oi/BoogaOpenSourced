local module = {}
module.__index = module
module.Derives = "Component"

local Rep = game:GetService("ReplicatedStorage")
local Framework = require(Rep.Framework)()


module.new = function(self)
	local originalCF = self.Object:GetPivot()

	local serverModel = Instance.new("Part")
	serverModel.Name = "Reference"
	serverModel.Size = Vector3.one * 2
	serverModel.Anchored = true
	serverModel.CanCollide = false
	serverModel.CanQuery = true
	serverModel.CanTouch = true
	self.Object:ClearAllChildren()
	serverModel:PivotTo(originalCF)
	serverModel.Parent = self.Object
	self.Object.PrimaryPart = serverModel
	
	return self
end

module.Init = function()
	Framework.Class.RegisterComponent("ResourceDisplay", module)
end

module.Start = function()
end

return module