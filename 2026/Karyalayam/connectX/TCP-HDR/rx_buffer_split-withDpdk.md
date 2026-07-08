$ sudo sysctl -w vm.nr_hugepages=1024
vm.nr_hugepages = 1024


sudo dpdk-testpmd -l 0-3 -n 4 -- -i --port-topology=paired
EAL: Detected CPU lcores: 12
EAL: Detected NUMA nodes: 1
EAL: Detected shared linkage of DPDK
EAL: Multi-process socket /var/run/dpdk/rte/mp_socket
EAL: Selected IOVA mode 'PA'
Interactive-mode selected
Warning: NUMA should be configured manually by using --port-numa-config and --ring-numa-config parameters along with --numa.
testpmd: Flow tunnel offload support might be limited or unavailable on port 0
testpmd: Flow tunnel offload support might be limited or unavailable on port 1
testpmd: create a new mbuf pool <mb_pool_0>: n=171456, size=2176, socket=0
testpmd: preferred mempool ops selected: ring_mp_mc
Configuring Port 0 (socket 0)
Port 0: 6C:B3:11:88:55:B4
Configuring Port 1 (socket 0)
Port 1: 6C:B3:11:88:55:B5
Checking link statuses...
Done
testpmd> show port info all

********************* Infos for port 0  *********************
MAC address: 6C:B3:11:88:55:B4
Device name: 0000:01:00.0
Driver name: mlx5_pci
Firmware-version: 16.35.4506
Connect to socket: 0
memory allocation on the socket: 0
Link status: up
Link speed: 25 Gbps
Link duplex: full-duplex
Autoneg status: On
MTU: 1500
Promiscuous mode: enabled
Allmulticast mode: disabled
Maximum number of MAC addresses: 128
Maximum number of MAC addresses of hash filtering: 0
VLAN offload:
  strip off, filter off, extend off, qinq strip off
Hash key size in bytes: 40
Redirection table size: 1
Supported RSS offload flow types:
  ipv4  ipv4-frag  ipv4-tcp  ipv4-udp  ipv4-other  ipv6
  ipv6-frag  ipv6-tcp  ipv6-udp  ipv6-other  ipv6-ex
  ipv6-tcp-ex  ipv6-udp-ex  esp  l4-dst-only  l4-src-only
  l3-dst-only  l3-src-only
Minimum size of RX buffer: 32
Maximum configurable length of RX packet: 10000
Maximum configurable size of LRO aggregated packet: 65280
Current number of RX queues: 1
Max possible RX queues: 1024
Max possible number of RXDs per queue: 32768
Min possible number of RXDs per queue: 0
RXDs number alignment: 1
Current number of TX queues: 1
Max possible TX queues: 1024
Max possible number of TXDs per queue: 32768
Min possible number of TXDs per queue: 0
TXDs number alignment: 1
Max segment number per packet: 40
Max segment number per MTU/TSO: 40
Device capabilities: 0x14( RXQ_SHARE FLOW_SHARED_OBJECT_KEEP )
Switch name: 0000:01:00.0
Switch domain Id: 0
Switch Port Id: 65535
Switch Rx domain: 0
Device error handling mode: none
Device private info:
  none

********************* Infos for port 1  *********************
MAC address: 6C:B3:11:88:55:B5
Device name: 0000:01:00.1
Driver name: mlx5_pci
Firmware-version: 16.35.4506
Connect to socket: 0
memory allocation on the socket: 0
Link status: up
Link speed: 25 Gbps
Link duplex: full-duplex
Autoneg status: On
MTU: 1500
Promiscuous mode: enabled
Allmulticast mode: disabled
Maximum number of MAC addresses: 128
Maximum number of MAC addresses of hash filtering: 0
VLAN offload:
  strip off, filter off, extend off, qinq strip off
Hash key size in bytes: 40
Redirection table size: 1
Supported RSS offload flow types:
  ipv4  ipv4-frag  ipv4-tcp  ipv4-udp  ipv4-other  ipv6
  ipv6-frag  ipv6-tcp  ipv6-udp  ipv6-other  ipv6-ex
  ipv6-tcp-ex  ipv6-udp-ex  esp  l4-dst-only  l4-src-only
  l3-dst-only  l3-src-only
