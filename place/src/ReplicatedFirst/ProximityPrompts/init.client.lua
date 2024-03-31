local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Maid = require(script.Maid)

local function getPromptsParent() : ProximityPrompt
	local has = PlayerGui:FindFirstChild("ProximityPrompts")

	if not has then
		has = Instance.new("Folder")
		has.Name = "ProximityPrompts"
		has.Parent = PlayerGui
	end

	return has
end

local function bindCircularGui(leftGradient : UIGradient, RightGradient : UIGradient)
	local value = Instance.new("NumberValue")
	value.Value = 0
	
	local function update()
		RightGradient.Rotation = math.clamp(value.Value, 0, 0.5) * 360
		leftGradient.Rotation = -180 + math.clamp(value.Value-0.5, 0, 0.5) * 360
	end
	
	value.Changed:Connect(update)
	update()
	
	return value
end

local function createPrompt(prompt:ProximityPrompt, inputType:Enum.ProximityPromptInputType, parentFolder:Folder)
	local promptMaid = Maid.new()
	
	local promptGui = script.Prompt:Clone()
	promptMaid:GiveTask(promptGui)
	
	local circleValue = bindCircularGui(promptGui.CanvasGroup.Left.Frame.UIStroke.UIGradient, promptGui.CanvasGroup.Right.Frame.UIStroke.UIGradient)
	local enableCircleTween = TweenService:Create(circleValue, TweenInfo.new(prompt.HoldDuration), {Value = 1})
	local disableCircleTween = TweenService:Create(circleValue, TweenInfo.new(0.1), {Value = 0})

	promptGui.CanvasGroup.KeyLabel.Visible = false
	promptGui.CanvasGroup.TapIcon.Visible = false
	
	if inputType == Enum.ProximityPromptInputType.Touch then
		promptGui.CanvasGroup.TapIcon.Visible = true
	elseif inputType == Enum.ProximityPromptInputType.Keyboard then
		promptGui.CanvasGroup.KeyLabel.Visible = true
		promptGui.CanvasGroup.KeyLabel.Text = prompt.KeyboardKeyCode.Name
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		promptGui.CanvasGroup.KeyLabel.Visible = true
		promptGui.CanvasGroup.KeyLabel.Text = prompt.GamepadKeyCode.Name
	end
	
	if inputType == Enum.ProximityPromptInputType.Touch or prompt.ClickablePrompt then
		promptGui.Button.Visible = true
	else
		promptGui.Button.Visible = false
	end
	
	promptGui.Button.Activated:Connect(function()
		prompt:InputHoldBegin()
		enableCircleTween:Play()
	end)
	promptGui.Button.MouseButton1Up:Connect(function()
		prompt:InputHoldEnd()
		disableCircleTween:Play()
	end)
	promptMaid:GiveTask(prompt.PromptButtonHoldBegan:Connect(function()
		prompt:InputHoldBegin()
		enableCircleTween:Play()
	end))
	promptMaid:GiveTask(prompt.PromptButtonHoldEnded:Connect(function()
		prompt:InputHoldEnd()
		disableCircleTween:Play()
	end))
	promptMaid:GiveTask(function()
		prompt:InputHoldEnd()
	end)
	
	local customAdornee = prompt:FindFirstChild("Adornee") and prompt.Adornee.Value or prompt.Parent
	
	promptGui.Adornee = customAdornee
	promptGui.Parent = parentFolder
	local highlight = script.Highlight:Clone()
	highlight.Adornee = customAdornee
	highlight.Parent = parentFolder
	promptMaid:GiveTask(highlight)
	
	return promptMaid
end

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style == Enum.ProximityPromptStyle.Default then
		return
	end

	local folder = getPromptsParent()

	local cleanupMaid = createPrompt(prompt, inputType, folder)

	prompt.PromptHidden:Wait()

	cleanupMaid:Destroy()
end)