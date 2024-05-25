--!strict

-- Modules:
local Types = require(script.Parent.Types)
local Messages = require(script.Parent.Messages)

-- Utils Module:
local Utils = {}

-- List of all the lua metamethods for reference
Utils.LuaMetamethods = {
	__index = true,
	__newindex = true,
	__call = true,
	__concat = true,
	__unm = true,
	__add = true,
	__sub = true,
	__mul = true,
	__div = true,
	__idiv = true,
	__mod = true,
	__pow = true,
	__tostring = true,
	__metatable = true,
	__eq = true,
	__lt = true,
	__le = true,
	__mode = true,
	__gc = true, -- NOT FUNCTIONAL IN ROBLOX!
	__len = true,
	__iter = true
}


local MissingID = "missingID"
local ErrorSuffix = "\n(ID: %s)"

--[[
	Formats a message using its id to retrieve the message,
	and the arguments provided to fill in placeholders.
	
	Returns the formatted message.
]]
local function parse(id: string, ...: any)
	local message = Messages.__messages[id]
	if message then
		return message:format(...) .. ErrorSuffix:format(id)
	end
	message = Messages.__messages[MissingID]
	return (message :: any):format(id) ..ErrorSuffix:format(MissingID)
end

--[[
	Custom warn method that parses the error ids given.
	Takes in arguments to pass to `parse()`.
]]
function Utils.warn(id: string, ...: any)
	local message = parse(id, ...)
	warn(debug.traceback(message, 2))
end

--[[
	Custom error method that parses the error ids given.
	Takes in arguments to pass to `parse()`.
]]
function Utils.error(id: string, ...: any)
	local message = parse(id, ...)
	error(message)
end

--[[
	Converts an Object or Super object to a specific string format.
	Format: TYPE<ADDRESS>
]]
function Utils.tostring(subject: Types.Object | Types.Super)
	local object = subject :: Types.Object
	if object.__type == Types.Super then
		object = (subject :: Types.Super).__object
	end
	return `{subject.__type}<{tostring(object.__self):sub(8)}>`
end

--[[
	Linearizes a given set of classes using C3 Linearization.
	Errors if no the set can't be linearized.
	
	Returns a predictable array of classes to be used for MRO.
]]
function Utils.Linearize(class: Types.Class, ...: Types.Class)
	local result = {class}
	local args = {...}

	local OffsetMap = {}
	local function GetOffset(key)
		return OffsetMap[key] or 0
	end

	local argCount = 0
	local function RecountArgs()
		argCount = #args
		return argCount
	end

	while RecountArgs() > 0 do
		local candidate: Types.Class? = nil
		for baseIndex = 1, argCount do
			local base = args[baseIndex]
			local baseMro = base.__mro
			local baseOffset = GetOffset(base)

			candidate = baseMro[1 + baseOffset]
			for compareIndex = 1, argCount do
				local compare = args[compareIndex]
				if base == compare then continue end

				local compareMro = compare.__mro
				local compareOffset = GetOffset(compare) + 2

				local compareMroLength = #compareMro
				if compareMroLength < compareOffset then continue end

				for searchIndex = compareOffset, compareMroLength do
					local value = compareMro[searchIndex]
					if value == candidate then
						candidate = nil
						break
					end
				end
				if not candidate then break end
			end
			if candidate then break end
		end

		if not candidate then
			return Utils.error(Messages.linearizeFailure)
		end
		table.insert(result, candidate)

		for argIndex = argCount, 1, -1 do
			local base = args[argIndex]
			local mro = base.__mro
			local offset = GetOffset(base) + 1

			if mro[offset] == candidate then
				if offset >= #mro then
					table.remove(args, argIndex)
				end
				OffsetMap[base] = offset
			end
		end
	end

	return result
end


return Utils
