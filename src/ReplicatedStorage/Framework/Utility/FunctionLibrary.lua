local FL = {}

local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

FL.CommafyNumber = function(number : number)
	if number == math.huge then
		return "inf"
	end
	if number ~= number then
		return "nan"
	end

	local _,_, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

FL.CopyValue = function(value : any)
	if type(value) == "table" then
		local copy = {}
		for i,v in value do
			if type(i) == "table" then
				i = FL.CopyValue(i)
			end
			if type(v) == "table" then
				v = FL.CopyValue(v)
			end
			copy[i] = v
		end
		return copy
	else
		return value
	end
end

FL.IsWeld = function(v)
	return (v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("ManualWeld") or v:IsA("Motor6D"))
end

FL.PointWithinPart = function(point, part)
	local rel = part.CFrame:ToObjectSpace(CFrame.new(point))
	local min = -part.Size/2
	local max = min + part.Size

	if rel.X > min.X and rel.Y > min.Y and rel.Z > min.Z and rel.X < max.X and rel.Y < max.Y and rel.Z < max.Z then
		return true
	end
end

FL.PointWithinRegion = function(point : Vector3, region : string)
	for _, part in CollectionService:GetTagged(region) do
		if FL.PointWithinPart(point, part) then
			return part
		end
	end
end

local wedge = Instance.new("WedgePart")
wedge.Anchored = true
wedge.TopSurface = Enum.SurfaceType.Smooth
wedge.BottomSurface = Enum.SurfaceType.Smooth

FL.DrawTriangle = function(a, b, c, parent, wedge1,wedge2)
	local edges = {
		{longest = (c - a), other = (b - a), origin = a},
		{longest = (a - b), other = (c - b), origin = b},
		{longest = (b - c), other = (a - c), origin = c}
	}

	local edge = edges[1]
	for i = 2, #edges do
		if (edges[i].longest.magnitude > edge.longest.magnitude) then
			edge = edges[i]
		end
	end

	local theta = math.acos(edge.longest.unit:Dot(edge.other.unit))
	local w1 = math.cos(theta) * edge.other.magnitude
	local w2 = edge.longest.magnitude - w1
	local h = math.sin(theta) * edge.other.magnitude

	local p1 = edge.origin + edge.other * 0.5
	local p2 = edge.origin + edge.longest + (edge.other - edge.longest) * 0.5

	local right = edge.longest:Cross(edge.other).unit
	local up = right:Cross(edge.longest).unit
	local back = edge.longest.unit

	local cf1 = CFrame.new(
		p1.x, p1.y, p1.z,
		-right.x, up.x, back.x,
		-right.y, up.y, back.y,
		-right.z, up.z, back.z
	)

	local cf2 = CFrame.new(
		p2.x, p2.y, p2.z,
		right.x, up.x, -back.x,
		right.y, up.y, -back.y,
		right.z, up.z, -back.z
	)

	-- put it all together by creating the wedges

	local wedge1 = wedge1 or wedge:Clone()
	wedge1.Size = Vector3.new(wedge1.Size.X, h, w1)
	wedge1.CFrame = cf1
	wedge1.Parent = parent

	local wedge2 = wedge2 or wedge:Clone()
	wedge2.Size = Vector3.new(wedge2.Size.X, h, w2)
	wedge2.CFrame = cf2
	wedge2.Parent = parent
end

FL.RemoveNAN = function(x : number, defaultTo)
	return x ~= x and (FL.RemoveNAN(defaultTo) or 0) or x
end

FL.ValidNumber = function(number : number)
	return number == number
end

FL.SameTable = function(tbl1, tbl2)
	for i,v in tbl1 do
		if tbl2[i] ~= v then
			return
		end
	end
	for i,v in tbl2 do
		if tbl1[i] ~= v then
			return
		end
	end
	return true
end

FL.CountTable = function(tbl : {[any]:any})
	local count = 0
	for _ in tbl do
		count += 1
	end
	return count
end

FL.Weld = function(part0 : BasePart, part1 : BasePart, name:string?)
	local weld = Instance.new("ManualWeld")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = part0.CFrame:Inverse() * part1.CFrame
	if name then
		weld.Name = name
	end
	weld.Parent = part0

	return weld
end

FL.WeldModel = function(model : Model)
	local primary = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
	if not primary then return end
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		if part ~= model.PrimaryPart then
			FL.Weld(part, primary, "SelfWeld")
		end
	end
end

FL.SetValues = function(tbl, otherTbl)
	for i, v in otherTbl do
		if type(v) == "table" then
			if not tbl[i] then
				tbl[i] = {}
			end
			FL.SetValues(tbl[i], v)
		else
			tbl[i] = v
		end
	end
end

FL.SetProps = function(part : Instance, props : {[any]:any}, class:string?)
	if part:IsA(class or "BasePart") then
		for prop, val in props do
			part[prop] = val
		end
	end
	for _, v in part:GetChildren() do
		FL.SetProps(v, props)
	end
