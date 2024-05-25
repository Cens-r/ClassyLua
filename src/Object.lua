--!strict

-- Modules:
local Utils = require(script.Parent.Utils)
local Types = require(script.Parent.Types)

-- Object Module:
local Object = {} :: {
	new: Types.ObjectConstructor,
}

--[[
	Sets a key-value pair in a given metatable if
	the index doesn't already exist.
]]
local function FillMetamethod(metatable: Types.AnyTable, key: string, value: any)
	local method = rawget(metatable :: {}, key)
	if method == nil then
		rawset(metatable :: {}, key, value)
	end
end

--[[
	Constructor for Objects.
	Sets up indexing, fills metamethods, and calls __init().
]]
function Object.new(class: Types.Class, ...:any)
	local struct = {
		__type = Types.Object,
		__class = class
	}
	struct.__self = setmetatable({}, {
		__index = if (class.__mrosize > 1) then
			function (_, index)
				local value = (class.__self :: {})[index]
				if value ~= nil then return value end
				return class:__search(index, 2)
			end
			else class.__self
	})
	
	local meta = table.clone(class.__metamethods)
	FillMetamethod(meta, "__index", struct.__self)
	FillMetamethod(meta, "__newindex", struct.__self)
	FillMetamethod(meta, "__tostring", Utils.tostring)
	
	local object: Types.Object = setmetatable(struct, meta)
	
	local initialize = rawget(class.__self :: {}, "__init")
	if initialize then
		initialize(object, ...)
	end
	
	return object
end

return Object
