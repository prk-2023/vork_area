
CFLAGS =  `pkg-config --cflags --libs gobject-2.0` -Wall -Wextra
#CFLAGS := `pkg-config --cflags --libs glib-2.0` -Wall -Wextra
all:
	gcc -o ex1 myobject.c main.c $(CFLAGS)

run: all
	./ex1

clean:
	rm -f ex1
