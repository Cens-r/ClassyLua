--!strict

local Types = require(script.Parent.Types)
export type Object = Types.Object

type ObjectModule = { 
	new: Types.ObjectConstructor,
	search: (Object | Types.Super, any, boolean?) -> (any, Types.AnyTable, boolean?),
	
	GetEnvironment: (Object, Types.Class) -> Types.AnyTable,
	
	Index: (Object | Types.Super, any) -> any,
	NewIndex: (Object | Types.Super, any, any) -> nil,
	
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

function Object.search(subject: Object | Types.Super, index: any, skipCache : boolean?)
	local cache = subject.__cache__ :: {}
	if (not skipCache) and (cache ~= nil) then
		local source = cache[index]
		if source ~= nil then return source[index], source end
	end
	
	local object, offset = subject, 1
	if subject.__type__ == Types.Super then
		object = (subject :: Types.Super).__object__
		offset = (subject :: Types.Super).__offset__
	end
	
	local main = (object :: Object).__class__
	local mro = main.__mro__
	local size = main.__mrosize__
	
	local source, value = nil, nil
	for num = offset, size do
		local class = mro[num]
		
		source = Object.GetEnvironment((object :: Object), class)
		value = source[index]
		if value ~= nil then break end
		
		local env = nil
		source = (nil :: any)
		value, env = class:__get__(index, skipCache)
		if value ~= nil then
			if not skipCache then
				mro[offset].__cache__[index] = (env :: any)
			end
			skipCache = true
			break
		end
		source = (nil :: any)
	end
	
	source = source or Object.GetEnvironment(object :: Object, mro[offset])
	return value, source, skipCache
end

function Object.Index(object, index)
	local value, source, skipCache = Object.search(object, index)
	if (not skipCache) and (value ~= nil) then
		(object.__cache__ :: {})[index] = source
	end
	return value
end

function Object.NewIndex(object, index, value)
	local _, source, skipCache = Object.search(object, index)
	if source ~= nil then
		source[index] = value
		if (value ~= nil) and (not skipCache) then
			(object.__cache__ :: {})[index] = source
		end
		return nil
	end
	
	if object.__type__ == Types.Super then
		object = (object :: Types.Super).__object__
	end
	return warn(`[Class<{(object :: Object).__class__.__name__}>] The value for index ({index}) was dropped, the object didn't retrieve a source!`)
end

Object.Metamethods = {
	__index = Object.Index,
	__newindex = Object.NewIndex
}

function Object.new(class: Types.Class, ...: any)
	local struct = {
		__type__ = Types.Object,
		__class__ = class,
		
		__cache__ = {},
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
	return (object :: any) :: Object
end

return Object