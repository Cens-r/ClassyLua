# ClassyLua
ClassyLua is a module created to offer an alternative to the standard object-oriented programming (OOP) approach in Lua/Luau. It was designed after Python's class system, while still feeling like Lua/Luau.

***Note**: The explanation of the module below is based on the assumption you have a basic understanding of OOP. It's suggested you have a solid grasp of this concept in Lua, Python, or any other language with OOP capabilities.*

## Purpose and Reasoning
Lua lacks a proper class system and there are very few modules built to offer a proper solution to this issue. We are left to abuse metatables which is fine for simple classes that only inherit a single class,
but not for more complex classes that need to inherit multiple classes. Mixins become seemingly out of the question as there's no proper way to inherit them all at once to a single class, and index shadowing can
be a pain to deal with if you're trying to keep a proper order.

ClassyLua abstracts all of that, letting you deal with implementing your classes while it takes care of the hassle of inheritance for you. Using [C3 Linearization](https://en.wikipedia.org/wiki/C3_linearization)
the module will construct a method resolution order (MRO) that keeps all the inherited classes in a predictable and well-defined order.

With use of this MRO, ClassyLua offers you a handful of useful features such as:
* `super()` - Access inherited classes directly
* `is()` - Identify if a class or object is equivalent to or a subclass of a given class
* `typeof()` - A more robust typeof method with support for ClassyLua
* Metamethod inheritance from inherited classes

## Fundamentals
Creating and implementing classes in most programming languages fall under the same action. However, these are two separate actions in ClassyLua for typing purposes. Due to this, there are two types of classes:

- **NeglectedClass**: The class has yet to be implemented, and awaits such an action.
- **Class**: The class is implemented and functional.

All classes start as a **NeglectedClass** at creation and will transition to a **Class** once fully implemented. To do these two actions there are two core methods within the module:
- `Class.new(name: string?)` : Used to construct a new class. If the name is left blank a UUID will be generated in its place.

- `Class.configure(class: Class, bypass: boolean?)` : Used to implement or configure a given class. Ideally, you should only be using the method as a first-time implementation of a class and it will warn you if the class has already been implemented. An optional second argument, "bypass" which is a boolean, acts as a means to silence this warning if you so wish. 

The two will likely be used together for most, if not all, class declarations so you should get comfortable with them.

## Basic Usage
Through the use of the two methods mentioned above, we can create a class. Through this demonstration, you should get an understanding of how the two methods work together to form the class.
It will also provide an example of the layout of the implementation table which will be provided to `Class.configure()`, so you can get familiar with how that works.

### Construction
As explained before, to construct a class its as simple as calling `Class.new()` and providing it with a name. It's important to note that currently the class is considered a **NeglectedClass** which means it has not been implemented yet, and will need to be implemented before you can start using/indexing it.
```lua
local Class = require(PATH.TO.ClassyLua)
local MyClass = Class.new("MyClass") --> Provide a name to identify your class
```
### Implementation
```lua
Class.configure(MyClass) {

  -- Define methods, static values, and metamethods here
  -- They will be stored within the class
  count = 0,
  foo = function ()
    print("Hello World")
  end,

  -- The __init metamethod is called every time an object is constructed
  __init = function (self, value)
    -- The object is always passed as the first argument here
    -- You can store your attributes inside the object
    self.value = value
    -- Change static values by using the class itself
    MyClass.count += 1
  end,

  -- The __new method is the universal object constructor
  -- for all of ClassyLua's classes.
  new = MyClass.__new
}
```

### Objects
```lua
-- Constructing an object from MyClass
local object = MyClass.new(5)

-- Accessing that object's value attribute
print(object.value) -- Output: 5

-- Accessing our static variable
print(MyClass.count)
-- OR:                } Output: 1
print(object.count)
```

### Inheritance
```lua
local Example = Class.new("Example")

-- Inherited classes are provided as arguments to
-- the function returned from `Class.configure()`
--                        [ HERE ]
Class.configure(Example) (MyClass) {
  __init = function (self, value)
    -- The method `Class.super()` can be used to get
    -- superclass of a given class. Since Example has its
    -- own `__init` we need to call MyClass's `__init` this way
    Class.super(Example, self):__init(value)
  end,
  new = Example.__new
}

-- OUTPUT EXAMPLES:
local object = Example.new(52)
print(object.value) -- Output: 52
print(Example.count) -- Output: 52
Example.foo() -- Output: "Hello World"
```
