#ifndef MYOBJECT_H
#define MYOBJECT_H

#include <glib-object.h>

#define MY_TYPE_OBJECT (my_object_get_type())

//G_DECLARE_FINAL_TYPE :A modern convention that handle much of the boilerplate needed to def GObject type.
G_DECLARE_FINAL_TYPE(MyObject, my_object, MY, OBJECT, GObject)

// Public API
void my_object_greet(MyObject *self);

#endif // MYOBJECT_H
