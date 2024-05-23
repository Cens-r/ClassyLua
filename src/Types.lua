--!strict
--# selene: allow(multiple_statements)

--[[
	Contains all the typings for the Class module
]]

--[[ Type Objects ]]
local Types = {}
Types.NeglectedClass = setmetatable({}, { __tostring = function () return "NeglectedClass" end })
Types.Class = setmetatable({}, { __tostring = function () return "Class" end })
Types.Object = setmetatable({}, { __tostring = function () return "Object" end })
Types.Super = setmetatable({}, { __tostring = function () return "Super" end})


--[[ Common ]]
export type Table<Key, Value> = {[Key]: Value}
export type AnyTable = Table<any, any>
export type Pass<Return...> = (...any) -> (Return...)


--[[ ConfigureInfo ]]
export type ImplementMethod = (AnyTable) -> Class
export type InheritMethod = (...Class) -> ImplementMethod
export type SetupMethod = InheritMethod & ImplementMethod

type ConfigureStruct = { class: Class }
type ConfigureMeta = { __call: SetupMethod }
export type ConfigureInfo = typeof(setmetatable({} :: ConfigureStruct, {} :: ConfigureMeta))


--[[ Class ]]
export type MetamethodStruct = {
	lua: AnyTable,
	native: AnyTable
}
export type MetamethodMeta = {
	__index: (ClassMetamethods, any) -> any,
	__iter: (ClassMetamethods) -> (() -> (any, any))
}
export type ClassMetamethods = typeof(setmetatable({} :: MetamethodStruct, {} :: MetamethodMeta)) 

export type ClassStruct = {
	__type: typeof(Types.Class) | typeof(Types.NeglectedClass),
	__name: string,
	
	__mro: Table<number, Class>,
	__mrosize: number,
	
	__self: AnyTable,
	__cache: Table<string, AnyTable>,
	__metamethods: ClassMetamethods,
	
	__new: ObjectConstructor,
}
export type ClassMeta = {
	__index: (Class, any) -> any,
	__newindex: (Class, any, any) -> (),
	__tostring: (Class) -> string
}
export type Class = typeof(setmetatable({} :: ClassStruct, {} :: ClassMeta))


--[[ Object ]]
export type ObjectConstructor = (class: Class, ...any) -> Object
export type Object = {
	__type: typeof(Types.Object),
	__class: Class,
	__self: AnyTable
}


--[[ Super ]]
export type Super = {
	__type: typeof(Types.Super),
	__object: Object,
	__offset: number
}

return Types