#ifndef MY_OBJECT_H
#define MY_OBJECT_H

#include <glib-object.h>

#define MY_TYPE_OBJECT (my_object_get_type())
G_DECLARE_FINAL_TYPE(MyObject, my_object, MY, OBJECT, GObject)

MyObject* my_object_new(void);

#endif