Minimum size of RX buffer: 32
Maximum configurable length of RX packet: 10000
Maximum configurable size of LRO aggregated packet: 65280
Current number of RX queues: 1
Max possible RX queues: 1024
Max possible number of RXDs per queue: 32768
Min possible number of RXDs per queue: 0
RXDs number alignment: 1
Current number of TX queues: 1
Max possible TX queues: 1024
Max possible number of TXDs per queue: 32768
Min possible number of TXDs per queue: 0
TXDs number alignment: 1
Max segment number per packet: 40
Max segment number per MTU/TSO: 40
Device capabilities: 0x14( RXQ_SHARE FLOW_SHARED_OBJECT_KEEP )
Switch name: 0000:01:00.1
Switch domain Id: 1
Switch Port Id: 65535
Switch Rx domain: 0
Device error handling mode: none
Device private info:
  none
testpmd> show port info all

********************* Infos for port 0  *********************
MAC address: 6C:B3:11:88:55:B4
Device name: 0000:01:00.0
Driver name: mlx5_pci
Firmware-version: 16.35.4506
Connect to socket: 0
memory allocation on the socket: 0
Link status: up
Link speed: 25 Gbps
Link duplex: full-duplex
Autoneg status: On
MTU: 1500
Promiscuous mode: enabled
Allmulticast mode: disabled
Maximum number of MAC addresses: 128
Maximum number of MAC addresses of hash filtering: 0
VLAN offload:
  strip off, filter off, extend off, qinq strip off
Hash key size in bytes: 40
Redirection table size: 1
Supported RSS offload flow types:
  ipv4  ipv4-frag  ipv4-tcp  ipv4-udp  ipv4-other  ipv6
  ipv6-frag  ipv6-tcp  ipv6-udp  ipv6-other  ipv6-ex
  ipv6-tcp-ex  ipv6-udp-ex  esp  l4-dst-only  l4-src-only
  l3-dst-only  l3-src-only
Minimum size of RX buffer: 32
Maximum configurable length of RX packet: 10000
Maximum configurable size of LRO aggregated packet: 65280
Current number of RX queues: 1
Max possible RX queues: 1024
Max possible number of RXDs per queue: 32768
Min possible number of RXDs per queue: 0
RXDs number alignment: 1
Current number of TX queues: 1
Max possible TX queues: 1024
Max possible number of TXDs per queue: 32768
Min possible number of TXDs per queue: 0
TXDs number alignment: 1
Max segment number per packet: 40
Max segment number per MTU/TSO: 40
Device capabilities: 0x14( RXQ_SHARE FLOW_SHARED_OBJECT_KEEP )
Switch name: 0000:01:00.0
Switch domain Id: 0
Switch Port Id: 65535
Switch Rx domain: 0
Device error handling mode: none
Device private info:
  none

********************* Infos for port 1  *********************
MAC address: 6C:B3:11:88:55:B5
Device name: 0000:01:00.1
Driver name: mlx5_pci
Firmware-version: 16.35.4506
Connect to socket: 0
memory allocation on the socket: 0
Link status: up
Link speed: 25 Gbps
Link duplex: full-duplex
Autoneg status: On
MTU: 1500
Promiscuous mode: enabled
Allmulticast mode: disabled
Maximum number of MAC addresses: 128
Maximum number of MAC addresses of hash filtering: 0
VLAN offload:
  strip off, filter off, extend off, qinq strip off
Hash key size in bytes: 40
Redirection table size: 1
Supported RSS offload flow types:
  ipv4  ipv4-frag  ipv4-tcp  ipv4-udp  ipv4-other  ipv6
  ipv6-frag  ipv6-tcp  ipv6-udp  ipv6-other  ipv6-ex
  ipv6-tcp-ex  ipv6-udp-ex  esp  l4-dst-only  l4-src-only
  l3-dst-only  l3-src-only
Minimum size of RX buffer: 32
Maximum configurable length of RX packet: 10000
Maximum configurable size of LRO aggregated packet: 65280
Current number of RX queues: 1
Max possible RX queues: 1024
Max possible number of RXDs per queue: 32768
Min possible number of RXDs per queue: 0
RXDs number alignment: 1
Current number of TX queues: 1
Max possible TX queues: 1024
Max possible number of TXDs per queue: 32768
Min possible number of TXDs per queue: 0
TXDs number alignment: 1
Max segment number per packet: 40
Max segment number per MTU/TSO: 40
Device capabilities: 0x14( RXQ_SHARE FLOW_SHARED_OBJECT_KEEP )
Switch name: 0000:01:00.1
Switch domain Id: 1
Switch Port Id: 65535
Switch Rx domain: 0
Device error handling mode: none
Device private info:
  none
