local module = {}
module.__index = module

module.new = function(autoStep)
	local self = setmetatable({
		_queue = {},
		AutoStep = not not autoStep,
	}, module)

	return self
end

function module:Add(callback, ...)
	local newTask = {
		_callback = callback,
		_params = {...},
		Disconnect = function(newTask)
			for i, v in self._queue do
				if v == newTask then
					table.remove(self._queue, i)
					break
				end
			end
		end,
	}
	table.insert(self._queue, newTask)
	if self.AutoStep and #self._queue == 1 then
		self:Step()
	end
	return newTask
end

function module:Step()
	task.spawn(function()
		local hasTask = self._queue[1]
		if hasTask then
			hasTask._callback(table.unpack(hasTask._params))
			hasTask:Disconnect()
			if self.AutoStep then
				self:Step()
			end
		end
	end)
end

local Class = require(script.Parent.Parent.Class)
module.Init = function()
	Class.RegisterClass("Queue", module)
end

return module