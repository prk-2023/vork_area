#gcc check_rx_offload.c -o check_rx_offload \
 #   $(pkg-config --cflags --libs libdpdk)


#echo "sudo ./check_rx_offload -l 0-3 -n 4"


gcc rx_split_test.c -o rx_split_test \
$(pkg-config --cflags --libs libdpdk)

echo "sudo ./rx_split_test -l 0-3 -n 4"
