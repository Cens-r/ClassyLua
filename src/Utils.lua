--!strict

local Types = require(script.Parent.Types)
local Utils = {}

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

function Utils.nextTable(tbl: any, index: any): (any, any)
	local key, value = next(tbl, index)
	if key == nil then return end
	if type(value) ~= "table" then
		return Utils.nextTable(tbl, key)
	end
	return key, value
end

function Utils.tableIterator(tbl: any): () -> (any, any)
	local nestedKey, nestedTbl = Utils.nextTable(tbl)
	local key, value
	return function ()
		while nestedKey do
			key, value = next(nestedTbl, key)
			if key then return key, value end
			nestedKey, nestedTbl = Utils.nextTable(tbl, nestedKey)
			key, value = nil, nil
		end
		return nil, nil
	end
end

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
			local baseMro = base.__mro__
			local baseOffset = GetOffset(base)

			candidate = baseMro[1 + baseOffset]
			for compareIndex = 1, argCount do
				local compare = args[compareIndex]
				if base == compare then continue end

				local compareMro = compare.__mro__
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
			error("Failed to linearize!")
		end
		table.insert(result, candidate)

		for argIndex = argCount, 1, -1 do
			local base = args[argIndex]
			local mro = base.__mro__
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