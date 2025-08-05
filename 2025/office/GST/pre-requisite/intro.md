# GStreamer 


## Introduction:

GStreamer, the multi-platform, modular, open-source, media streaming framework.

Step1: setup the development env 
( install the source-code by checking out or use dnf to install the related devel packages )

Step2: Gstremar tutorials are written in C, But framework used GObject allowing to leverage Object oriented features to it. 
Note Knowledge of GObject and GLib is not mandatory but it will make learning GStreamer easy.

Where 
1. GLib: This library provides many wide range of essential data structures, algos, and low-level functionality:
    - Core Data structures: linklists ( GList ), hash tables ( GHashTable ), and arrays (GArray) for managing its internal components.
    - Main Loop: GLib provides main loop ( GMailLoop ), which is crucial for event driven programming. This is used by Gstremar for events, signals, and timers in a signal, efficient loop, which is essential for multimedia applications.
    - Memory Management : GLib offers portable and robust memory allocation functions.
    - Threading and Synchronization: GLib's thread primitives ( like GMutex, and GThread ) are used by Gstremar for managing concurrency and ensuring thread-safe access to shared resources, which are vital in a multi-threaded media processing env.

2. GObject: This is a GLib Object system. It provides portable OO framework for the C programming language, which is primary lang for Gstremar's core lib's. GStreamer leverages GObject for:
    - OO Design: GObject provides the core OO principles, including single inheritance, polymorphism, and dynamic typing. All *GStreamer components, such as elements (GstElement), pads (GstPad), and objects (GstObject), are GObjects*. This allows for a clean, hierarchical, and extensible design.
    - Dynamic Type System (GType): 
        GObject's type system, known as GType, is a powerful feature that allows for a runtime description of all objects. This enables GStreamer to:
        1. Create and Manage Objects: Takes care of the creation, initialization, and memory management of objects and their class structures.
        2. Plugin Architecture: The GType system is a cornerstone of GStreamer's plugin architecture. It allows the framework to dynamically load and unload plugins at runtime, and to register new object types from those plugins.
        3. Language Bindings: The dynamic type information is what makes GStreamer's APIs transparently accessible from other programming languages like Python, Rust, and JavaScript through introspection.
    - Properties: GObject provides a standardized mechanism for defining and accessing object properties. GStreamer elements use this to expose customizable parameters (Ex : a file source element's "uri" property) that can be easily set and retrieved.
    - Signals and Callbacks: GObject provides a robust signal/callback mechanism. This is a fundamental communication method in GStreamer, allowing elements to emit signals (e.g., an error or a state change) and other parts of the application to connect to these signals to react to events.

The knowledge of GLib , GObjects help in  learning GStreamer more smooth. Since GStreamer is built on top of GObjects( for OO ) and GLib ( for common algos ) libraries, this means that we have to call functions form these libraries. 

Convention: The Framework source uses a prefix "gst_" to tell which library you are calling all GStreamer functions, structures types. And a "g_" prefix for GObjects and GLib.

## The Foundation: An Introduction to GLib and GObject

Before diving into the specifics of how they are used in GStreamer, it's essential to understand GLib and GObject in their own right. They form the foundational layers of a vast ecosystem of software, most notably the GNOME desktop environment.

### GLib: The "C" Utility Library

GLib is a general-purpose, cross-platform utility library written in C. It's often referred to as the "C utility library" because it provides a comprehensive set of portable, high-level functionalities that are missing from the standard C library. Its primary goal is to make C programming easier and more robust, especially for building complex applications.

#### History and Purpose
GLib's history is intertwined with the development of the GNOME project. In the late 1990s, GNOME developers realized they needed a common set of tools and data structures to build their desktop environment. They needed a library that could handle things like main loops for event handling, a consistent memory management API, and efficient data structures. GLib was born out of this need. It's designed to be:

* **Portable:** It works on various operating systems, including Linux, Windows, macOS, and others.
* **Efficient:** The data structures and algorithms are optimized for performance.
* **Thread-safe:** Many of its functions and data structures are designed to be used safely in multi-threaded environments.

#### Examples of GLib's Features
* **Data Structures:** GLib provides a rich set of data structures that are more flexible and powerful than their C standard library counterparts.
    * `GList`: A doubly-linked list.
    * `GSList`: A singly-linked list.
    * `GHashTable`: A hash table for key-value pairs.
    * `GQueue`: A queue.
* **Main Loop:** The `GMainLoop` is a central concept in event-driven applications. It allows an application to wait for and dispatch events from various sources, such as I/O, timers, and signals.
* **String Utilities:** It has functions for manipulating strings, including a flexible string builder (`GString`).
* **File I/O and System Utilities:** GLib provides a portable way to interact with the file system, manage processes, and handle environment variables.

---
### GObject: The Object System for C

GObject is the Object System for GLib. It's an object-oriented framework that provides a way to write reusable, extensible, and type-safe code in C. GObject essentially adds object-oriented features like inheritance, polymorphism, and a dynamic type system to C.

#### History and Purpose
The need for GObject arose from the need to organize the growing number of widgets and components in the GTK+ toolkit (the toolkit used by GNOME). Building complex user interfaces requires an object-oriented approach to manage the state and behavior of various graphical elements. GObject provides the foundation for this. It’s designed to be:

* **Extensible:** It allows new types of objects to be defined and registered at runtime.
* **Language-agnostic:** Because of its powerful introspection capabilities, it can be easily integrated with other programming languages, enabling language bindings.
* **Type-safe:** The dynamic type system ensures that you are always working with the correct type of object.

#### Examples of GObject's Features
* **`GType` - The Type System:** At the heart of GObject is the `GType` system. Every GObject has a `GType` ID that uniquely identifies its class. This type system is dynamic and allows for runtime type checking, which is a powerful feature for plugin-based architectures and language bindings.
* **Object Properties:** GObject provides a standardized way to define properties for an object. These properties can be set and retrieved by name. This is a crucial feature for configuration and for tools that need to inspect an object's state.
* **Signals:** The GObject signal system is a powerful way for objects to communicate with each other. An object can "emit" a signal when something interesting happens (e.g., a button is clicked), and other objects can "connect" to that signal to be notified and run a callback function.
* **Inheritance:** GObject provides a single-inheritance model. A new object can "inherit" from an existing one, gaining its properties and methods, and then extending them. For example, a `GtkButton` inherits from `GtkWidget`, which in turn inherits from `GObject`.

---

### Tying it all together: GStreamer's Usage

Now that you have a solid understanding of GLib and GObject, their role in GStreamer becomes much clearer.

* **GLib provides the essential plumbing:** It gives GStreamer the core data structures, threading tools, and event loop that are needed to build a complex, multi-threaded multimedia framework.
* **GObject provides the core architecture:** All of GStreamer's fundamental components—elements, pads, bins, and more—are GObjects. The object-oriented model allows for a clean hierarchy, while the `GType` system is what makes GStreamer's dynamic plugin system possible. The properties, signals, and methods defined through GObject are how a GStreamer pipeline is built, configured, and controlled.

## Code examples

Code examples are the best way to solidify an understanding of these concepts. Let's walk through some simple C programs that demonstrate the core functionalities of GLib and GObject.

### Setting up the environment

To compile these examples, you'll need the GLib development headers and libraries. On a Debian/Ubuntu system, you can install them with:

```bash
sudo apt-get install libglib2.0-dev
```

You'll then compile with `pkg-config` to automatically get the correct compiler flags. The command will look like this:

```bash
gcc -o my_program my_program.c $(pkg-config --cflags --libs glib-2.0)
```

-----

### Example 1: GLib's Main Loop and Timers

This program demonstrates the fundamental event-driven nature of GLib applications. The `GMainLoop` runs continuously, waiting for events. In this case, we add a timer that will trigger a function after a certain amount of time.

```c
#include <glib.h>
#include <stdio.h>

// This function will be called by the timer.
gboolean timer_callback(gpointer data) {
    g_print("Timer triggered! The 'data' pointer is: %s\n", (char*)data);

    // This is a one-shot timer. To stop the main loop, we need to quit it.
    GMainLoop *loop = (GMainLoop*)data;
    g_main_loop_quit(loop);

    // Returning FALSE means this source will not be called again.
    return FALSE;
}

int main(int argc, char *argv[]) {
    // 1. Create a new main loop.
    GMainLoop *loop = g_main_loop_new(NULL, FALSE);

    g_print("Starting the GLib main loop. This will run for 3 seconds.\n");

    // 2. Add a timeout source to the loop.
    // The timer_callback function will be called after 3000 milliseconds (3 seconds).
    // The last argument is user data, which we'll use to pass the main loop itself.
    g_timeout_add(3000, timer_callback, loop);

    // 3. Run the main loop. This function will block until g_main_loop_quit() is called.
    g_main_loop_run(loop);

    g_print("Main loop has quit. Program is exiting.\n");

    // 4. Clean up.
    g_main_loop_unref(loop);

    return 0;
}
```

**Explanation:**

  * The `g_main_loop_new()` function creates an instance of the event loop.
  * `g_timeout_add()` adds a timed event source to the loop. It takes a timeout in milliseconds, a function to call, and some user data to pass to that function.
  * `g_main_loop_run()` starts the loop, which will now wait for events (in this case, just our timer).
  * The `timer_callback` function is executed after 3 seconds. It prints a message and then calls `g_main_loop_quit()`, which signals the loop to stop running.
  * `g_main_loop_unref()` is called to free the memory associated with the loop.

-----

### Example 2: Creating a Simple GObject with Properties and Signals

This is a more complex example that shows how to define your own object type using GObject, complete with properties and a signal.

First, the header file (`my_object.h`):

```c
#ifndef __MY_OBJECT_H__
#define __MY_OBJECT_H__

#include <glib-object.h>

G_BEGIN_DECLS

#define MY_TYPE_OBJECT (my_object_get_type())
G_DECLARE_FINAL_TYPE(MyObject, my_object, MY, OBJECT, GObject)

// Our public method
void my_object_do_something(MyObject *self);

G_END_DECLS

#endif /* __MY_OBJECT_H__ */
```

Next, the implementation file (`my_object.c`):

```c
#include "my_object.h"
#include <stdio.h>

// A unique ID for our property.
enum {
    PROP_0,
    PROP_MESSAGE
};

// A unique ID for our signal.
enum {
    SIGNAL_SOMETHING_HAPPENED,
    N_SIGNALS
};

static guint my_object_signals[N_SIGNALS] = { 0 };

G_DEFINE_FINAL_TYPE(MyObject, my_object, G_TYPE_OBJECT);

// Private data for our object
typedef struct {
    gchar *message;
} MyObjectPrivate;

#define MY_OBJECT_GET_PRIVATE(o) \
    (G_TYPE_INSTANCE_GET_PRIVATE((o), MY_TYPE_OBJECT, MyObjectPrivate))

// A property setter function.
static void my_object_set_property(GObject *object, guint prop_id, const GValue *value, GParamSpec *pspec) {
    MyObjectPrivate *priv = MY_OBJECT_GET_PRIVATE(object);

    switch (prop_id) {
        case PROP_MESSAGE:
            g_free(priv->message);
            priv->message = g_value_dup_string(value);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
            break;
    }
}

// A property getter function.
static void my_object_get_property(GObject *object, guint prop_id, GValue *value, GParamSpec *pspec) {
    MyObjectPrivate *priv = MY_OBJECT_GET_PRIVATE(object);

    switch (prop_id) {
        case PROP_MESSAGE:
            g_value_set_string(value, priv->message);
            break;
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID(object, prop_id, pspec);
            break;
    }
}

// Our object's constructor-like function.
static void my_object_init(MyObject *self) {
    MyObjectPrivate *priv = MY_OBJECT_GET_PRIVATE(self);
    priv->message = g_strdup("Hello from GObject!");
}

// Our object's destructor-like function.
static void my_object_dispose(GObject *gobject) {
    MyObjectPrivate *priv = MY_OBJECT_GET_PRIVATE(gobject);

    g_free(priv->message);
    priv->message = NULL;

    G_OBJECT_CLASS(my_object_parent_class)->dispose(gobject);
}

// The class initialization function. This is where we register properties and signals.
static void my_object_class_init(MyObjectClass *klass) {
    GObjectClass *gobject_class = G_OBJECT_CLASS(klass);
    gobject_class->set_property = my_object_set_property;
    gobject_class->get_property = my_object_get_property;
    gobject_class->dispose = my_object_dispose;

    // Register a property
    g_object_class_install_property(
        gobject_class,
        PROP_MESSAGE,
        g_param_spec_string("message", "Message", "A message string.",
                            "default message", G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS)
    );

    // Register a signal
    my_object_signals[SIGNAL_SOMETHING_HAPPENED] = g_signal_new("something-happened",
                                                               MY_TYPE_OBJECT,
                                                               G_SIGNAL_RUN_LAST,
                                                               0,
                                                               NULL,
                                                               NULL,
                                                               g_cclosure_marshal_VOID__VOID,
                                                               G_TYPE_NONE,
                                                               0);
}

// Our public method implementation.
void my_object_do_something(MyObject *self) {
    MyObjectPrivate *priv = MY_OBJECT_GET_PRIVATE(self);
    g_print("MyObject is doing something. Its message is: %s\n", priv->message);

    // Emit the signal to notify others that something happened.
    g_signal_emit(self, my_object_signals[SIGNAL_SOMETHING_HAPPENED], 0);
}
```

Finally, a `main.c` to use our custom GObject:

```c
#include "my_object.h"
#include <stdio.h>

// A signal handler function.
void on_something_happened(MyObject *obj, gpointer user_data) {
    g_print("Signal received: Something happened to the object!\n");
}

int main(int argc, char *argv[]) {
    // GObject requires g_type_init() to be called.
    // In modern GLib, this is done automatically.
    // g_type_init();

    // Create a new instance of our custom GObject.
    MyObject *my_obj = g_object_new(MY_TYPE_OBJECT, "message", "My custom object message!", NULL);

    // Connect our signal handler to the "something-happened" signal.
    g_signal_connect(my_obj, "something-happened", G_CALLBACK(on_something_happened), NULL);

    // Call a method on our object.
    my_object_do_something(my_obj);

    // Get a property value from our object.
    gchar *current_message = NULL;
    g_object_get(my_obj, "message", &current_message, NULL);
    g_print("Got the message from the object: %s\n", current_message);
    g_free(current_message);

    // Clean up our object.
    g_object_unref(my_obj);

    return 0;
}
```

To compile this example, you would need to compile the two `.c` files together:

```bash
gcc -o my_app my_object.c main.c $(pkg-config --cflags --libs glib-2.0 gobject-2.0)
```

**Explanation:**

  * The `G_DECLARE_FINAL_TYPE` and `G_DEFINE_FINAL_TYPE` macros are modern conveniences that handle much of the boilerplate needed to define a new GObject type.
  * `my_object_class_init` is the crucial part where we define the behavior of our class. We register a string property named "message" and a signal named "something-happened".
  * `g_object_new()` is the GObject way of creating a new instance. We can pass property values directly to it.
  * `g_signal_connect()` is used to connect a function (`on_something_happened`) to a signal (`something-happened`) on our object instance.
  * `g_signal_emit()` is how an object broadcasts that a signal has occurred.
  * `g_object_get()` and `g_object_set()` (not shown in this example, but used by the setter) are the standard ways to interact with object properties.
  * `g_object_unref()` is used to decrease the reference count of the object. When the count reaches zero, the object is automatically finalized and its memory is freed.

These examples illustrate the key roles GLib and GObject play in providing a solid foundation for applications. GLib handles the low-level utilities and event-driven architecture, while GObject builds on that to provide a full-featured, dynamic, and extensible object system. GStreamer takes these very concepts and applies them to the domain of multimedia processing.


## Jump Start to GStreamer development :


The examples are a good starting point for jumping into GStreamer development, but with some important caveats and next steps.

GStreamer is built **on top of GLib**, and it heavily uses:

| Concept            | Used in Your Examples? | GStreamer Uses It? | Notes                                                                 |
| ------------------ | ---------------------- | ------------------ | --------------------------------------------------------------------- |
| `GMainLoop`        | ✅ Yes                  | ✅ Yes              | Core to event-driven design in GStreamer (e.g., for message handling) |
| `g_timeout_add()`  | ✅ Yes                  | ✅ Yes              | GStreamer also adds bus watch functions (like `gst_bus_add_watch()`)  |
| `GThread`          | ✅ Yes                  | ✅ Yes              | GStreamer pipelines may involve background threads                    |
| `GMutex`, `GCond`  | ✅ Yes                  | ✅ Internally       | Not required to use directly, but knowing them helps                  |
| State handling     | ✅ Yes (ping/pong)      | ✅ Yes              | GStreamer has pipeline state changes (READY → PAUSED → PLAYING)       |
| Event-driven logic | ✅ Yes                  | ✅ Yes              | The whole message bus and pipeline lifecycle is event-driven          |

So you're already **familiarizing yourself with the GLib runtime model** — which is exactly what GStreamer builds on.

---

## What to Learn Next to Dive into GStreamer

Here’s how you can layer GStreamer knowledge **on top of** what you've done:

---

### 1. **Understand the GStreamer Pipeline Model**

```c
GstElement *pipeline = gst_parse_launch("videotestsrc ! autovideosink", NULL);
```

* Each pipeline is a set of connected elements.
* Pipelines run asynchronously.
* Events are reported via a **message bus**, just like your `GMainLoop` event model.

---

### 2. **Use `GMainLoop` with `GstBus`**

In your examples, you used `g_timeout_add()`.

In GStreamer, instead, you'll do:

```c
GstBus *bus = gst_element_get_bus(pipeline);
gst_bus_add_watch(bus, (GstBusFunc)bus_call, loop);
```

And the `bus_call` callback gets messages (EOS, errors, state changes) just like your timeout handler.

---

### 3. **Compile with `pkg-config`**

You’ll add `gstreamer-1.0` to your compile line:

```sh
gcc your_program.c `pkg-config --cflags --libs gstreamer-1.0`
```

Same as how you’d compile a GLib-based program.

---

### 4. **Thread Awareness**

You used threads in the ping-pong example. GStreamer internally uses threads to run pipelines and elements in parallel. Your awareness of race conditions, mutexes, and `g_usleep()` already gives you a big leg up.

---

## Sample Minimal GStreamer Program

Here’s a super-short GStreamer example to build next:

```c
#include <gst/gst.h>

int main(int argc, char *argv[]) {
    GstElement *pipeline;
    GstBus *bus;
    GstMessage *msg;

    gst_init(&argc, &argv);

    pipeline = gst_parse_launch("videotestsrc ! autovideosink", NULL);

    gst_element_set_state(pipeline, GST_STATE_PLAYING);

    bus = gst_element_get_bus(pipeline);
    msg = gst_bus_timed_pop_filtered(bus, GST_CLOCK_TIME_NONE,
                                     GST_MESSAGE_ERROR | GST_MESSAGE_EOS);

    if (msg != NULL)
        gst_message_unref(msg);

    gst_object_unref(bus);
    gst_element_set_state(pipeline, GST_STATE_NULL);
    gst_object_unref(pipeline);

    return 0;
}
```

---

## TL;DR:

Yes — your GLib examples are absolutely a solid foundation for GStreamer development. You're already comfortable with:

* GLib main loop
* Event-driven architecture
* Multithreading basics
* GLib build and runtime patterns

Now you're ready to explore:

* `gst_parse_launch()`
* Pipeline states
* Bus messages
* Media I/O

