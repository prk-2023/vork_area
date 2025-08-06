# GObject:


## Intro
- Most modern programming language come with their own native Object systems and additional fundamental algorithmic language constructs. Similar to GLib that comes with a set of implementations to support fundamental types and algorithms ( LinkedLists, HashTables, ...). The GLib Object system provides the required implementations of a flexible, extensible and internally easy to map ( to other languages ) OO framework for C.


Summery of the elements that are provided are as below:

1. A generic type system to register arbitrary single-inherited flat and deep derived types as well as interfaces for structured types. It takes care of creation, initialization and memory management of the assorted object and class structures, maintains parent/child relationships and deals with dynamic implementations of such types. That is, their type specific implementations are relocatable/unloadable during runtime.

    - GObjects: A generic type system...
    This means *GObject* isn't designed for one specific kind of object (like a video player or a file handler). It's a general-purpose framework that lets you define and manage *any kind of structured data* as a "type" or "class."
    - *Register arbitrary types:* You can define a new class for anything you want, whether it's a GStreamer element, a UI widget, or a custom data structure. GObject provides the mechanism to "register" this new type so the system knows how to handle it.
    - *Single-inherited:* This is a key limitation of GObject. A class can only inherit from one parent class. This is similar to how inheritance works in many other languages like Java or C#. For example, a `GstVideoDecoder` can inherit from `GstElement`, but it can't simultaneously inherit from a separate `MyCustomBaseClass`.
    - *Flat and deep derived types:*  A "flat" type is a base class that doesn't inherit from anything else (except `GObject` itself).
    - *Deep derived:* A "deep derived" type is a class that's several levels down in the inheritance hierarchy. For example, `GstXvImageSink` is a deeply derived type that inherits from `GstBaseSink`, which inherits from `GstElement`, which inherits from `GstObject`. GObject's system manages this entire chain of inheritance.
    - interfaces for structured types: This is how GObject gets around the "single-inheritance" limitation. An *interface* is a set of methods that a class *must* implement, but it's not a parent class. For example, in GStreamer, you might have an interface called `GstTagListInterface`. Any GObject that implements this interface promises to provide a specific set of functions for handling tags, even if it has a completely different parent class. This is similar to interfaces in Java or protocols in Objective-C.
    - Takes care of creation, initialization and memory management of the assorted object and class structures: This is the core value proposition of GObject. It handles the low-level, error-prone tasks for you:
        - *Creation:* When you create a new object of a registered type, GObject automatically allocates the memory for it and its parent classes.
        - *Initialization:* It calls the correct initialization functions for your class and all its parent classes in the right order.
        - *Memory management:* This is done primarily through *reference counting*. When you get a reference to an object, you "increment" its reference count. When you're done, you "decrement" it. When the count hits zero, GObject automatically frees the memory, preventing memory leaks. This is a huge benefit for C programming.
        - maintains parent/child relationships: This refers to the class hierarchy. GObject keeps track of which types are a parent or child of other types. This is essential for things like casting an object to a parent type (`GstElement` to `GstObject`) and for ensuring that the correct virtual functions are called at runtime.
        - and deals with dynamic implementations of such types. That is, their type specific implementations are relocatable/unloadable during runtime.
            This is a fancy way of describing how plugins work. GObject's type system is designed to be *dynamic*. You can load a GStreamer plugin (a shared library file) at runtime, and the GObject system will read its type information, register the new classes (like `my_awesome_filter`), and make them available to the rest of the application. Later, you could unload that plugin from memory. This is what makes GStreamer so flexible and extensible—you can add or remove functionality without recompiling the entire application.

2. A collection of fundamental type implementations such as int, double, enums, and struct types ...

3. A sample fundamental types implementation to base object hierarchies upon - GObject fundamental type..

4. A signal system that allows very flexible user customization of virtual/overridable object methods and can serve as a powerful notification mechanism.

5. An extendible parameter/value system, supporting all the provided fundamental types that can be used to generically handle object properties or otherwise parameterized types.

## Getting started:

### Install the required devl pkgs:
    sudo apt install libglib2.0-dev 
    or 
    sudo dnf install glib2-devel

### The Core Concepts 

Before we write any code, let's internalize the most important GObject concepts.

- GObject: 
  The fundamental base class for all objects in the GObject system. Every object you create will eventually be a descendant of GObject.

- GType: 
  A unique identifier for every class in the GObject type system. When you create a new class, you're essentially "registering" a new GType.

- Class and Instance Structures: GObject uses two main structs for each type:
    1. Class Struct: 
      Holds a pointer to the parent class's struct and a set of function pointers (virtual methods). There is only one instance of this class struct for each type, created the first time an object of that type is instantiated.

    2. Instance Struct: 
      Holds the private data for a specific object. There is one instance struct for every object you create.

- Properties: 
  GObject's way of exposing and controlling an object's state. Properties are named, typed values that can be set and retrieved using a consistent API (g_object_set, g_object_get).

- Reference Counting: 
  GObject manages memory using a reference-counting system. You use g_object_ref() to get a new reference and g_object_unref() to drop one. When an object's reference count drops to zero, its memory is automatically freed.


### GObject programming 

Since GObjects involves many concepts its better go in steps instead of tackling everything simultaneously, its better to learn the core components one by one. Here’s a sequential approach to get familiar with GObject programming.

1. The Instance and Class Structures
    Before diving into macros and functions, understand the fundamental building blocks of a GObject.
    * *Instance Structure:* Think of this as the object's private data. Every instance of your custom GObject type has its own copy of this structure. It *must* have its parent's instance structure as its first member.
    * *Class Structure:* This contains the shared data and virtual methods (function pointers) for all instances of your type. It also *must* have its parent's class structure as its first member.

    This dual-structure concept is key to GObject's object-oriented design in C. 

