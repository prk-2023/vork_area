CFLAGS := `pkg-config --cflags --libs glib-2.0` -Wall -Wextra
SOURCES = $(wildcard glib_*.c)
PROGRAMS = $(patsubst %.c,%,$(SOURCES))

#COMMON_OBJ = util.o

all: $(PROGRAMS)

%: %.o $(COMMON_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o $(PROGRAMS)

.PHONY: all clean
