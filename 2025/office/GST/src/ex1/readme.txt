GObject and its lower-level type system GType are used by GTK and most GNOME libraries to provide:
- OO C-based APIs
- automatic transparent API binding to other compiled or interpreted languages.

GType library holds the runtime description of all the objects manipulated by the program. This so-called
dynamic type library then used by special generic glue code to automatically convert function parameters and
functions calling conventions between different runtime domains. ( py, c , c++...)
The advantage of this type of solution implemented by GType is that the glue code sitting at the runtime
domain boundaries is written once. Currently there are multiple generic glue code which makes it possible to
use C objects written in GType directly in variety of other languages with minimum amount of work.
This also prevents to generate huge amounts of glue code either automatically or by hand.

=> GObject and GType not only offer OO like features to C but also transparent cross-language
interoperability.

GType: Its a unique identifier for every class in the GObject type system. When you create a new class, you
are essentially "registering" a new GType.

A GType is a unique identifier used by the GObject system to represent a specific type of class or
interface. It's a fundamental part of GLib's object system, providing a robust, runtime-verifiable way to 
handle object types.

Think of it as a type registry that provides key features:

* *Type Identity*: Each class (like `GObject` or `MyObject`) gets a unique `GType` value, which can be used to identify it at runtime.
* *Inheritance*: `GType` tracks the parent-child relationships between types, allowing for type-safe casting and inheritance checks.
* *Type System*: It enables the GObject type system to manage properties, signals, and virtual functions for a given class.

When you define a new GObject-derived class with macros like `G_DEFINE_TYPE`, the GObject system automatically assigns it a new `GType` and registers it within the type system.


# Step 1: Create a Simple GObject Type*

Goal:

Define a basic GObject-derived type and instantiate it.

---

### File Structure:

```
simple/
├── main.c
├── myobject.c
└── myobject.h
```

---

#### `myobject.h`

```c
#ifndef MY_OBJECT_H
#define MY_OBJECT_H

#include <glib-object.h>

#define MY_TYPE_OBJECT (my_object_get_type())
G_DECLARE_FINAL_TYPE(MyObject, my_object, MY, OBJECT, GObject)

MyObject* my_object_new(void);

#endif
```
1. G_DECLARE_FINAL_TYPE: This macro that generates the boilerplate code needed to declare a new GObject
type:
    - MyObject: Name of the new type.
    - my_object: prefix of all the functions and macros related to this type( ex: my_object_get_type())
    - MY: the namespace prefix
    - OBJECT: name of the type in namespace.
    - GObject: Parent type from which MyObject inherits.
2. MY_TYPE_OBJECT: macro for getting GType identifier of MyObject. This is a key part of the GObject system,
as GType is used for type checking and instance creation.
    - my_object_new(): A public constructor function to create new instances of MyObject.

---
Implementation:

#### `myobject.c`

```c
#include "myobject.h"
#include <stdio.h>

struct _MyObject {
    GObject parent_instance;
};

G_DEFINE_TYPE(MyObject, my_object, G_TYPE_OBJECT)

static void my_object_class_init(MyObjectClass *klass) {
    // Nothing to override for now
}

static void my_object_init(MyObject *self) {
    g_print("MyObject initialized!\n");
}

MyObject* my_object_new(void) {
    return g_object_new(MY_TYPE_OBJECT, NULL);
}
```
- struct _MyObject: This defines the instance structure for MyObject. 
  The first member must be the parent's instance structure (GObject parent_instance) to ensure compatibility
  with the inheritance model. You can add more members after this for your custom data.

- G_DEFINE_TYPE: This macro is the counterpart to G_DECLARE_FINAL_TYPE. It generates all the necessary "C" 
code for registering the type with the GObject system, including the my_object_get_type() function and the 
type initialization functions (my_object_class_init and my_object_init).

- my_object_class_init(): func is called once during prog startup when the MyObject type is first registered.
It's used to set up class-specific properties, virtual function tables, and signals.

- my_object_init(): function is called every time a new instance of MyObject is created. It's used to 
initialize instance-specific data. In this example, it simply prints a message.

- my_object_new(): public construct func which is defined here to be used in main.c it internally calls 
g_object_new() ( Which is the standard GObject function for creating a new instance of a given type.)
- g_object_new(MY_TYPE_OBJECT, NULL): This is the core function call for instantiation.
    - MY_TYPE_OBJECT: The GType of the object to create.
    - NULL: A list of initial properties to set. In this case, none are provided.
---

####  `main.c`
Demo how to create and manage an instance of MyObject.

```c
#include "myobject.h"

int main() {
    MyObject *obj = my_object_new();
    g_print("Created a MyObject instance: %p\n", obj);

    g_object_unref(obj);
    return 0;
}
```

---

### *Compile and Run*:

```sh
gcc `pkg-config --cflags --libs gobject-2.0` -o simple main.c myobject.c
./simple
```

---

### Output:

```
MyObject initialized!
Created a MyObject instance: 0x55e1b2fa6240
```

---

### What You Learned:

* How to define a GObject-derived type (`G_DEFINE_TYPE`)
* Object instantiation with `g_object_new()`
* Basic boilerplate for `.h` and `.c`

----
1. GType: A unique identifier used by GObject system to represent a specific type of class or interface. Its
a fundamental part of GLib's  Object system, providing robust, runtime-verifiable way to handle object
types.

Think of it as a type registry that provides key features :
- Type Identity : Each class  (like GObject or MyObject) get unique GType value, which can be used to
  identify it at runtime.

- Inherirance: GType tracs parent-child relationship between Types allowing for type-safe casting and
  Inherirance checks.
  - Type Systems: It enables GObject type system to manage properties, signals and virtual functions for a
    given class.

When we define "G_DEFINE_TYPE" the GObject system automatically assigns it a new GType and register it
within the type system.
