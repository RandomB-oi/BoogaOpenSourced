local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))()

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)

Framework.LoadGuis(script.Parent.Guis)
Framework.Class.LoadDirectory(script, true)

Framework.Class.Begin()