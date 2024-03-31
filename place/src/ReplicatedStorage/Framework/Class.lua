local CollectionService = game:GetService("CollectionService")
local Run = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Module = {}
local Classes = {}
local Components = {}

local RequiredModules = {}
local AlreadyRequiredModules = {}

local function GameDoneLoading()
	for name, component in Components do
		local function newObject(object : Instance)
			if Run:IsServer() and object:IsDescendantOf(ReplicatedFirst) then return end
			if object:IsDescendantOf(game:GetService("StarterGui")) then return end
			if object:FindFirstAncestor("Prefabs") or object:FindFirstAncestor("Components") then return end

			if component.Objects[object] then return end
			local attributeName
			if Run:IsServer() then
				attributeName = `SDidComp_{name}`
			else
				attributeName = `CDidComp_{name}`
			end
			if object:GetAttribute(attributeName) then
				return
			end

			object:SetAttribute(attributeName, true)

			local newComponent = Module.new(name, object)
			component.Objects[object] = newComponent
		end

		CollectionService:GetInstanceRemovedSignal(name):Connect(function(object)
			local objectComponent = component.Objects[object]

			local attributeName
			if Run:IsServer() then
				attributeName = `SDidComp_{name}`
			else
				attributeName = `CDidComp_{name}`
			end
			if not object:GetAttribute(attributeName) then
				return
			end

			if objectComponent then
				object:SetAttribute(attributeName, nil)
				component.Objects[object] = nil
				objectComponent:Destroy()
			end
		end)
		CollectionService:GetInstanceAddedSignal(name):Connect(newObject)
		for _, object in CollectionService:GetTagged(name) do
			task.spawn(newObject, object)
		end
	end
end

local function InitGame()
	for _, v in RequiredModules do
		local has = rawget(v, "Init")
		if has then
			has()
		end
	end
end
local function StartGame()
	for _, v in RequiredModules do
		local has = rawget(v, "Start")
		if has then
			has()
		end
	end
	GameDoneLoading()
end

Module.GetClass = function(name : string)
	return Classes[name]
end

Module.RegisterClass = function(name : string, class : {[any] : any})
	Classes[name] = class
end

Module.RegisterComponent = function(name : string, component : {[any] : any})
	Module.RegisterClass(name, component)
	
	Components[name] = component
	component.Objects = {}
end

local setmetatableModules = {}
Module.new = function(name : string, ...)
	local order = {name}
	local parentClassName = name

	while true do
		local parentClass = Module.GetClass(parentClassName)
		parentClass.Name = parentClassName
		local derives = rawget(parentClass, "Derives")
		if derives then
			if not setmetatableModules[parentClassName] then
				setmetatableModules[parentClassName] = true
				local deriveClass = Module.GetClass(derives)
				parentClass.Base = deriveClass
				setmetatable(parentClass, deriveClass)
			end
			parentClassName = derives
			table.insert(order, parentClassName)
		else
			table.remove(order, #order) -- because this is parentClass
			break
		end
	end

	local object = Module.GetClass(parentClassName).new(...)
	for i = #order, 1, -1 do
		local subClass = Module.GetClass(order[i])
		setmetatable(object, subClass)
		local newMethod = rawget(subClass, "new")
		if newMethod then
			object = newMethod(object) or object
		end
	end
	return object
end

Module.IsA = function(class, className)
	if class.Name == className then return true end
	local derives = rawget(class, "Derives")
	if derives then
		return Module.IsA(Module.GetClass(derives), className)
	end
end

Module.LoadDirectory = function(dir : Instance, descendants : boolean)
	local children = descendants and dir:GetDescendants() or dir:GetChildren()

	for _, v : ModuleScript in children do
		if v:IsA("ModuleScript") then
			if table.find(AlreadyRequiredModules, v) then continue end
			
			table.insert(AlreadyRequiredModules, v)
			table.insert(RequiredModules, require(v))
		end
	end
end

Module.Begin = function()
	InitGame()
	StartGame()
end

Module.GetComponent = function(object : Instance, componentName : string, _iterated)
	local class = Module.GetClass(componentName)
	if not (class and class.Objects) then return end

	local _iterated = _iterated or {}

	if not class.Objects[object] then
		for _, tag in object:GetTags() do
			if table.find(_iterated, tag) then continue end
			table.insert(_iterated, tag)
			
			local foundClass = Module.GetClass(tag)
			if foundClass and Module.IsA(foundClass, componentName) then
				return Module.GetComponent(object, tag, _iterated)
			end
		end
	end

	return class.Objects[object]
end

return Module