# ClassyLua
ClassyLua is a module created to offer an alternative to the standard object-oriented programming (OOP) approach in Lua/Luau. It was designed after Python's class system, while still feeling like Lua/Luau.

***Note**: The explanation of the module below is based on the assumption you have a basic understanding of OOP. It's suggested you have a solid grasp of this concept in Lua, Python, or any other language with OOP capabilities.*

## Fundamentals
Creating and implementing classes in most programming languages fall under the same action. However, these are two separate actions in ClassyLua for typing purposes. Due to this, there are two types of classes:

- **NeglectedClass**: The class has yet to be implemented, and awaits such an action.
- **Class**: The class is implemented and functional.

All classes start as a **NeglectedClass** at creation and will transition to a **Class** once fully implemented. To do these two actions there are two core methods within the module:
- `Class.new(name: string)` : Used to construct a new class, a name must be supplied.

- `Class.configure(class: Class, bypass: boolean?)` : Used to implement or configure a given class. Ideally, you should only be using the method as a first-time implementation of a class and it will warn you if the class has already been implemented. An optional second argument, "bypass" which is a boolean, acts as a means to silence this warning if you so wish. 

The two will likely be used together for most, if not all, class declarations so you should get comfortable with them.

## Basic Usage
Through the use of the two methods mentioned above, we can create a class. Through this demonstration, you should get an understanding of how the two methods work together to form the class.
It will also example of the layout of the implementation table which will be provided to `Class.configure()`, so you can get familiar with how that works.

### Construction
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

  -- The __init metamethod is called every time an object is constructed
  __init = function (self, value)

    -- The object is always passed as the first argument here
    -- You can store your attributes inside the object
    self.value = value

    -- Change static values by using the class itself
    MyClass.count += 1
  end
}
```

### Objects
```lua
-- Constructing an object from MyClass
local object = MyClass(5)

-- Accessing that object's value attribute
print(object.value) -- Output: 5

-- Accessing our static variable
print(MyClass.count)
-- OR:                } Output: 1
print(object.count)
```
