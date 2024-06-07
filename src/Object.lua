--!strict

-- Modules:
local Utils = require(script.Parent.Utils)
local Messages = require(script.Parent.Messages)
local Types = require(script.Parent.Types)

-- Object Module:
local Object = {} :: {
	new: Types.ObjectConstructor,
	cleanup: (Types.Object) -> (),
	destroy: (Types.Object) -> (),
	clone: (Types.Object) -> Types.Object
}

-- Warning wrappers:
local function WrappedWarning()
	Utils.warn(Messages.destroyedUse)
end
local function AlreadyDestroyed()
	Utils.warn(Messages.alreadyDestroyed)
end

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
	struct.__self = {}
	struct.__cleanup = {}
	struct.__destroy = Object.destroy
	
	local indexMethod: any = nil
	local newindexMethod: any = nil
	
	local instance = rawget(class :: any, "__instance")
	if instance ~= nil then
		local entity = Instance.new(instance.ClassName)
		struct.__entity = entity
		
		local cleanup = struct.__cleanup
		cleanup["__entity"] = entity
		cleanup["__destroying"] = entity.Destroying:Connect(function ()
			if struct.__destroy == AlreadyDestroyed then return end
			Object.destroy(struct :: any)
		end)
		
		indexMethod = function (_, index)
			-- Index Custom:
			local custom = class.__custom :: {}
			local value = custom[index]
			if value ~= nil then return value end

			-- Index Entity:
			if struct.__entity then
				local success, result = pcall(function ()
					return struct.__entity[index]
				end)
				if success then
					if typeof(result) == "function" then
						local processedMethod = Utils.ProcessInstanceMethod(result)
						custom[index] = processedMethod
						return processedMethod
					end
					return result
				end
			end
			
			-- Index Class:
			value = (class.__self :: {})[index]
			if value ~= nil then return value end
			
			return nil
		end
		
		newindexMethod = function (_, index, value)
			local success = pcall(function ()
				struct.__entity[index] = value
			end)
			if success then return end
			rawset(struct.__self, index, value)
		end
	end
	
	if class.__mrosize > 1 then
		local previous = indexMethod
		indexMethod = function (_, index)
			if previous ~= nil then
				local result = previous(nil, index)
				if result ~= nil then return result end
			else
				-- NOTE: class.__custom??
				local value = (class.__self :: {})[index]
				if value ~= nil then return value end
			end
			
			-- Search Class:
			return class:__search(index, 2)
		end
	end
	
	-- NOTE: class.__custom??
	setmetatable(struct.__self, { __index = indexMethod or class.__self, __newindex = newindexMethod })
	
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

--[[
	Cleans up an object's __cleanup table.
	Uses the GenericCleanup utility method from Utils.
]]
function Object.cleanup(object: Types.Object)
	local cleanupTbl = object.__cleanup
	Utils.GenericCleanup(cleanupTbl)
end

--[[
	Destroys and cleans up the given object.
	
	This method will also warn users if the object
	is used past its destruction point.
]]
function Object.destroy(object: Types.Object)
	if Utils.typeof(object) == Types.Class then
		return Utils.warn(Messages.classInstanceDestroy)
	end

	if object.__destroy == AlreadyDestroyed then
		return AlreadyDestroyed()
	end
	object.__destroy = AlreadyDestroyed
	setmetatable(object :: any, {
		__index = WrappedWarning,
		__newindex = WrappedWarning
	})
	Object.cleanup(object)
end

function Object.clone()
	-- TODO: Implement this
end

return Object
