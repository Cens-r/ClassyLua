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
export type Pass<T> = (...any) -> ()


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
	
	__mro__: Table<number, Class>,
	
	__static__: AnyTable,
	__methods__: AnyTable,
	__metamethods__: ClassMetamethods,
	
	__get__: (class: Class, index: any) -> (any, AnyTable?)
}
export type ClassMeta = {
	__call: ObjectConstructor,
	__index: (Class, any) -> any?,
	__newindex: (Class, any, any) -> (),
	__tostring: (Class) -> string
}
export type Class = typeof(setmetatable({} :: ClassStruct, {} :: ClassMeta))


--[[ Object ]]
export type ObjectConstructor = ({class: Class}) -> Object
export type Object = {
	__type__: typeof(Types.Object),
	__class__: Class,
	__environments__: Table<Class, AnyTable>
}


--[[ Super-Context ]]
type SuperStruct = {
	__type__: typeof(Types.Super),
	__object__: Object,
	__offset__: number
}
type SuperMeta = {
	__index: (Super, any) -> any,
	__newindex: (Super, any, any) -> ()
}
export type Super = typeof(setmetatable({} :: SuperStruct, {} :: SuperMeta))


return Types
