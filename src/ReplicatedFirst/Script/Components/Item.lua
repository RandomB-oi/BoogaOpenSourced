local module = {}
module.__index = module
module.Derives = "Component"

local Rep = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")

local Framework = require(Rep.Framework)()

local Player = Players.LocalPlayer

module.new = function(self)
	
	return self
end

module.Init = function()
	Framework.Class.RegisterComponent("AAAAA", module)
end

module.Start = function()
end

return module