testpmd> show port stats all

  ######################## NIC statistics for port 0  ########################
  RX-packets: 0          RX-missed: 0          RX-bytes:  0
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 0          TX-errors: 0          TX-bytes:  0

  Throughput (since last show)
  Rx-pps:            0          Rx-bps:            0
  Tx-pps:            0          Tx-bps:            0
  ############################################################################

  ######################## NIC statistics for port 1  ########################
  RX-packets: 0          RX-missed: 0          RX-bytes:  0
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 0          TX-errors: 0          TX-bytes:  0

  Throughput (since last show)
  Rx-pps:            0          Rx-bps:            0
  Tx-pps:            0          Tx-bps:            0
  ############################################################################
testpmd> start
io packet forwarding - ports=2 - cores=1 - streams=2 - NUMA support enabled, MP allocation mode: native
Logical Core 1 (socket 0) forwards packets on 2 streams:
  RX P=0/Q=0 (socket 0) -> TX P=1/Q=0 (socket 0) peer=02:00:00:00:00:01
  RX P=1/Q=0 (socket 0) -> TX P=0/Q=0 (socket 0) peer=02:00:00:00:00:00

  io packet forwarding packets/burst=32
  nb forwarding cores=1 - nb forwarding ports=2
  port 0: RX queue number: 1 Tx queue number: 1
    Rx offloads=0x0 Tx offloads=0x10000
    RX queue: 0
      RX desc=256 - RX free threshold=64
      RX threshold registers: pthresh=0 hthresh=0  wthresh=0
      RX Offloads=0x0
    TX queue: 0
      TX desc=256 - TX free threshold=0
      TX threshold registers: pthresh=0 hthresh=0  wthresh=0
      TX offloads=0x10000 - TX RS bit threshold=0
  port 1: RX queue number: 1 Tx queue number: 1
    Rx offloads=0x0 Tx offloads=0x10000
    RX queue: 0
      RX desc=256 - RX free threshold=64
      RX threshold registers: pthresh=0 hthresh=0  wthresh=0
      RX Offloads=0x0
    TX queue: 0
      TX desc=256 - TX free threshold=0
      TX threshold registers: pthresh=0 hthresh=0  wthresh=0
      TX offloads=0x10000 - TX RS bit threshold=0
testpmd> stop
Telling cores to stop...
Waiting for lcores to finish...

  ---------------------- Forward statistics for port 0  ----------------------
  RX-packets: 0              RX-dropped: 0             RX-total: 0
  TX-packets: 0              TX-dropped: 0             TX-total: 0
  ----------------------------------------------------------------------------

  ---------------------- Forward statistics for port 1  ----------------------
  RX-packets: 0              RX-dropped: 0             RX-total: 0
  TX-packets: 0              TX-dropped: 0             TX-total: 0
  ----------------------------------------------------------------------------

  +++++++++++++++ Accumulated forward statistics for all ports+++++++++++++++
  RX-packets: 0              RX-dropped: 0             RX-total: 0
  TX-packets: 0              TX-dropped: 0             TX-total: 0
  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Done.
testpmd> set fwd io
Set io packet forwarding mode
testpmd> set fwd mac
Set mac packet forwarding mode
testpmd>
testpmd> set fwd io
Set io packet forwarding mode
testpmd> set fwd mac
Set mac packet forwarding mode
testpmd> stop
Packet forwarding not started
testpmd> set fwd txonly
Set txonly packet forwarding mode
testpmd> start
txonly packet forwarding - ports=2 - cores=1 - streams=2 - NUMA support enabled, MP allocation mode: native
Logical Core 1 (socket 0) forwards packets on 2 streams:
  RX P=0/Q=0 (socket 0) -> TX P=1/Q=0 (socket 0) peer=02:00:00:00:00:01
  RX P=1/Q=0 (socket 0) -> TX P=0/Q=0 (socket 0) peer=02:00:00:00:00:00

  txonly packet forwarding packets/burst=32
  packet len=64 - nb packet segments=1
  nb forwarding cores=1 - nb forwarding ports=2
  port 0: RX queue number: 1 Tx queue number: 1
    Rx offloads=0x0 Tx offloads=0x10000
    RX queue: 0
      RX desc=256 - RX free threshold=64
      RX threshold registers: pthresh=0 hthresh=0  wthresh=0
      RX Offloads=0x0
    TX queue: 0
      TX desc=256 - TX free threshold=0
      TX threshold registers: pthresh=0 hthresh=0  wthresh=0
      TX offloads=0x10000 - TX RS bit threshold=0
  port 1: RX queue number: 1 Tx queue number: 1
    Rx offloads=0x0 Tx offloads=0x10000
    RX queue: 0
      RX desc=256 - RX free threshold=64
      RX threshold registers: pthresh=0 hthresh=0  wthresh=0
      RX Offloads=0x0
    TX queue: 0
      TX desc=256 - TX free threshold=0
      TX threshold registers: pthresh=0 hthresh=0  wthresh=0
      TX offloads=0x10000 - TX RS bit threshold=0
