local Rep = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")

if Run:IsClient() and not game:IsLoaded() then
	game.Loaded:Wait()
end


local Module = {}

Module.Class = require(script.Class)
Module.Utility = require(script.Utility)

Module.Remotes = script.Remotes

if Run:IsServer() then
	-- any server modules
else
	local Player = game.Players.LocalPlayer
	local PlayerGui = Player:WaitForChild("PlayerGui")
	Module.LoadGuis = function(folder)
		for i,v in folder:GetChildren() do
			v.Parent = PlayerGui
		end
	end
end


local WasInitialized
return function()
	if WasInitialized then
		return Module
	end
	WasInitialized = true
	Module.Class.LoadDirectory(script.Shared)
	
	return Module
end