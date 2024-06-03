--!strict

--[[
	Helper method to create custom type objects easier.
	Converts a table to a given name when tostring() is called on it.
]]
local function CustomType(name: string)
	return setmetatable({}, {
		__tostring = function ()
			return name
		end
	})
end

local Types = {}

-- Type Objects:
Types.NeglectedClass = CustomType("NeglectedClass")
Types.Class = CustomType("Class")
Types.Object = CustomType("Object")
Types.Super = CustomType("Super")

--[[ GENERIC TYPES ]]
export type Pass<Return...> = (...any) -> (Return...) 
export type Table<Key, Value> = {[Key]: Value}
export type AnyTable = Table<any, any> | typeof(setmetatable({} :: Table<any, any>, {} :: Table<any, any>))

--[[ CONFIGURE INFO ]]
export type ImplementMethod = (Table<any, any>) -> Class
export type InheritMethod = (...Class) -> ImplementMethod
export type SetupMethod = InheritMethod & ImplementMethod

type ConfigureMeta = { __call: SetupMethod }
type ConfigureStruct = { __class: Class }
export type ConfigureInfo = typeof(setmetatable({} :: ConfigureStruct, {} :: ConfigureMeta))

--[[ CLASS ]]
type ClassMeta = {
	__index: Pass<any> | AnyTable,
	__newindex: Pass<nil> | AnyTable,
	__tostring: Pass<string>
}
type ClassStruct = {
	__type: typeof(Types.Class),
	__name: string,
	
	__custom: AnyTable,
	__self: AnyTable,
	__metamethods: AnyTable,
	
	__mro: {Class},
	__mrosize: number,
	
	__new: ObjectConstructor,
	__search: Pass<any>,
	
	-- Used exclusively for Class.from()
	__instance: Instance?,
}
export type Class = typeof(setmetatable({} :: ClassStruct, {} :: ClassMeta))

--[[ OBJECT ]]
type ObjectMeta = {
	__tostring: Pass<string>
}
type ObjectStruct = {
	__type: typeof(Types.Object),
	__class: Class,
	__self: AnyTable,
	__cleanup: AnyTable,
	__destroy: (Object) -> (),
	
	-- Used exclusively for Class.from()
	__entity: Instance?
}
export type Object = typeof(setmetatable({} :: ObjectStruct, {} :: ObjectMeta))
export type ObjectConstructor = (Class, ...any) -> Object

--[[ SUPER ]]
type SuperMeta = {
	__index: Pass<any>,
	__newindex: Pass<nil>,
	__tostring: Pass<string>
}
type SuperStruct = {
	__type: typeof(Types.Super),
	__object: Object,
	__offset: number
}
export type Super = typeof(setmetatable({} :: SuperStruct, {} :: SuperMeta))

return Types
