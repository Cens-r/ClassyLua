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
	__type__: typeof(Types.Class) | typeof(Types.NeglectedClass),
	__name__: string,
	
	__cache__: Table<string, AnyTable>,
	__mro__: Table<number, Class>,
	__mrosize__: number,
	
	__values__: AnyTable,
	__metamethods__: ClassMetamethods,
	
	__new__: ObjectConstructor,
	__get__: (Class, any, boolean?) -> (any, AnyTable?)
}
export type ClassMeta = {
	__call: ObjectConstructor & Pass<any>,
	__index: (Class, any) -> any,
	__newindex: (Class, any, any) -> (),
	__tostring: (Class) -> string
}
export type Class = typeof(setmetatable({} :: ClassStruct, {} :: ClassMeta))


--[[ Object ]]
export type ObjectConstructor = (class: Class, ...any) -> Object
export type Object = {
	__type__: typeof(Types.Object),
	__class__: Class,
	
	__cache__: Table<string, AnyTable>,
	__environments__: Table<Class, AnyTable>
}


--[[ Super ]]
export type Super = {
	__type__: typeof(Types.Super),
	__cache__: Table<string, AnyTable>,
	__object__: Object,
	__offset__: number
}


return Types