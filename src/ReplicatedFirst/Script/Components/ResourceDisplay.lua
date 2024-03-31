local module = {}
module.__index = module
module.Derives = "Component"

local Rep = game:GetService("ReplicatedStorage")
local Framework = require(Rep.Framework)()

module.new = function(self)
	local foundModel = Rep.Prefabs:FindFirstChild(self.Object.Name, true)
	if foundModel then
		self.DisplayModel = foundModel:Clone()
		self.DisplayModel.Name = "Model"
		self.DisplayModel:PivotTo(self.Object:GetPivot())
		self.DisplayModel.Parent = self.Object
		self.Maid.Model = self.DisplayModel
	else
		warn(`{self.Object.Name} is not inside prefabs`)
	end

	return self
end

module.Init = function()
	Framework.Class.RegisterComponent("ResourceDisplay", module)
end

module.Start = function()
end

return module