testpmd> show port stats all

  ######################## NIC statistics for port 0  ########################
  RX-packets: 0          RX-missed: 158269376  RX-bytes:  0
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 158268352  TX-errors: 0          TX-bytes:  10129176576

  Throughput (since last show)
  Rx-pps:            0          Rx-bps:            0
  Tx-pps:       668296          Tx-bps:    342168112
  ############################################################################

  ######################## NIC statistics for port 1  ########################
  RX-packets: 0          RX-missed: 158271424  RX-bytes:  0
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 158270912  TX-errors: 0          TX-bytes:  10129338368

  Throughput (since last show)
  Rx-pps:            0          Rx-bps:            0
  Tx-pps:       668308          Tx-bps:    342173712
  ############################################################################
testpmd> stop
Telling cores to stop...
Waiting for lcores to finish...

  ---------------------- Forward statistics for port 0  ----------------------
  RX-packets: 0              RX-dropped: 295470656     RX-total: 295470656
  TX-packets: 295470912      TX-dropped: 0             TX-total: 295470912
  ----------------------------------------------------------------------------

  ---------------------- Forward statistics for port 1  ----------------------
  RX-packets: 0              RX-dropped: 295470656     RX-total: 295470656
  TX-packets: 295470912      TX-dropped: 0             TX-total: 295470912
  ----------------------------------------------------------------------------

  +++++++++++++++ Accumulated forward statistics for all ports+++++++++++++++
  RX-packets: 0              RX-dropped: 590941312     RX-total: 590941312
  TX-packets: 590941824      TX-dropped: 0             TX-total: 590941824
  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Done.
testpmd> show rxq info 0 0

********************* Infos for port 0 , RX queue 0  *********************
Mempool: mb_pool_0
RX prefetch threshold: 0
RX host threshold: 0
RX writeback threshold: 0
RX free threshold: 64
RX drop packets: on
RX deferred start: on
RX scattered packets: off
Rx queue state: started
Number of RXDs: 256
Burst mode: Vector SSE
testpmd> show port info 0

********************* Infos for port 0  *********************
MAC address: 6C:B3:11:88:55:B4
Device name: 0000:01:00.0
Driver name: mlx5_pci
Firmware-version: 16.35.4506
Connect to socket: 0
memory allocation on the socket: 0
Link status: up
Link speed: 25 Gbps
Link duplex: full-duplex
Autoneg status: On
MTU: 1500
Promiscuous mode: enabled
Allmulticast mode: disabled
Maximum number of MAC addresses: 128
Maximum number of MAC addresses of hash filtering: 0
VLAN offload:
  strip off, filter off, extend off, qinq strip off
Hash key size in bytes: 40
Redirection table size: 1
Supported RSS offload flow types:
  ipv4  ipv4-frag  ipv4-tcp  ipv4-udp  ipv4-other  ipv6
  ipv6-frag  ipv6-tcp  ipv6-udp  ipv6-other  ipv6-ex
  ipv6-tcp-ex  ipv6-udp-ex  esp  l4-dst-only  l4-src-only
  l3-dst-only  l3-src-only
Minimum size of RX buffer: 32
Maximum configurable length of RX packet: 10000
Maximum configurable size of LRO aggregated packet: 65280
Current number of RX queues: 1
Max possible RX queues: 1024
Max possible number of RXDs per queue: 32768
Min possible number of RXDs per queue: 0
RXDs number alignment: 1
Current number of TX queues: 1
Max possible TX queues: 1024
Max possible number of TXDs per queue: 32768
Min possible number of TXDs per queue: 0
TXDs number alignment: 1
Max segment number per packet: 40
Max segment number per MTU/TSO: 40
Device capabilities: 0x14( RXQ_SHARE FLOW_SHARED_OBJECT_KEEP )
Switch name: 0000:01:00.0
Switch domain Id: 0
Switch Port Id: 65535
Switch Rx domain: 0
Device error handling mode: none
Device private info:
  none
  
=================


