local Number = {}

local rng = Random.new(os.time())

Number.IsNan = function(x:number)
	return not (x == x)
end

Number.IsInt = function(x:number)
	return x % 1 == 0
end

Number.Sum = function(list:{number})
	local total = 0
	for _,v in list do
		total += v
	end
	return total
end

Number.Round = function(number : number, inc : number?, ceil : boolean?)
	local inc = inc or 0
	local f = math.round
	if ceil then 
		f = math.ceil
	end

	return f(number/inc)*inc
end

Number.RandomWeight1 = function(weights:{number}, values:{any}, randomObject:Random?)
	local totalWeight = Number.Sum(weights)

	local randomWeight = if Number.IsInt(totalWeight) then
		(randomObject or rng):NextInteger(0, totalWeight)
		else
		(randomObject or rng):NextNumber(0, totalWeight)

	local index = 1
	while randomWeight > weights[index] do
		randomWeight -= weights[index]
		index += 1
	end
	return values[index]
end

Number.RandomWeight2 = function(items:{[any]:number}, randomObject:Random?)
	local weights,values = {},{}

	for item, weight in items do
		weights[#weights+1] = weight
		values[#values+1] = item
	end

	return Number.RandomWeight1(weights, values)
end

Number.CommafyNumber = function(number : number)
	if number == math.huge then
		return "∞"
	end
	if number ~= number then
		return "NaN"
	end

	local _,_, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

return Number