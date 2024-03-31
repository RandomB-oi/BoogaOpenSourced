local module = {}
module.__index = module
module.Derives = "Component"

local Rep = game:GetService("ReplicatedStorage")
local Framework = require(Rep.Framework)()


module.new = function(self)
	local originalColor = self.Object.Color
	
	self.Maid:GiveTask(task.spawn(function()
		while true do
			self.Object.Color = BrickColor.random().Color
			task.wait(1)
		end
	end))
	self.Maid:GiveTask(function()
		self.Object.Color = originalColor
	end)
	
	return self
end

module.Init = function()
	Framework.Class.RegisterComponent("Rainbow", module)
end

module.Start = function()
end

return module