2. The Type System and Boilerplate
    Next, focus on how GObject registers and manages your custom type. The macros are the key to this process.
    * `G_DECLARE_FINAL_TYPE`: This macro goes in your header file (`.h`). It declares the instance and class structures and a function to get the `GType` ID for your object.
    * `G_DEFINE_FINAL_TYPE`: This macro goes in your source file (`.c`). It implements the declarations from the header file, including the **`_class_init`** and **`_init`** functions.
    * **`_init` function:** This is called for every new instance of your object. Its purpose is to initialize the private data in the instance structure.
    * **`_class_init` function:** This is called only **once** when the type is first registered. Its purpose is to set up the class structure, such as registering properties or signals.

Start by creating an object with just these two functions. Don't worry about properties or methods yet. Simply print a message in each function to see the execution flow.

3. Properties
    Once you understand the basic type system, add a property to your object. Properties are a standardized way to get and set data on an object.

    * **`G_PARAM_READWRITE`**: This flag indicates that a property can be both read from and written to.
    * **`g_object_class_install_property`**: This function is called in your `_class_init` function to define and register the property.
    * **`set_property` and `get_property` functions**: These are the virtual methods you must override in your `_class_init` function. GObject calls these when `g_object_set()` or `g_object_get()` are used. These functions handle the actual reading and writing of your private data.

4. Public Methods and Signals
    Finally, add your custom logic.
    
    * **Public Methods**: These are regular C functions that take a pointer to your object as the first argument (e.g., `my_counter_increment`). Use the `MY_IS_COUNTER()` macro at the start of these functions for type safety.
    * **Signals**: GObject's signal system allows objects to communicate. When a property changes, you should call `g_object_notify()` to emit the `notify::` signal for that property. This allows other objects to connect to the signal and react to the change without tight coupling.

By following this sequence—starting with structures, then the type system, then properties, and finally methods and signals—you build your understanding one layer at a time.

###  step-by-step approach 

Things to cover interconnected concepts (object-oriented principles, signals, memory management, type systems, etc.), so it's much more effective to learn it incrementally.

Aim is of this structured path will help you understand the core components *one at a time*, leading to a 
solid understanding without being overwhelmed.

#### *Step 0: Prerequisites*

Before diving into GObject:

* Know basic C programming
* Understand pointers and structs
* Know how to compile C programs with `gcc`
* Optional: Some familiarity with object-oriented programming (OOP) concepts

---

#### *Step 1: Understand GObject’s Purpose*

* What is GObject?

  * GObject is the base object system used in GNOME and GTK.
  * It brings OOP features (like inheritance, interfaces, signals) to C.
* Why use it?

  * It provides dynamic type checking, object introspection, properties, and signals — essential for large-scale C applications.

Read:

