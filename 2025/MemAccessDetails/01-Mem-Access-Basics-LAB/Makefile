CC = gcc
CFLAGS = -Wall -O2
DBGFLAGS = -g -O0

TARGETS = lesson1_memcpy lesson2_stack_heap lesson3_mmio lesson4_cache lesson5_alignment bonus_struct_padding

all: $(TARGETS)

debug: CFLAGS=$(DBGFLAGS)
debug: $(TARGETS)

%: %.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(TARGETS)

