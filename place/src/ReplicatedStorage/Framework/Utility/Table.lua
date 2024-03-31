local Table = {}

Table.Copy = function(value)
	if type(value) == "table" then
		local new = {}
		for i,v in value do
			new[Table.Copy(i)] = Table.Copy(v)
		end
		return new
	end
	
	return value
end

return Table