end

local attachmentOffsets = {
	["BodyBackAttachment"] = CFrame.new(0, 0.499997199, 0.499999881, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["BodyFrontAttachment"] = CFrame.new(0, 0.499997199, -0.5, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["FaceCenterAttachment"] = CFrame.new(3.93568822e-09, 2, 0, 1, 7.87137555e-09, 3.02998127e-15, -7.87137555e-09, 1, -4.1444258e-16, -3.02998127e-15, 4.14442554e-16, 1),
	["FaceFrontAttachment"] = CFrame.new(3.93568866e-09, 2, -0.600000024, 1, 7.87137555e-09, 3.02998127e-15, -7.87137555e-09, 1, -4.1444258e-16, -3.02998127e-15, 4.14442554e-16, 1),
	["HairAttachment"] = CFrame.new(8.65851391e-09, 2.5999999, 0, 1, 7.87137555e-09, 3.02998127e-15, -7.87137555e-09, 1, -4.1444258e-16, -3.02998127e-15, 4.14442554e-16, 1),
	["HatAttachment"] = CFrame.new(8.65851391e-09, 2.5999999, 0, 1, 7.87137555e-09, 3.02998127e-15, -7.87137555e-09, 1, -4.1444258e-16, -3.02998127e-15, 4.14442554e-16, 1),
	["LeftAnkleRigAttachment"] = CFrame.new(-0.500000119, -2.24806046, -2.31832405e-06, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["LeftCollarAttachment"] = CFrame.new(-0.999999821, 1.49999988, -1.91949027e-07, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["LeftElbowRigAttachment"] = CFrame.new(-1.49952102, 0.534616947, 7.64462551e-20, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["LeftGripAttachment"] = CFrame.new(-1.5, -0.499999881, -2.05910766e-07, 1, 0, -0, 0, 6.12323426e-17, 1, 0, -1, 6.12323426e-17),
	["LeftHipRigAttachment"] = CFrame.new(-0.5, -0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["LeftKneeRigAttachment"] = CFrame.new(-0.49999997, -1.32188463, -2.65168723e-07, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["LeftShoulderAttachment"] = CFrame.new(-1.5, 1.45299995, -1.16503799e-07, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["LeftShoulderRigAttachment"] = CFrame.new(-0.999999881, 1.26300001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["LeftWristRigAttachment"] = CFrame.new(-1.49952102, -0.224999964, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["NeckAttachment"] = CFrame.new(9.01869512e-09, 1.5, -4.80920477e-08, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["NeckRigAttachment"] = CFrame.new(0, 1.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["RightAnkleRigAttachment"] = CFrame.new(0.5, -2.24806023, 7.64477882e-05, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["RightCollarAttachment"] = CFrame.new(1, 1.49999964, -7.30796899e-08, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["RightElbowRigAttachment"] = CFrame.new(1.50000012, 0.534508228, 7.64462551e-20, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["RightGripAttachment"] = CFrame.new(1.49999976, -0.499999881, -2.05910766e-07, 1, 0, -0, 0, 6.12323426e-17, 1, 0, -1, 6.12323426e-17),
	["RightHipRigAttachment"] = CFrame.new(0.5, -0.5, -1.91208565e-05, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["RightKneeRigAttachment"] = CFrame.new(0.5, -1.32172894, 2.57324173e-05, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["RightShoulderAttachment"] = CFrame.new(1.49999988, 1.45299995, -1.16503799e-07, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["RightShoulderRigAttachment"] = CFrame.new(1, 1.26300001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["RightWristRigAttachment"] = CFrame.new(1.50000012, -0.224999964, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["RootRigAttachment"] = CFrame.new(0, -0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["WaistBackAttachment"] = CFrame.new(-2.72039244e-08, -0.5, 0.50000006, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["WaistCenterAttachment"] = CFrame.new(-3.02791591e-07, -0.5, -1.65436123e-24, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["WaistFrontAttachment"] = CFrame.new(-1.30105775e-08, -0.5, -0.50000006, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	["WaistRigAttachment"] = CFrame.new(0, -0.100002825, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
}

FL.AccessoriesToModel = function(pieces : {Accessory}, noCanCollide : boolean?)
	local model = Instance.new("Model")

	for _, piece in pieces do
		local piece = piece:Clone()
		local pieceAttachment = piece:FindFirstChildWhichIsA("Attachment", true)
		local destCF = attachmentOffsets[pieceAttachment.Name] or CFrame.identity

		pieceAttachment.Parent:PivotTo(destCF * pieceAttachment.CFrame:Inverse())
		for _, part in piece:GetChildren() do
			part.Parent = model
			if part:IsA("BasePart") then
				part.Massless = false
				part.CanCollide = not noCanCollide
				part.Anchored = false
			end
		end
		if not model.PrimaryPart then
			model.PrimaryPart = pieceAttachment.Parent
		end
		Debris:AddItem(piece, 0)
	end

	-- weld all pieces to a rootPart
	for i,v in model:GetChildren() do
		if v ~= model.PrimaryPart and v:IsA("BasePart") and v.Name == "Handle" then
			FL.Weld(v, model.PrimaryPart)
		end
	end

	return model
end

local bodypartAttachmentLookup = { 
	["LeftWristRigAttachment"] = "LeftHand",
	["LeftGripAttachment"] = "LeftHand",
	["LeftElbowRigAttachment"] = "LeftLowerArm",
	["LeftShoulderRigAttachment"] = "LeftUpperArm",
	["LeftShoulderAttachment"] = "LeftUpperArm",
	["WaistRigAttachment"] = "UpperTorso",
	["NeckRigAttachment"] = "UpperTorso",
	["RightShoulderRigAttachment"] = "UpperTorso",
	["BodyFrontAttachment"] = "UpperTorso",
	["BodyBackAttachment"] = "UpperTorso",
	["LeftCollarAttachment"] = "UpperTorso",
	["RightCollarAttachment"] = "UpperTorso",
	["NeckAttachment"] = "UpperTorso",
	["RootRigAttachment"] = "LowerTorso",
	["LeftHipRigAttachment"] = "LeftUpperLeg",
	["RightHipRigAttachment"] = "RightUpperLeg",
	["WaistCenterAttachment"] = "LowerTorso",
	["WaistFrontAttachment"] = "LowerTorso",
	["WaistBackAttachment"] = "LowerTorso",
	["RightWristRigAttachment"] = "RightHand",
	["RightGripAttachment"] = "RightHand",
	["RightElbowRigAttachment"] = "RightLowerArm",
	["RightShoulderAttachment"] = "RightUpperArm",
	["LeftAnkleRigAttachment"] = "LeftFoot",
	["LeftKneeRigAttachment"] = "LeftLowerLeg",
	["RightAnkleRigAttachment"] = "RightFoot",
	["RightKneeRigAttachment"] = "RightLowerLeg",
	["FaceCenterAttachment"] = "Head",
	["FaceFrontAttachment"] = "Head",
	["HairAttachment"] = "Head",
	["HatAttachment"] = "Head",
}
FL.AttachModelAccessoryToCharacter = function(char, model)
	FL.SetProps(model, {CanCollide = false, Anchored = false, Massless = true, CanTouch = false, CanQuery = false})
	local contraint = Instance.new("RigidConstraint")
	local att0
	for i,v in model:GetDescendants() do
		if bodypartAttachmentLookup[v.Name] then
			att0 = v
			break
		end
	end
	local bodypartName = bodypartAttachmentLookup[att0.Name]
	local att1 = char:WaitForChild(bodypartName):FindFirstChild(att0.Name)
	contraint.Attachment0 = att0
	contraint.Attachment1 = att1
	contraint.Parent = model
end

FL.ShowPos = function(pos :  Vector3, radius, lifeTime)
	local np = Instance.new("Part")
	np.Anchored = true
	np.CanQuery = false
	np.CanCollide = false
	np.CanTouch = false
	np.Size = Vector3.one * (radius or 0.5) * 2
	np.CFrame = CFrame.new(pos)
	np.Parent = workspace
	Debris:AddItem(np, lifeTime or 0.5)
	return np
end

FL.Map = function(x:number, inF:number,inT:number, outF:number, outT:number)
	return ((x - inF)/inT) * (outT - outF) + outF
end
FL.Lerp = function(a:number,b:number,x:number)
	return (b-a)*x+a
end

FL.PartOfPlayer = function(part)
	for _,v in game.Players:GetPlayers() do
		if part == v or v.Character and (part:IsDescendantOf(v.Character) or part == v.Character) or part:IsDescendantOf(v) then
			return v
		end
	end
end

FL.GetPercentColor = function(percent)
	return Color3.fromHSV(0.222222 * math.clamp(percent, 0, 1), 1, 1)
end

FL.TimeToStr = function(length, abrev)
	local minutes = math.floor(length/60)
	local seconds = length % 60

	if abrev then
		local secondsStr = `{seconds}s`
		local minutesStr = `{minutes}m`

		if minutes > 0 then
			return `{minutesStr} {secondsStr}`
		else
			return `{secondsStr}`
		end
	else
		local secondsStr = `{seconds} second{seconds==1 and""or"s"}`
		local minutesStr = `{minutes} minute{minutes==1 and""or"s"}`

		if minutes > 0 then
			return `{minutesStr} {secondsStr}`
		else
			return `{secondsStr}`
		end
	end
end

FL.CombineArrays = function(...)
	local new = {}
	for _, list in {...} do
		for i,v in list do
			table.insert(new, v)
		end
	end
	return new
end

FL.GetPositionAtTime = function(time, origin, initialVelocity, acceleration)
	local force = (acceleration * time^2) / 2
	return (origin + (initialVelocity * time) + force)
end

return FL