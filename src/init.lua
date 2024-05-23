--!strict

local Object = require(script.Object)
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
	SUPER: typeof(Types.Super),
	
	new: (string) -> Class,
	configure: (Class, boolean?) -> Types.SetupMethod,

	search: (Class, any, boolean?) -> (any, Types.AnyTable?),
	super: (Class, Types.Object | Types.Super) -> Types.Super,
	typeof: (any) -> (string | {}),
	
	debugPrint: (Class) -> ()
}

local Class = {} :: ClassModule

Class.NEGLECTED = Types.NeglectedClass
Class.CLASS = Types.Class
Class.OBJECT = Types.Object
Class.SUPER = Types.Super

function Class.search(class: Class, index: any, skipCache: boolean?)
	if not skipCache then
		local source = class.__cache[index]
		if source then return source[index], source end
	end
	local value = class.__self[index]
	if value ~= nil then return value, class.__self end
	return nil, nil
end

local function Index(class: Class, index: any, offset: number?): any
	for num = (offset or 1), class.__mrosize do
		local base = class.__mro[num]
		local value, source = Class.search(base, index)
		if value == nil then continue end
		class.__cache[index] = (source :: any)
		return value
	end
	return nil
end

local function NewIndex(class: Class, index: any, value: any, offset: number?)
	for num = (offset or 1), class.__mrosize do
		local base = class.__mro[num]
		local current, source = Class.search(base, index)
		if source ~= nil then
			source[index] = value
			class.__cache[index] = if (current ~= nil) then (source :: any) else nil
		end
	end
end

local function Implement(info: Types.ConfigureInfo): Types.ImplementMethod
	return function (impl: Types.AnyTable)
		local class = info.class
		class.__type = Class.CLASS
		
		class.__self = setmetatable({}, { __index = class.__metamethods }) :: any
		class.__cache = {}
		
		local metamethods = class.__metamethods
		for key, value in impl do
			local valueType = Class.typeof(value)
			if valueType == "function" then
				if key:sub(1, 2) == "__" then
					if Utils.LuaMetamethods[key] then
						metamethods.lua[key] = value
					else
						metamethods.native[key] = value
					end
					continue
				end
			end
			class.__self[key] = value
		end
		
		class.__new = Object.new
		
		local meta = getmetatable(class)
		meta.__index = Index
		meta.__newindex = NewIndex
		return setmetatable(class :: any, meta)
	end
end

local function Inherit(info: Types.ConfigureInfo, ...: Class)
	local neglected = info.class
	neglected.__mro = Utils.Linearize(neglected, ...)
	neglected.__mrosize = table.maxn(neglected.__mro)
	
	local metamethods = neglected.__metamethods
	local superClass = neglected.__mro[2]
	if superClass then
		local superMetas = superClass.__metamethods
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
		__type = Types.NeglectedClass,
		__name = name
	}
	
	local neglected: Class = setmetatable(struct, {
		__tostring = function (this: Class)
			return `{this.__type}<{this.__name}>`
		end,
	}) :: any
	
	neglected.__mro = {neglected}
	neglected.__mrosize = 1
	neglected.__metamethods = setmetatable({
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

local function SuperIndex(super: Types.Super, index: any)
	local object = super.__object
	local value = rawget(object.__self, index)
	if value ~= nil then return value end
	return Index(object.__class, index, super.__offset)
end
local function SuperNewIndex(super: Types.Super, index: any, value: any)
	local object = super.__object
	local attribute = rawget(object.__self, index)
	if attribute ~= nil then
		object[index] = value
		return
	end
	return NewIndex(object.__class, index, value, super.__offset)
end

function Class.super(class: Class, subject: Types.Object | Types.Super)
	local object = subject
	if subject.__type == Types.Super then
		object = (subject :: Types.Super).__object
	end
	
	local main = (object :: Types.Object).__class
	local mro = main.__mro
	local offset = table.find(mro, class)
	
	if offset == nil then
		error(`[Class<{main.__name}>] The class provided to 'Class.super()' was not found within the object's inheritance path!`)
	elseif offset > main.__mrosize then
		error(`[Class<{main.__name}>] The offset calculated for 'Class.super()' was out of the bounds of the class's mro!`)
	end
	
	local super: Types.Super = setmetatable({
		__type = Types.Super,
		__object = object,
		__offset = offset + 1
	}, { __index = SuperIndex, __newindex = SuperNewIndex }) :: any
	
	return super
end

function Class.typeof(value: any)
	local valueType = typeof(value)
	if valueType == "table" then
		local classType = value.__type
		return classType or valueType
	end
	return valueType
end

function Class.debugPrint(class: Class)
	local tbl = setmetatable(table.clone(class :: any), {})
	print(tbl)
end

return Class