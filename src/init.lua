--!strict

-- Services:
local HttpService = game:GetService("HttpService")

-- Modules:
local Utils = require(script.Utils)
local Types = require(script.Types)
local Messages = require(script.Messages)
local Object = require(script.Object)

-- Types:
export type Class = Types.Class
export type Object = Types.Object
export type Super = Types.Super

-- Class Module:
local Class = {} :: {
	types: TypeTable,
	
	new: (string?) -> Class,
	configure: (Class, boolean?) -> Types.SetupMethod,
	super: (Class, (Object | Super)) -> Super,
	
	from: (string, string?) -> Class,
	
	typeof: (any) -> (string | Types.AnyTable),
	is: ((Class | Object | Super), (Class | string)) -> boolean,
	trace: (Class | Object | Super | Types.AnyTable) -> Types.AnyTable?
}

-- All the type objects used by ClassyLua
Class.types = {
	NeglectedClass = Types.NeglectedClass,
	Class = Types.Class,
	Object = Types.Object,
	Super = Types.Super
}
type TypeTable = typeof(Class.types)

-- Passing through the typeof method
Class.typeof = Utils.typeof

--[[
	Constructor for ClassyLua's custom Class objects.
	
	Optionally, a string can be passed in to name the
	class for debugging and use within `Class.is()`. 
]]
function Class.new(name: string?)
	name = name or HttpService:GenerateGUID(false)
	local struct = {
		__type = Class.types.NeglectedClass,
		__name = name
	}
	
	struct.__mro = { struct }
	struct.__mrosize = 1
	struct.__custom = {}
	struct.__metamethods = {}
	
	local neglected: Class = setmetatable(struct, {
		__tostring = function (this: Class)
			return `{this.__type}<{this.__name}>`
		end,
		__index = function (_, index)
			return Utils.warn(Messages.neglectedIndex, index)
		end
	}) :: any
	return neglected
end

--[[
	Searches a class for a given index, with the class's
	mro being offset by the provided offset number.
	
	Returns the value and source as a tuple.
]]
local function Search(class: Class, index: any, offset: number): (any, Types.AnyTable?)
	for num = offset, class.__mrosize do
		local base = class.__mro[num]
		local value = (base.__self :: {})[index]
		if value == nil then continue end
		return value, base.__self
	end
	return nil, nil
end

--[[
	Indexes the class before searching its mro.
	
	Returns the value found.
]]
local function Index(class: Class, index: any)
	local value = (class.__self :: {})[index]
	if value ~= nil then return value end
	
	local custom = (class.__custom :: {})[index]
	if custom ~= nil then return custom end
	
	local instance = rawget(class :: any, "__instance")
	if instance then
		local success, result = pcall(function ()
			return (instance :: any)[index]
		end)
		if success and typeof(result) == "function" then
			return Utils.ProcessInstanceMethod(result)
		end
	end
	
	return Search(class, index, 2)
end

--[[
	Searches for the given index and sets it to a value.
]]
local function NewIndex(class: Class, index: any, value: any)
	local instance = class.__instance
	if typeof(value) == "function" then
		value = if instance == nil then Utils.ProcessMethod(value) else Utils.ProcessInstanceMethod(value)
	end
	
	local current = (class.__self :: {})[index]
	if current ~= nil then
		(class.__self :: {})[index] = value
		return
	end
	
	local custom = (class.__custom :: {})[index]
	if custom ~= nil then
		(class.__custom :: {})[index] = value
		return
	end
	
	local _, source = Search(class, index, 2)
	if source ~= nil then
		(source :: {})[index] = value
		return
	end
	rawset(class.__self :: {}, index, value)
end

--[[
	This function is responsible for filling the class with all the
	methods, metamethods, and static values.
	
	Converts a class from a "NeglectedClass" to a "Class".
]]
local function Implement(info: Types.ConfigureInfo): Types.ImplementMethod
	return function (impl: Types.Table<any, any>)
		local class = info.__class
		class.__type = Class.types.Class
		
		local metamethods = class.__metamethods
		class.__self = setmetatable({}, { __index = metamethods });
		(class.__custom :: any).new = function (...)
			return class:__new(...)
		end
		
		for key, value in impl do
			local valueType = Class.typeof(value)
			if valueType == "function" then
				if Utils.LuaMetamethods[key] then
					(metamethods :: {})[key] = value
					continue
				end
				value = Utils.ProcessMethod(value)
			end
			rawset(class.__self :: {}, key, value)
		end
		
		class.__new = Object.new
		class.__search = Search
		
		
		local useExpandedMeta = (class.__mrosize > 1) or (rawget(class :: any, "__instance") ~= nil)
		local meta = getmetatable(class)
		meta.__index = if useExpandedMeta then Index else class.__self
		meta.__newindex = if useExpandedMeta then NewIndex else class.__self
		return setmetatable(class :: any, meta)
	end
end

