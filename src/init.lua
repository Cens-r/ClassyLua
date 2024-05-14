--!strict

local Object = require(script.Object)
local Super = require(script.Super)
local Utils = require(script.Utils)
local Types = require(script.Types)

export type Class = Types.Class
export type Object = Types.Object
export type Pass<Return> = Types.Pass<Return>

type Table<Key, Value> = Types.Table<Key, Value>

type ClassModule = {
	TYPE: typeof(Types.Class),
	
	new: (name: string) -> Class,
	configure: (class: Class) -> Types.SetupMethod,

	mro: (class: Class) -> {[number]: Class},
	super: (class: Class, object: Types.Object) -> (),

	typeof: (value: any) -> (string | {})
}

local Class = {} :: ClassModule
Class.TYPE = Types.Class

local function Retrieve(class: Class, index: any): (any, Types.AnyTable?)
	local static = class.__static__[index]
	if static ~= nil then return static, class.__static__ end
	local method = class.__methods__[index]
	if method ~= nil then return method, class.__methods__ end
	local metamethod = class.__metamethods__[index]
	if metamethod ~= nil then return metamethod, nil end
	return nil, nil
end

local function Index(class: Class, index: any): any
	for _, base in Class.mro(class) do
		local value = base:__get__(index)
		if value == nil then continue end
		return value
	end
	return nil
end

local function NewIndex(class: Class, index: any, value: any)
	for _, base in Class.mro(class) do
		local _, source = base:__get__(index)
		if source ~= nil then
			source[index] = value
			break
		end
	end
end

local function IndexMetamethod(tbl: Types.ClassMetamethods, index: any)
	local method = tbl.lua[index]
	if method ~= nil then return method end
	return tbl.native[index]
end

local function Implement(info: Types.ConfigureInfo): Types.ImplementMethod
	return function (impl: Types.AnyTable)
		local class = info.class
		class.__type__ = Class.TYPE
		
		class.__static__ = {}
		class.__methods__ = {}
		class.__metamethods__ = setmetatable({
			lua = {},
			native = {}
		}, {
			__index = IndexMetamethod,
			__iter = Utils.tableIterator
		})
		
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
				else
					class.__methods__[key] = value
				end
			else
				class.__static__[key] = value
			end
		end
		
		class.__get__ = Retrieve
		
		local meta = {}
		meta.__call = Object.new
		meta.__index = Index
		meta.__newindex = NewIndex
		setmetatable(class :: any, meta)
		
		return class
	end
end

local function Inherit(info: Types.ConfigureInfo, ...: Class)
	local class = info.class
	class.__mro__ = Utils.Linearize(class, ...)
	return Implement(info)
end

local SetupClass: Types.SetupMethod = nil do
	function SetupClass(info: Types.ConfigureInfo, arg: any, ...: Class): (Class | Types.ImplementMethod)
		local argType = Class.typeof(arg)
		if argType == Class.TYPE or argType == "nil" then
			return Inherit(info, arg, ...)
		elseif argType == "table" then
			return Implement(info)(arg)
		else
			error(`INVALID TYPE({argType}): SETUP FAILED!`)
		end
	end
end

function Class.new(name: string)
	local struct = {
		__type__ = Types.NeglectedClass,
		__name__ = name
	}
	
	local neglected = setmetatable(struct, {
		__call = function ()
			error("Attempted to create an object from a neglected class!")
		end,
		__tostring = function (this: Class)
			return `{this}<{this.__name__}>`
		end,
	}) :: Class
	
	neglected.__mro__ = {neglected}
	return neglected
end

function Class.configure(class: Class)
	local info = { class = class }
	setmetatable(info, {
		__call = SetupClass
	})
	return (info :: any) :: Types.SetupMethod
end

function Class.mro(class: Class)
	return table.clone(class.__mro__)
end

function Class.super(class: Class, object: Types.Object)
	local mro = object.__class__.__mro__
	local offset = table.find(mro, class)
	
	if offset == nil then
		error("WRITE AN ERROR HERE")
	end
	return Super(object, offset)
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
