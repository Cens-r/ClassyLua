--!strict

local Object = require(script.Parent.Object)
local Types = require(script.Parent.Types)
export type Super = Types.Super

local function SuperIndex(super: Super, index: any)
	return Object.Index(super.__object__, index, super)
end
local function SuperNewIndex(super: Super, index: any, value: any)
	return Object.NewIndex(super.__object__, index, value, super)
end

return function (object: Types.Object, offset: number): Super
	local struct = {
		__type__ = Types.Super,
		__object__ = object,
		__offset__ = offset
	}
	return setmetatable(struct, {
		__index = SuperIndex,
		__newindex = SuperNewIndex
	})
end