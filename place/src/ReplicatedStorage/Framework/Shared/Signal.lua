local Signal = {}
Signal.__index = Signal

Signal.new = function()
	return setmetatable({}, Signal)
end

function Signal:Connect(callback)
	assert(type(callback) == "function", "callback must be a function")
	local connection = {
		_callback = callback,
		Disconnect = function(connection)
			for i, v in self do
				if v == connection then
					self[i] = nil
					break
				end
			end
		end,
	}
	connection.Destroy = connection.Disconnect
	table.insert(self, connection)
	return connection
end

function Signal:Once(callback)
	local conn conn = self:Connect(function(...)
		conn:Disconnect()
		callback(...)
	end)
	return conn
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Once(function(...)
		coroutine.resume(thread, ...)
	end)
	return coroutine.yield(thread)
end

function Signal:Fire(...)
	for _, connection in self do
		if not connection._callback then continue end

		task.spawn(connection._callback, ...)
	end
end

function Signal:Destroy()
	for _, connection in self do
		connection:Disconnect()
	end
end

local Class = require(script.Parent.Parent.Class)
Signal.Init = function()
	Class.RegisterClass("Signal", Signal)
end

return Signal