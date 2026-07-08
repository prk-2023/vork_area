CFLAGS += $(shell pkg-config --cflags libdpdk)
LDFLAGS += $(shell pkg-config --libs libdpdk)


all:
	gcc check_rx_offload.c -o check_rx_offload $(CFLAGS) $(LDFLAGS)
	gcc rx_split_test.c -o rx_split_test $(CFLAGS) $(LDFLAGS)

clean:
	rm -f rx_split_test check_rx_offload 

run:
	echo "sudo ./check_rx_offload -l 0-3 -n 4"
	echo "sudo ./rx_split_test -l 0-3 -n 4"
