local module = {}
module.__index = module

local Class = require(script.Parent.Parent.Class)

function module.new(object : Instance)
	local self = setmetatable({}, module)
	self.Maid = Class.new("Maid")
	self.Object = object
	
	return self
end

function module:IsA(className)
	return Class.IsA(self, className)
end

function module:Destroy()
	self.Maid:Destroy()
end

module.Init = function()
	Class.RegisterClass("Component", module)
end

return module