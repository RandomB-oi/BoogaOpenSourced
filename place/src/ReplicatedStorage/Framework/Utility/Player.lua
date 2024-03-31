local PlayerUtil = {}

local Players = game:GetService("Players")

PlayerUtil.Distance = function(player : Player, point : Vector3)
	return player:DistanceFromCharacter(point)
end

PlayerUtil.WithinRange = function(player : Player, point : Vector3, range : number)
	return PlayerUtil.Distance(player, point) < range
end

PlayerUtil.PartOfPlayer = function(player : Player, object : Instance) : boolean
	return object:IsDescendantOf(player) or player.Character and object:IsDescendantOf(player.Character) or player.Character == object
end

PlayerUtil.GetPlayerFromPart = function(object : Instance) : Player?
	for _, v in Players:GetPlayers() do
		if PlayerUtil.PartOfPlayer(v, object) then
			return v
		end
	end
	return nil
end

PlayerUtil.IsAlive = function(player : Player)
	if player.Character then
		local hum = player.Character:FindFirstChild("Humanoid")
		if hum then
			return hum.Health > 0
		end
	end
end

PlayerUtil.GetAlivePlayers = function()
	local players = {}
	for _, player in Players:GetPlayers() do
		if PlayerUtil.IsAlive(player) then
			players[#players+1] = player
		end
	end
	return players
end

PlayerUtil.GetPlayersInRadius = function(player : Player, point : Vector3, radius : number)
	local players = {}
	for _, player in Players:GetPlayers() do
		if player.Character and PlayerUtil.WithinRange(player, point, radius) then
			players[#players+1] = player
		end
	end
	return players
end

PlayerUtil.GetClosestPlayer = function(point)
	local closestPlayer, closestDist = nil, math.huge
	for _, player in PlayerUtil.GetAlivePlayers() do
		local dist = PlayerUtil.Distance(player, point)
		if dist < closestDist then
			closestPlayer, closestDist = player, dist
		end
	end
	return closestPlayer, closestDist
end

PlayerUtil.GiveNetworkToNearestPlayer = function(part : BasePart)
	local nearestPlayer = PlayerUtil.GetClosestPlayer(part.Position)

	if nearestPlayer then
		part:SetNetworkOwner(nearestPlayer)
	end
end

PlayerUtil.GetPlayer = function(object : Instance) : Player?
	for _, player : Player in PlayerUtil.GetAlivePlayers() do
		if PlayerUtil.PartOfPlayer(player, object) then
			return player
		end
	end
	return nil
end

PlayerUtil.GetTools = function(player : Player)
	local tools = {}
	for _, tool in player.Backpack:GetChildren() do
		if tool:IsA("Tool") then
			table.insert(tools, tool)
		end
	end
	if player.Character then
		for _, tool in player.Character:GetChildren() do
			if tool:IsA("Tool") then
				table.insert(tools, tool)
			end
		end
	end
	return tools
end

return PlayerUtil