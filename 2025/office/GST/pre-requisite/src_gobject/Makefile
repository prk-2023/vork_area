
CFLAGS =  `pkg-config --cflags --libs gobject-2.0` -Wall -Wextra
#CFLAGS := `pkg-config --cflags --libs glib-2.0` -Wall -Wextra
all:
	gcc -o myapp myobject.c main.c $(CFLAGS)

clean:
	rm -f myapp
