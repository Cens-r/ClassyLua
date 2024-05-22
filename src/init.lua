--!strict

local Object = require(script.Object)
local Super = require(script.Super)
local Utils = require(script.Utils)
local Types = require(script.Types)

export type Class = Types.Class
export type Object = Types.Object
export type Pass<Return...> = Types.Pass<Return...>

type Table<Key, Value> = Types.Table<Key, Value>

type ClassModule = {
	CLASS: typeof(Types.Class),
	NEGLECTED: typeof(Types.NeglectedClass),
	OBJECT: typeof(Types.Object),
	
	new: (name: string) -> Class,
	configure: (class: Class, bypass: boolean?) -> Types.SetupMethod,

	search: (Class, any, boolean?) -> (any, Types.AnyTable?),

	mro: (class: Class) -> {[number]: Class},
	super: (class: Class, object: Types.Object) -> Types.Super,

	typeof: (value: any) -> (string | {})
}

local Class = {} :: ClassModule
Class.NEGLECTED = Types.NeglectedClass
Class.CLASS = Types.Class
Class.OBJECT = Types.Object

function Class.search(class: Class, index: any, skipCache: boolean?)
	if not skipCache then
		local source = class.__cache__[index]
		if source then  return source[index], source end
	end
	local value = class.__values__[index]
	if value ~= nil then return value, class.__values__ end
	local metamethod = class.__metamethods__[index]
	if metamethod ~= nil then return metamethod, (class.__metamethods__ :: any) end
	return nil, nil
end

local function Index(class: Class, index: any): any
	for _, base in Class.mro(class) do
		local value, source = Class.search(base, index)
		if value == nil then continue end
		class.__cache__[index] = (source :: any)
		return value
	end
	return nil
end

local function NewIndex(class: Class, index: any, value: any)
	for _, base in Class.mro(class) do
		local value, source = base:__get__(index)
		if source ~= nil then
			source[index] = value
			class.__cache__[index] = if (value ~= nil) then (source :: any) else nil
			break
		end
	end
end

local function Implement(info: Types.ConfigureInfo): Types.ImplementMethod
	return function (impl: Types.AnyTable)
		local class = info.class
		class.__type__ = Class.CLASS
		
		class.__cache__ = {}
		class.__values__ = {}
		
		for key, value in impl do
			local valueType = Class.typeof(value)
			if valueType == "function" then
				local _, count = key:gsub("__", "")
				if count == 1 then
					local metamethods = class.__metamethods__
					if Utils.LuaMetamethods[key] then
						metamethods.lua[key] = value
					else
						metamethods.native[key] = value
					end
				end
			end
			class.__values__[key] = value
		end
		
		class.__new__ = Object.new
		class.__get__ = Class.search
		
		local meta = {}
		meta.__call = class.__new__
		meta.__index = Index
		meta.__newindex = NewIndex
		setmetatable(class :: any, meta)
		
		return class
	end
end

local function Inherit(info: Types.ConfigureInfo, ...: Class)
	local neglected = info.class
	neglected.__mro__ = Utils.Linearize(neglected, ...)
	neglected.__mrosize__ = table.maxn(neglected.__mro__)
	
	local metamethods = neglected.__metamethods__
	local superClass = neglected.__mro__[2]
	if superClass then
		local superMetas = superClass.__metamethods__
		metamethods.lua = table.clone(superMetas.lua)
	end
	
	return Implement(info)
end

local SetupClass: Types.SetupMethod = nil do
	function SetupClass(info: Types.ConfigureInfo, arg: any, ...: Class): (Class | Types.ImplementMethod)
		local argType = Class.typeof(arg)
		if argType == Class.CLASS or argType == "nil" then
			return Inherit(info, arg, ...)
		elseif argType == "table" then
			return Implement(info)(arg)
		else
			error(`INVALID TYPE({argType}): SETUP FAILED!`)
		end
	end
end

local function IndexMetamethod(tbl: Types.ClassMetamethods, index: any)
	local method = tbl.lua[index]
	if method ~= nil then return method end
	return tbl.native[index]
end

function Class.new(name: string)
	local struct = {
		__type__ = Types.NeglectedClass,
		__name__ = name
	}
	
	local neglected = setmetatable(struct, {
		__call = function (this: Class)
			error(`[Class<{this.__name__}>] Attempted to construct an object from a Neglected class!`)
		end,
		__tostring = function (this: Class)
			return `{this}<{this.__name__}>`
		end,
	}) :: Class
	
	neglected.__mro__ = {neglected}
	neglected.__mrosize__ = 1
	neglected.__metamethods__ = setmetatable({
		lua = {},
		native = {}
	}, {
		__index = IndexMetamethod,
		__iter = Utils.tableIterator
	})
	
	return neglected
end

function Class.configure(class: Class, bypass: boolean?)
	if (not bypass) and (class.__type__ == Class.CLASS) then
		warn(`[Class<{class.__name__}>] Configuring a class that has already been implemented! Use the 'bypass' parameter to silence this warning.`, debug.traceback())
	end
	local info = { class = class }
	setmetatable(info, {
		__call = SetupClass
	})
	return (info :: any) :: Types.SetupMethod
end

function Class.mro(class: Class)
	return table.clone(class.__mro__)
end

function Class.super(class: Class, object: Types.Object | Types.Super)
	if object.__type__ == Types.Super then
		object = (object :: Types.Super).__object__
	end
	
	local main = (object :: Types.Object).__class__
	local mro = main.__mro__
	local offset = table.find(mro, class)
	
	if offset == nil then
		error(`[Class<{main.__name__}>] The class provided to 'Class.super()' was not found within the object's inheritance path!`)
	elseif offset > main.__mrosize__ then
		error(`[Class<{main.__name__}>] The offset calculated for 'Class.super()' was out of the bounds of the class's mro!`)
	end
	
	return Super((object :: Types.Object), offset + 1)
end

function Class.typeof(value: any)
	local valueType = typeof(value)
	if valueType == "table" then
		local classType = value.__type__
		return classType or valueType
	end
	return valueType
end

return Class