--[[
	Constructs an MRO for the class, using C3 Linearization.
	Metamethods of superclasses are copied over here as well.
	
	Returns the Implement method.
]]
local function Inherit(info: Types.ConfigureInfo, ...: Class)
	local neglected = info.__class
	neglected.__mro = Utils.Linearize(neglected, ...)
	neglected.__mrosize = table.maxn(neglected.__mro)
	
	local superClass = neglected.__mro[2]
	if superClass then
		neglected.__metamethods = table.clone(superClass.__metamethods)
		local instance = rawget(superClass :: any, "__instance")
		if instance ~= nil then
			neglected.__instance = instance
		end
	end
	return Implement(info)
end

--[[
	This is an "overloaded" function. Its functionality is
	determined by the type of the second argument.
	
	If class: Inherit
	If table: Implement
	Else: ERROR
]]
local SetupMethod: Types.SetupMethod do
	function SetupMethod(info: Types.ConfigureInfo, arg: any, ...: Class): (Class | Types.ImplementMethod)
		local argType = Class.typeof(arg)
		if (argType == Class.types.Class) or argType == "nil" then
			return Inherit(info, arg, ...)
		elseif argType == "table" then
			return Implement(info)(arg)
		else
			return Utils.error(Messages.invalidType, argType) :: never
		end
	end
end

--[[
	Starts the process of configuring a class.
	
	This method will warn the user if the class has already
	been configured before. The second argument accepts a
	boolean which can silence this warning.
	
	Returns ConfigureInfo which is used internally.
	When called it acts as SetupMethod.
]]
function Class.configure(class: Class, bypass: boolean?)
	if (not bypass) and (class.__type == Class.types.Class) then
		Utils.warn(Messages.excessiveConfigure)
	end
	local info = setmetatable({ __class = class }, {
		__call = SetupMethod
	})
	return (info :: any) :: Types.SetupMethod
end


--[[
	Searches the class MRO for a given index from
	an offset in the Super object.
]]
local function SuperIndex(super: Super, index: any)
	local object = super.__object
	return Search(object.__class, index, super.__offset)
end

--[[
	Searches for the given index and sets it to a value.
]]
local function SuperNewIndex(super: Super, index: any, value: any)
	if typeof(value) == "function" then
		value = Utils.ProcessMethod(value)
	end
	local class = super.__object.__class
	local _, source = Search(class, index, super.__offset)
	if source ~= nil then
		(source :: {})[index] = value;
		return
	end
	local superClass = class.__mro[super.__offset]
	rawset(superClass.__self :: {}, index, value);
end

--[[
	Constructor method for Super objects.
	Takes in a class to get the superclass of and an object.
]]
function Class.super(class: Class, subject: (Object | Super))
	local object = subject :: Object
	if subject.__type == Class.types.Super then
		object = (subject :: Super).__object
	end
	
	local main = object.__class
	local mro = main.__mro
	local offset = table.find(mro, class)
	
	if offset == nil then
		Utils.error(Messages.superInvalidClass)
	elseif (offset + 1) > main.__mrosize then
		Utils.error(Messages.superOutOfBound)
	end
	
	local super = setmetatable({
		__type = Class.types.Super,
		__object = object,
		__offset = (offset :: number) + 1
	}, {
		__tostring = Utils.tostring,
		__index = SuperIndex,
		__newindex = SuperNewIndex,
	})
	
	return super
end

--[[
	Constructs a ClassyLua class from a given Instance class name.
	Optionally provide a custom name for the class as the
	second argument.
]]
function Class.from(className: string, name: string?)
	local class = Class.new(name)
	local success, instance = pcall(Instance.new, className)
	if not success then
		Utils.error(Messages.invalidClassName, className)
	end
	
	local function ReplaceInstance()
		Utils.warn(Messages.classInstanceDestroy)
		local replacement = Instance.new(className)
		class.__instance = replacement
		replacement.Destroying:Connect(ReplaceInstance)
	end
	
	class.__custom = {
		ClassName = class.__name,
		Destroy = Object.destroy,
		destroy = Object.destroy,
		Clone = Object.clone,
		clone = Object.clone,
		IsA = Class.is
	}
	class.__instance = instance
	instance.Destroying:Connect(ReplaceInstance)
	
	Class.configure(class) {}
	return class
end

--[[
	Checks if a Class, Object, or Super object is derived from
	a given class, or inherits said class. The class can be provided in
	its object form or by name.

	Returns true or false.
]]
function Class.is(subject: (Class | Object | Super), classType: (Class | string))
	local subjectType = Class.typeof(subject)
	
	local class = nil
	if subjectType == Class.types.Class or subjectType == Class.types.NeglectedClass then
		class = subject
	elseif subjectType == Class.types.Super then
		class = (subject :: Super).__object.__class
	elseif subjectType == Class.types.Object then
		class = (subject :: Object).__class
	else
		return false
	end
	
	for _, base: Class in (class :: Class).__mro do
		if (base == classType) or (base.__name == classType) then
			return true
		end
	end
	return false
end

--[[
	Clones and removes metamethods from a table/object and returns it.
	Useful for debugging, where you need to see the interior of said object
	without metamethods like __tostring interfering.
]]
function Class.trace(subject: (Class | Object | Super | Types.AnyTable))
	if not subject then return nil end
	return setmetatable(table.clone(subject :: any), {})
end

return Class