--!strict

local Object = require(script.Parent.Object)
local Types = require(script.Parent.Types)
export type Super = Types.Super

return function (object: Types.Object, offset: number): Super
	local struct = {
		__type__ = Types.Super,
		__cache__ = {},
		__object__ = object,
		__offset__ = offset
	}
	return (setmetatable(struct, {
		__index = Object.Index,
		__newindex = Object.NewIndex
	}) :: any) :: Super
end