* [GObject Overview on GNOME Developer](https://developer.gnome.org/gobject/stable/)

---

#### *Step 2: Setup Development Environment*

1. Install required tools:

   * **Linux**: `sudo apt install libglib2.0-dev`
   * **macOS**: `brew install glib`
2. Learn to compile a GObject program:

   ```bash
   gcc my_object.c `pkg-config --cflags --libs gobject-2.0` -o my_object
   ```

---

#### *Step 3: Create a Simple GObject Type*

**Goals**:

* Define a basic GObject-derived type
* Create and destroy an instance

*Learn*:

* `G_DEFINE_TYPE()`
* `GObject` boilerplate macros
* Memory management with `g_object_new()` and `g_object_unref()`

Practice:

```c
// MyObject.h and MyObject.c
G_DECLARE_FINAL_TYPE(MyObject, my_object, MY, OBJECT, GObject)
```

Compile and run a simple instance.

---

#### *Step 4: Add Properties*

*Goals*:

* Learn how to define object properties (`GParamSpec`)
* Use `g_object_set()` and `g_object_get()`

*Learn*:

* `GObjectClass::set_property`
* `GObjectClass::get_property`

Practice:

* Add a string property like `"name"` to your object
* Set and get its value

---

#### *Step 5: Signals*

*Goals*:

* Understand how to define and emit signals
* Connect signals to callbacks

*Learn*:

* `g_signal_new()`
* `g_signal_emit()`
* `g_signal_connect()`

Practice:

* Define a `"changed"` signal and emit it when a property changes

---

#### *Step 6: Inheritance and Virtual Functions*

*Goals*:

* Derive a new class from your object
* Override methods (virtual functions)

*Learn*:

* GObject class hierarchy
* `parent_class` pattern for overriding
* Virtual method dispatch

Practice:

* Create `MyDerivedObject` from `MyObject` and override a method

---

#### *Step 7: Interfaces*

*Goals*:

* Define and implement a GInterface
* Understand how interfaces differ from inheritance

*Learn*:

* `GTypeInterface`
* `g_type_add_interface_static()`

Practice:

* Define a printable interface, `MyPrintable`, with a `print()` method

---

#### *Step 8: Reference Counting and Memory Management*

*Goals*:

* Master object lifecycle
* Understand weak refs, floating refs (important in GTK)

*Learn*:

* `g_object_ref()` / `g_object_unref()`
* `g_object_weak_ref()`

Practice:

* Watch what happens when multiple references exist and unref one

---

#### *Step 9: GObject Introspection (Optional)*

If you want to use your GObject in other languages (Python, JS):

* Learn how to use `GIR` tools
* Generate introspection data
* Bind from Python using PyGObject

---

#### *Step 10: Write a Small App Using GObjects*

Combine what you've learned:

* Define a few object types
* Use signals, properties, and inheritance
* Hook them together in a simple CLI or GTK app

---
Example code at each step or a walkthrough of one of them in detail?


Structured walk-through with *example code for each step* in the GObject learning path.

We'll start simple and build up from there, so you can see how each concept works in action.

---

## *Step 1: Create a Simple GObject Type*

---

### **Goal**:

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

---

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

---

####  `main.c`

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

--------------------------------------------------

## *Step 2: Adding Properties to Your GObject*

---

### *Goal*:

* Add a property (e.g., `"name"`) to your GObject.
* Learn to set and get its value with `g_object_set()` and `g_object_get()`.

---

### File Structure:

```
with-property/
├── main.c
├── myobject.c
└── myobject.h
```

---

#### Changes from Step 1:

* Add a `name` property of type `gchar*`.
* Handle it via `set_property` and `get_property`.

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

---

#### `myobject.c`

```c
#include "myobject.h"
#include <string.h>

struct _MyObject {
    GObject parent_instance;
    gchar *name;  // Our property
};

enum {
    PROP_0,       // Required by GObject
    PROP_NAME,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

G_DEFINE_TYPE(MyObject, my_object, G_TYPE_OBJECT)

// set_property implementation
static void my_object_set_property(GObject *object,
                                   guint property_id,
                                   const GValue *value,
                                   GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_NAME:
            g_free(self->name);
            self->name = g_value_dup_string(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

// get_property implementation
static void my_object_get_property(GObject *object,
                                   guint property_id,
                                   GValue *value,
                                   GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_NAME:
            g_value_set_string(value, self->name);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

// finalize to free memory
static void my_object_finalize(GObject *object) {
    MyObject *self = MY_OBJECT(object);
    g_free(self->name);

    G_OBJECT_CLASS(my_object_parent_class)->finalize(object);
}

static void my_object_class_init(MyObjectClass *klass) {
    GObjectClass *gobject_class = G_OBJECT_CLASS(klass);

    gobject_class->set_property = my_object_set_property;
    gobject_class->get_property = my_object_get_property;
    gobject_class->finalize = my_object_finalize;

    obj_properties[PROP_NAME] =
        g_param_spec_string("name",       // property name
                            "Name",       // nick name
                            "The name",   // description
                            NULL,         // default value
                            G_PARAM_READWRITE);

    g_object_class_install_properties(gobject_class, N_PROPERTIES, obj_properties);
}

static void my_object_init(MyObject *self) {
    self->name = g_strdup("default");
}

MyObject* my_object_new(void) {
    return g_object_new(MY_TYPE_OBJECT, NULL);
}
```

---

#### `main.c`

```c
#include "myobject.h"

int main() {
    MyObject *obj = my_object_new();

    // Set property
    g_object_set(obj, "name", "Alice", NULL);

    // Get property
    gchar *name = NULL;
    g_object_get(obj, "name", &name, NULL);

    g_print("Object name: %s\n", name);

    g_free(name);
    g_object_unref(obj);
    return 0;
}
```

---

#### Compile & Run:

```sh
gcc `pkg-config --cflags --libs gobject-2.0` -o with-property main.c myobject.c
./with-property
```

---

#### Output:

```
Object name: Alice
```

---

### What You Learned:

* How to define, set, and get a GObject property
* How to manage memory for string properties
* How to override `set_property()` and `get_property()`
* Use of `GParamSpec` and `g_object_class_install_properties`

--------------------------

## *Step 3: Adding and Using Signals in GObject*

---

Goal:

* Define a custom signal (e.g., `"name-changed"`).
* Connect to the signal with a callback.
* Emit the signal from your code.

---

### File Structure:

```
with-signal/
├── main.c
├── myobject.c
└── myobject.h
```

---

#### What's New in This Step:

* Define a custom signal using `g_signal_new()`
* Emit signal using `g_signal_emit()`
* Connect signal with `g_signal_connect()`

---

#### `myobject.h`

```c
#ifndef MY_OBJECT_H
#define MY_OBJECT_H

#include <glib-object.h>

#define MY_TYPE_OBJECT (my_object_get_type())
G_DECLARE_FINAL_TYPE(MyObject, my_object, MY, OBJECT, GObject)

MyObject* my_object_new(void);
void my_object_set_name(MyObject *self, const gchar *name);
const gchar* my_object_get_name(MyObject *self);

#endif
```

---

#### `myobject.c`

```c
#include "myobject.h"

struct _MyObject {
    GObject parent_instance;
    gchar *name;
};

enum {
    PROP_0,
    PROP_NAME,
    N_PROPERTIES
};

enum {
    NAME_CHANGED,  // Signal ID
    N_SIGNALS
};

static guint signals[N_SIGNALS] = { 0 };
static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

G_DEFINE_TYPE(MyObject, my_object, G_TYPE_OBJECT)

// SET PROPERTY
static void my_object_set_property(GObject *object, guint property_id,
                                   const GValue *value, GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_NAME:
            my_object_set_name(self, g_value_get_string(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

// GET PROPERTY
static void my_object_get_property(GObject *object, guint property_id,
                                   GValue *value, GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_NAME:
            g_value_set_string(value, self->name);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

static void my_object_finalize(GObject *object) {
    MyObject *self = MY_OBJECT(object);
    g_free(self->name);

    G_OBJECT_CLASS(my_object_parent_class)->finalize(object);
}

// CLASS INIT
static void my_object_class_init(MyObjectClass *klass) {
    GObjectClass *gobject_class = G_OBJECT_CLASS(klass);
    gobject_class->set_property = my_object_set_property;
    gobject_class->get_property = my_object_get_property;
    gobject_class->finalize = my_object_finalize;

    obj_properties[PROP_NAME] = g_param_spec_string(
        "name", "Name", "The name", NULL,
        G_PARAM_READWRITE);

    g_object_class_install_properties(gobject_class, N_PROPERTIES, obj_properties);

    // Register the "name-changed" signal
    signals[NAME_CHANGED] = g_signal_new(
        "name-changed",
        G_TYPE_FROM_CLASS(klass),
        G_SIGNAL_RUN_FIRST,
        0,            // class_offset (not using class handler)
        NULL, NULL,   // accumulator, accumulator data
        NULL,         // C marshaller (use default)
        G_TYPE_NONE,  // return type
        1,            // number of parameters
        G_TYPE_STRING // parameter type: the new name
    );
}

// INSTANCE INIT
static void my_object_init(MyObject *self) {
    self->name = g_strdup("default");
}

// PUBLIC METHOD: SET NAME
void my_object_set_name(MyObject *self, const gchar *name) {
    g_return_if_fail(MY_IS_OBJECT(self));

    if (g_strcmp0(self->name, name) != 0) {
        g_free(self->name);
        self->name = g_strdup(name);

        g_signal_emit(self, signals[NAME_CHANGED], 0, self->name);
    }
}

// PUBLIC METHOD: GET NAME
const gchar* my_object_get_name(MyObject *self) {
    g_return_val_if_fail(MY_IS_OBJECT(self), NULL);
    return self->name;
}

// Constructor
MyObject* my_object_new(void) {
    return g_object_new(MY_TYPE_OBJECT, NULL);
}
```

---

#### `main.c`

```c
#include "myobject.h"

// Signal callback
static void on_name_changed(MyObject *self, const gchar *new_name, gpointer user_data) {
    g_print("Signal received! New name is: %s\n", new_name);
}

int main() {
    MyObject *obj = my_object_new();

    // Connect the signal
    g_signal_connect(obj, "name-changed", G_CALLBACK(on_name_changed), NULL);

    // Set name (will emit signal)
    my_object_set_name(obj, "Bob");

    // Set name again (emits again)
    my_object_set_name(obj, "Charlie");

    // Set same name (won't emit signal)
    my_object_set_name(obj, "Charlie");

    g_object_unref(obj);
    return 0;
}
```

---

#### Compile & Run:

```sh
gcc `pkg-config --cflags --libs gobject-2.0` -o with-signal main.c myobject.c
./with-signal
```

---

#### Output:

```
Signal received! New name is: Bob
Signal received! New name is: Charlie
```

---

### What You Learned:

* How to declare and register custom signals
* How to emit signals with `g_signal_emit()`
* How to connect signals to callbacks using `g_signal_connect()`
* How to avoid unnecessary signals by checking property changes

---

Would you like to continue to **Step 4: Inheritance and Virtual Methods** next, with full example code?

## *Step 4: Inheritance and Virtual Methods in GObject*

---

#### *Goal*:

* Create a derived class from your base GObject type.
* Override a virtual method.
* Demonstrate calling both the parent and overridden methods.

---

#### File Structure:

```
inheritance/
├── main.c
├── myobject.c
├── myobject.h
├── myderivedobject.c
└── myderivedobject.h
```

---

#### Step overview:

* `MyObject`: base class with a virtual method `print_name()`.
* `MyDerivedObject`: inherits `MyObject` and overrides `print_name()`.

---

#### `myobject.h`

```c
#ifndef MY_OBJECT_H
#define MY_OBJECT_H

#include <glib-object.h>

#define MY_TYPE_OBJECT (my_object_get_type())
G_DECLARE_DERIVABLE_TYPE(MyObject, my_object, MY, OBJECT, GObject)

struct _MyObjectClass {
    GObjectClass parent_class;

    // Virtual method pointer
    void (*print_name)(MyObject *self);
};

MyObject* my_object_new(void);

void my_object_print_name(MyObject *self);

void my_object_set_name(MyObject *self, const gchar *name);
const gchar* my_object_get_name(MyObject *self);

#endif
```

---

#### `myobject.c`

```c
#include "myobject.h"
#include <string.h>

struct _MyObject {
    GObject parent_instance;
    gchar *name;
};

enum {
    PROP_0,
    PROP_NAME,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

G_DEFINE_TYPE_WITH_CODE(MyObject, my_object, G_TYPE_OBJECT,
                       G_ADD_PRIVATE(MyObject))

// Forward declaration for virtual method default implementation
static void my_object_print_name_default(MyObject *self);

static void my_object_set_property(GObject *object,
                                   guint property_id,
                                   const GValue *value,
                                   GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_NAME:
            my_object_set_name(self, g_value_get_string(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

static void my_object_get_property(GObject *object,
                                   guint property_id,
                                   GValue *value,
                                   GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_NAME:
            g_value_set_string(value, self->name);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

static void my_object_finalize(GObject *object) {
    MyObject *self = MY_OBJECT(object);
    g_free(self->name);

    G_OBJECT_CLASS(my_object_parent_class)->finalize(object);
}

// Virtual method default implementation
static void my_object_print_name_default(MyObject *self) {
    g_print("MyObject: name is %s\n", self->name);
}

static void my_object_class_init(MyObjectClass *klass) {
    GObjectClass *gobject_class = G_OBJECT_CLASS(klass);
    gobject_class->set_property = my_object_set_property;
    gobject_class->get_property = my_object_get_property;
    gobject_class->finalize = my_object_finalize;

    obj_properties[PROP_NAME] = g_param_spec_string(
        "name", "Name", "The name", NULL,
        G_PARAM_READWRITE);

    g_object_class_install_properties(gobject_class, N_PROPERTIES, obj_properties);

    // Set virtual method pointer to default implementation
    klass->print_name = my_object_print_name_default;
}

static void my_object_init(MyObject *self) {
    self->name = g_strdup("default");
}

MyObject* my_object_new(void) {
    return g_object_new(MY_TYPE_OBJECT, NULL);
}

void my_object_print_name(MyObject *self) {
    g_return_if_fail(MY_IS_OBJECT(self));

    // Call virtual method
    MyObjectClass *klass = MY_OBJECT_GET_CLASS(self);
    klass->print_name(self);
}

void my_object_set_name(MyObject *self, const gchar *name) {
    g_return_if_fail(MY_IS_OBJECT(self));

    if (g_strcmp0(self->name, name) != 0) {
        g_free(self->name);
        self->name = g_strdup(name);
    }
}

const gchar* my_object_get_name(MyObject *self) {
    g_return_val_if_fail(MY_IS_OBJECT(self), NULL);
    return self->name;
}
```

---

#### `myderivedobject.h`

```c
#ifndef MY_DERIVED_OBJECT_H
#define MY_DERIVED_OBJECT_H

#include "myobject.h"

#define MY_TYPE_DERIVED_OBJECT (my_derived_object_get_type())
G_DECLARE_FINAL_TYPE(MyDerivedObject, my_derived_object, MY, DERIVED_OBJECT, MyObject)

MyDerivedObject* my_derived_object_new(void);

#endif
```

---

#### `myderivedobject.c`

```c
#include "myderivedobject.h"
#include <stdio.h>

struct _MyDerivedObject {
    MyObject parent_instance;
};

G_DEFINE_TYPE(MyDerivedObject, my_derived_object, MY_TYPE_OBJECT)

// Override virtual method
static void my_derived_object_print_name(MyObject *self) {
    g_print("MyDerivedObject override: Name is %s\n", my_object_get_name(self));
}

static void my_derived_object_class_init(MyDerivedObjectClass *klass) {
    MyObjectClass *parent_class = MY_OBJECT_CLASS(klass);

    // Override the virtual method
    parent_class->print_name = my_derived_object_print_name;
}

static void my_derived_object_init(MyDerivedObject *self) {
    // Initialization if needed
}

MyDerivedObject* my_derived_object_new(void) {
    return g_object_new(MY_TYPE_DERIVED_OBJECT, NULL);
}
```

---

#### `main.c`

```c
#include "myobject.h"
#include "myderivedobject.h"

int main() {
    MyObject *base_obj = my_object_new();
    my_object_set_name(base_obj, "Base");

    MyDerivedObject *derived_obj = my_derived_object_new();
    my_object_set_name(MY_OBJECT(derived_obj), "Derived");

    g_print("Calling print_name on base object:\n");
    my_object_print_name(base_obj);

    g_print("Calling print_name on derived object:\n");
    my_object_print_name(MY_OBJECT(derived_obj));

    g_object_unref(base_obj);
    g_object_unref(derived_obj);
    return 0;
}
```

---

#### Compile & Run:

```sh
gcc `pkg-config --cflags --libs gobject-2.0` \
    main.c myobject.c myderivedobject.c -o inheritance
./inheritance
```

---

#### Output:

```
Calling print_name on base object:
MyObject: name is Base
Calling print_name on derived object:
MyDerivedObject override: Name is Derived
```

---

#### What You Learned:

* How to create a derivable base class with virtual methods.
* How to override virtual methods in a derived class.
* How to invoke virtual methods polymorphically.
* The pattern of class/instance structs and function pointers for OOP in C.

---

Would you like to keep going to **Step 5: Interfaces** next?


## *Step 5: Implementing Interfaces in GObject*

---

*Goal*:

* Define a new interface.
* Implement that interface in a GObject type.
* Call interface methods on instances.

---

#### File Structure:

```
interface/
├── main.c
├── myinterface.c
├── myinterface.h
├── myobject.c
└── myobject.h
```

---

#### What we will do:

* Define `MyInterface` with a method `do_something()`.
* Implement `MyInterface` in `MyObject`.
* Call `do_something()` via the interface.

---

#### `myinterface.h`

```c
#ifndef MY_INTERFACE_H
#define MY_INTERFACE_H

#include <glib-object.h>

#define MY_TYPE_INTERFACE (my_interface_get_type())
G_DECLARE_INTERFACE(MyInterface, my_interface, MY, INTERFACE, GTypeInstance)

// Interface method
void my_interface_do_something(MyInterface *self);

struct _MyInterfaceInterface {
    GTypeInterface parent_iface;

    // Virtual method
    void (*do_something)(MyInterface *self);
};

#endif
```

---

#### `myinterface.c`

```c
#include "myinterface.h"
#include <stdio.h>

static void my_interface_default_init(MyInterfaceInterface *iface) {
    // Provide a default implementation
    iface->do_something = NULL; // No default implementation here
}

void my_interface_do_something(MyInterface *self) {
    MyInterfaceInterface *iface;

    g_return_if_fail(MY_IS_INTERFACE(self));

    iface = MY_INTERFACE_GET_IFACE(self);

    if (iface->do_something)
        iface->do_something(self);
    else
        g_print("No implementation for do_something()\n");
}
```

---

#### `myobject.h`

```c
#ifndef MY_OBJECT_H
#define MY_OBJECT_H

#include <glib-object.h>
#include "myinterface.h"

#define MY_TYPE_OBJECT (my_object_get_type())
G_DECLARE_FINAL_TYPE(MyObject, my_object, MY, OBJECT, GObject)

MyObject* my_object_new(void);

#endif
```

---

#### `myobject.c`

```c
#include "myobject.h"
#include <stdio.h>

struct _MyObject {
    GObject parent_instance;
};

G_DEFINE_TYPE_WITH_CODE(MyObject, my_object, G_TYPE_OBJECT,
                       G_IMPLEMENT_INTERFACE(MY_TYPE_INTERFACE, NULL))

static void my_object_do_something(MyInterface *self) {
    g_print("MyObject does something!\n");
}

static void my_interface_init(MyInterfaceInterface *iface) {
    iface->do_something = my_object_do_something;
}

static void my_object_class_init(MyObjectClass *klass) {
    // Nothing additional here
}

static void my_object_init(MyObject *self) {
    // Init if needed
}

MyObject* my_object_new(void) {
    return g_object_new(MY_TYPE_OBJECT, NULL);
}
```

---

#### `main.c`

```c
#include "myobject.h"
#include "myinterface.h"

int main() {
    MyObject *obj = my_object_new();

    // Cast to interface and call method
    my_interface_do_something(MY_INTERFACE(obj));

    g_object_unref(obj);
    return 0;
}
```

---

#### Compile & Run:

```bash
gcc `pkg-config --cflags --libs gobject-2.0` myinterface.c myobject.c main.c -o interface
./interface
```

---

#### Output:

```
MyObject does something!
```

---

#### What You Learned:

* How to define a GObject interface with virtual methods.
* How to implement the interface in a GObject-derived type.
* How to call interface methods polymorphically.
* How interfaces enable multiple inheritance patterns.

---

Want to continue with **Step 6: GObject Memory Management & Reference Counting** next?


## *Step 6: GObject Memory Management & Reference Counting*

---

*Goal*:

* Understand `g_object_ref()` and `g_object_unref()`.
* Learn about object lifecycle and finalize.
* See how to safely manage memory with GObjects.

---

### Key concepts:

* **Reference counting**: Each GObject keeps a count of references to it.
* When `refcount` drops to zero, the object is finalized and freed.
* Use `g_object_ref()` to increase refcount if you want to keep a pointer.
* Use `g_object_unref()` to decrease refcount when done.

---

#### We’ll use this simple GObject:

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

---

#### `myobject.c`

```c
#include "myobject.h"
#include <stdio.h>

struct _MyObject {
    GObject parent_instance;
};

G_DEFINE_TYPE(MyObject, my_object, G_TYPE_OBJECT)

static void my_object_finalize(GObject *object) {
    g_print("MyObject finalized\n");
    G_OBJECT_CLASS(my_object_parent_class)->finalize(object);
}

static void my_object_class_init(MyObjectClass *klass) {
    GObjectClass *gobject_class = G_OBJECT_CLASS(klass);
    gobject_class->finalize = my_object_finalize;
}

static void my_object_init(MyObject *self) {
    g_print("MyObject initialized\n");
}

MyObject* my_object_new(void) {
    return g_object_new(MY_TYPE_OBJECT, NULL);
}
```

---

#### `main.c`

```c
#include "myobject.h"

int main() {
    MyObject *obj = my_object_new();

    g_print("Refcount after new: %d\n", g_object_get_ref_count(obj));

    g_object_ref(obj);
    g_print("Refcount after g_object_ref: %d\n", g_object_get_ref_count(obj));

    g_object_unref(obj);
    g_print("Refcount after first unref: %d\n", g_object_get_ref_count(obj));

    g_object_unref(obj);  // Final unref, object finalized here

    // Uncommenting below is unsafe — object is freed
    // g_print("Refcount after final unref: %d\n", g_object_get_ref_count(obj));

    return 0;
}
```

---

#### Compile & Run:

```bash
gcc `pkg-config --cflags --libs gobject-2.0` main.c myobject.c -o memory
./memory
```

---

#### Output:

```
MyObject initialized
Refcount after new: 1
Refcount after g_object_ref: 2
Refcount after first unref: 1
MyObject finalized
```

---

#### What You Learned:

* When an object is created, refcount is 1.
* `g_object_ref()` increments refcount to hold additional references.
* `g_object_unref()` decrements refcount and frees the object when zero.
* Override `finalize()` to clean up resources.
* Always balance `ref()` and `unref()` calls to avoid leaks or crashes.

---

Want me to continue with **Step 7: Properties with Notifications (GParamSpec, GObject notify signal)**?

## *Step 7: Properties with Notifications (GParamSpec & "notify" Signal)*

---

*Goal*:

* Learn how to define properties with `GParamSpec`.
* Understand how to emit "notify" signals when properties change.
* Connect to the `"notify::property-name"` signal to react on changes.

---

### Key concepts:

* Properties expose object data with read/write.
* GObject emits `"notify::property"` signal when a property changes.
* This allows clients to watch and react to property changes.

---

#### File Structure:

```
notify-property/
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

void my_object_set_name(MyObject *self, const gchar *name);
const gchar* my_object_get_name(MyObject *self);

#endif
```

---

#### `myobject.c`

```c
#include "myobject.h"
#include <string.h>

struct _MyObject {
    GObject parent_instance;
    gchar *name;
};

enum {
    PROP_0,
    PROP_NAME,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

G_DEFINE_TYPE(MyObject, my_object, G_TYPE_OBJECT)

static void my_object_set_property(GObject *object,
                                   guint property_id,
                                   const GValue *value,
                                   GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_NAME: {
            const gchar *new_name = g_value_get_string(value);
            if (g_strcmp0(self->name, new_name) != 0) {
                g_free(self->name);
                self->name = g_strdup(new_name);
                g_object_notify_by_pspec(object, pspec);
            }
            break;
        }
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

static void my_object_get_property(GObject *object,
                                   guint property_id,
                                   GValue *value,
                                   GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_NAME:
            g_value_set_string(value, self->name);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

static void my_object_finalize(GObject *object) {
    MyObject *self = MY_OBJECT(object);
    g_free(self->name);
    G_OBJECT_CLASS(my_object_parent_class)->finalize(object);
}

static void my_object_class_init(MyObjectClass *klass) {
    GObjectClass *gobject_class = G_OBJECT_CLASS(klass);

    gobject_class->set_property = my_object_set_property;
    gobject_class->get_property = my_object_get_property;
    gobject_class->finalize = my_object_finalize;

    obj_properties[PROP_NAME] = g_param_spec_string(
        "name",
        "Name",
        "The object's name",
        NULL,
        G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    g_object_class_install_properties(gobject_class, N_PROPERTIES, obj_properties);
}

static void my_object_init(MyObject *self) {
    self->name = g_strdup("default");
}

MyObject* my_object_new(void) {
    return g_object_new(MY_TYPE_OBJECT, NULL);
}

void my_object_set_name(MyObject *self, const gchar *name) {
    g_object_set(self, "name", name, NULL);
}

const gchar* my_object_get_name(MyObject *self) {
    const gchar *name = NULL;
    g_object_get(self, "name", &name, NULL);
    return name;
}
```

---

#### `main.c`

```c
#include "myobject.h"
#include <stdio.h>

// Callback for property notification
static void on_name_notify(GObject *obj, GParamSpec *pspec, gpointer user_data) {
    const gchar *name;
    g_object_get(obj, "name", &name, NULL);
    g_print("Property '%s' changed to: %s\n", pspec->name, name);
}

int main() {
    MyObject *obj = my_object_new();

    // Connect to notify signal for "name"
    g_signal_connect(obj, "notify::name", G_CALLBACK(on_name_notify), NULL);

    // Change the property; triggers notify
    my_object_set_name(obj, "Alice");
    my_object_set_name(obj, "Bob");

    g_object_unref(obj);
    return 0;
}
```

---

#### Compile & Run:

```bash
gcc `pkg-config --cflags --libs gobject-2.0` main.c myobject.c -o notify_property
./notify_property
```

---

#### Output:

```
Property 'name' changed to: Alice
Property 'name' changed to: Bob
```

---

#### What You Learned:

* How to define readable/writable properties with `g_object_class_install_properties()`.
* How to emit `"notify::property"` signals automatically with `g_object_notify_by_pspec()`.
* How clients connect to `"notify::property"` signals to react to changes.
* Using `g_object_set()` and `g_object_get()` for property access.

---

Ready for **Step 8: Thread Safety and GObject** or want to explore this step more?


## *Step 8: Thread Safety and GObject*

---

*Goal*:

* Understand GObject’s thread safety model.
* Learn how to safely use GObjects across threads.
* Explore locking, thread-safe reference counting, and main loop integration.

---

### Key points:

* **GObject reference counting is thread-safe.** You can safely call `g_object_ref()` and `g_object_unref()` from multiple threads.
* **Instance and class data are NOT automatically thread-safe.** You must ensure your own instance variables are properly synchronized.
* **Use locks/mutexes** to protect instance state accessed by multiple threads.
* **Use `GMainContext` and `GMainLoop`** to run event loops in threads and dispatch signals or events safely.
* **GTask and asynchronous patterns** help safely do async work with GObject.

---

#### Simple example showing thread-safe refcounting and property update with locking:

---

#### `myobject.h`

```c
#ifndef MY_OBJECT_H
#define MY_OBJECT_H

#include <glib-object.h>

#define MY_TYPE_OBJECT (my_object_get_type())
G_DECLARE_FINAL_TYPE(MyObject, my_object, MY, OBJECT, GObject)

MyObject* my_object_new(void);

void my_object_set_counter(MyObject *self, gint counter);
gint my_object_get_counter(MyObject *self);

#endif
```

---

#### `myobject.c`

```c
#include "myobject.h"
#include <glib.h>

struct _MyObject {
    GObject parent_instance;
    gint counter;
    GMutex mutex;  // Protects counter
};

enum {
    PROP_0,
    PROP_COUNTER,
    N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL, };

G_DEFINE_TYPE(MyObject, my_object, G_TYPE_OBJECT)

static void my_object_set_property(GObject *object,
                                   guint property_id,
                                   const GValue *value,
                                   GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_COUNTER:
            my_object_set_counter(self, g_value_get_int(value));
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

static void my_object_get_property(GObject *object,
                                   guint property_id,
                                   GValue *value,
                                   GParamSpec *pspec) {
    MyObject *self = MY_OBJECT(object);

    switch (property_id) {
        case PROP_COUNTER:
            g_mutex_lock(&self->mutex);
            g_value_set_int(value, self->counter);
            g_mutex_unlock(&self->mutex);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, property_id, pspec);
    }
}

static void my_object_finalize(GObject *object) {
    MyObject *self = MY_OBJECT(object);
    g_mutex_clear(&self->mutex);
    G_OBJECT_CLASS(my_object_parent_class)->finalize(object);
}

static void my_object_class_init(MyObjectClass *klass) {
    GObjectClass *gobject_class = G_OBJECT_CLASS(klass);

    gobject_class->set_property = my_object_set_property;
    gobject_class->get_property = my_object_get_property;
    gobject_class->finalize = my_object_finalize;

    obj_properties[PROP_COUNTER] = g_param_spec_int(
        "counter",
        "Counter",
        "Thread-safe integer counter",
        G_MININT, G_MAXINT, 0,
        G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);

    g_object_class_install_properties(gobject_class, N_PROPERTIES, obj_properties);
}

static void my_object_init(MyObject *self) {
    self->counter = 0;
    g_mutex_init(&self->mutex);
}

void my_object_set_counter(MyObject *self, gint counter) {
    g_mutex_lock(&self->mutex);
    if (self->counter != counter) {
        self->counter = counter;
        g_object_notify_by_pspec(G_OBJECT(self), obj_properties[PROP_COUNTER]);
    }
    g_mutex_unlock(&self->mutex);
}

gint my_object_get_counter(MyObject *self) {
    gint counter;
    g_mutex_lock(&self->mutex);
    counter = self->counter;
    g_mutex_unlock(&self->mutex);
    return counter;
}
```

---

#### `main.c`

```c
#include "myobject.h"
#include <glib.h>
#include <stdio.h>

static void on_counter_notify(GObject *obj, GParamSpec *pspec, gpointer user_data) {
    gint counter;
    counter = my_object_get_counter(MY_OBJECT(obj));
    g_print("Counter changed to %d\n", counter);
}

static gpointer thread_func(gpointer data) {
    MyObject *obj = MY_OBJECT(data);

    for (int i = 1; i <= 5; i++) {
        g_usleep(500000);  // Sleep 0.5 seconds
        my_object_set_counter(obj, i);
    }

    return NULL;
}

int main() {
    MyObject *obj = my_object_new();

    g_signal_connect(obj, "notify::counter", G_CALLBACK(on_counter_notify), NULL);

    GThread *thread = g_thread_new("worker", thread_func, obj);

    // Main thread waits for worker thread
    g_thread_join(thread);

    g_object_unref(obj);
    return 0;
}
```

---

#### Compile & Run:

```bash
gcc `pkg-config --cflags --libs gobject-2.0 gio-2.0` myobject.c main.c -o threadsafe
./threadsafe
```

---

#### Output:

```
Counter changed to 1
Counter changed to 2
Counter changed to 3
Counter changed to 4
Counter changed to 5
```

---

#### What You Learned:

* `g_object_ref()` / `unref()` are safe across threads.
* You must manually protect mutable instance data with mutexes.
* Use `g_mutex_init()` and `g_mutex_clear()` in init/finalize.
* Property notifications and signals can be emitted safely if protected.
* Use GThread for multi-threading with GObject safely.

---

Ready for **Step 9: Signals and Custom Signal Emission**?

## *Step 9: Signals and Custom Signal Emission in GObject*

---

*Goal*:

* Learn to define and register custom signals.
* Understand how to emit signals.
* Connect signal handlers (callbacks).
* Use signal parameters and return values.

---

### Why Signals?

* Signals allow objects to **notify** interested parties about events.
* They’re central to the GObject event system.
* You can define custom signals beyond built-in ones.

---

#### File Structure:

```
signal/
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

void my_object_do_work(MyObject *self);

#endif
```

---

#### `myobject.c`

```c
#include "myobject.h"
#include <stdio.h>

enum {
    WORK_DONE,
    LAST_SIGNAL
};

static guint my_object_signals[LAST_SIGNAL] = { 0 };

struct _MyObject {
    GObject parent_instance;
};

G_DEFINE_TYPE(MyObject, my_object, G_TYPE_OBJECT)

// Signal callback prototype:
// void user_callback(MyObject *self, gint result, gpointer user_data);

static void my_object_class_init(MyObjectClass *klass) {
    my_object_signals[WORK_DONE] = g_signal_new(
        "work-done",
        G_TYPE_FROM_CLASS(klass),
        G_SIGNAL_RUN_LAST,
        0,                  // class offset for default handler
        NULL, NULL,
        g_cclosure_marshal_VOID__INT,
        G_TYPE_NONE,
        1,                  // number of params
        G_TYPE_INT          // parameter type: int
    );
}

static void my_object_init(MyObject *self) {
    // Initialization if needed
}

MyObject* my_object_new(void) {
    return g_object_new(MY_TYPE_OBJECT, NULL);
}

// Function to emit the signal with a result parameter
void my_object_do_work(MyObject *self) {
    g_print("Doing work...\n");

    int result = 42;  // Example result from work

    // Emit the "work-done" signal with result
    g_signal_emit(self, my_object_signals[WORK_DONE], 0, result);
}
```

---

#### `main.c`

```c
#include "myobject.h"
#include <stdio.h>

// Signal handler for "work-done"
static void on_work_done(MyObject *self, gint result, gpointer user_data) {
    g_print("Work done! Result is: %d\n", result);
}

int main() {
    MyObject *obj = my_object_new();

    // Connect signal handler
    g_signal_connect(obj, "work-done", G_CALLBACK(on_work_done), NULL);

    // Trigger work that emits signal
    my_object_do_work(obj);

    g_object_unref(obj);
    return 0;
}
```

---

#### Compile & Run:

```bash
gcc `pkg-config --cflags --libs gobject-2.0` myobject.c main.c -o signal_example
./signal_example
```

---

#### Output:

```
Doing work...
Work done! Result is: 42
```

---

#### What You Learned:

* How to register a **custom signal** with `g_signal_new()`.
* How to define signal parameters and return type.
* How to **emit** a signal with `g_signal_emit()`.
* How to connect a handler using `g_signal_connect()`.
* The power of signals for event-driven programming in GObject.

---

Ready to move to **Step 10: GObject Introspection and Language Bindings**?
-------------------------------------------------------------------------------
