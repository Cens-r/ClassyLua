--!strict

local Types = require(script.Parent.Types)
export type Object = Types.Object

type ObjectModule = { 
	new: Types.ObjectConstructor,
}

local Object = {} :: ObjectModule

function Object.new(class: Types.Class, ...: any)
	local struct = {
		__type = Types.Object,
		__class = class,
		__self = setmetatable({}, { __index = class })
	}
	
	local metamethods = class.__metamethods
	local meta = table.clone(metamethods.lua)
	meta.__index = meta.__index or struct.__self
	meta.__newindex = meta.__newindex or struct.__self
	
	local object: Object = (setmetatable(struct, meta) :: any)
	local init = metamethods.native.__init
	if init then
		init(object, ...)
	end
	
	return object
end

return Object