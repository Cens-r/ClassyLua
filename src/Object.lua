local Types = require(script.Parent.Types)
export type Object = Types.Object

type ObjectModule = {
	new: Types.ObjectConstructor,
	
	GetEnvironement: (object: Object, class: Types.Class) -> Types.AnyTable,
	Retrieve: (object: Object, index: any, context: Types.Super?) -> (any, Types.AnyTable),
	
	Index: (object: Object, index: any, context: Types.Super?) -> any,
	NewIndex: (object: Object, index: any, value: any, context: Types.Super?) -> (),
	
	Metamethods: {}
}

local Object = {} :: ObjectModule

function Object.GetEnvironment(object: Object, class: Types.Class)
	class = class or object.__class__
	local env = object.__environments__[class]
	if not env then
		env = {}
		object.__environments__[class] = env
	end
	return env
end

function Object.get(object, index, context)
	local offset = (context and context.__offset__) or 1

	local main = object.__class__
	local mro = main.__mro__
	local size = table.maxn(mro)

	for num = offset, size do
		local class = mro[num]

		local env = Object.GetEnvironment(object, class)
		local attribute = env[index]
		if attribute ~= nil then return attribute, env end

		local value = class:__get__(index, (context or object))
		if value ~= nil then return value end
	end
	return nil, Object.GetEnvironment(object, mro[offset])
end

function Object.Index(object, index, context)
	local value = Object.get(object, index, context)
	return value
end

function Object.NewIndex(object, index, value, context)
	local _, source = Object.get(object, index, context)
	if source ~= nil then
		source[index] = value
		return
	end
	warn(`[Class<{object.__class__.__name__}>] The value for index ({index}) was dropped, the object didn't retrieve a source!`)
end

Object.Metamethods = {
	__index = Object.Index,
	__newindex = Object.NewIndex
}

function Object.new(class: Types.Class, ...: any)
	local struct = {
		__type__ = Types.Object,
		__class__ = class,
		__environments__ = {}
	}
	
	local metamethods = class.__metamethods__
	local meta = table.clone(metamethods.lua)
	for name, method in Object.Metamethods do
		if meta[name] then continue end
		meta[name] = method
	end
	
	local object = setmetatable(struct, meta)
	if metamethods.__init then
		metamethods.__init(object, ...)
	end
	return object
end

return Object