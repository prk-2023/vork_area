# Open VSwitch:


**Open vSwitch (OVS)** is an open-source virtual switch designed for virtualized environments and
software-defined networking (SDN). 

It provides advanced network switching capabilities for virtual machines and containers, similar to how a
physical Ethernet switch connects physical devices.

OVS is commonly used in:

* Virtual machine platforms like VMware and KVM-based environments.
* Cloud platforms such as OpenStack.
* Container networking with Kubernetes.
* SDN solutions that require programmable network behavior.

## What does it do?

Open vSwitch acts like a Layer 2 Ethernet switch, but in software. 

It can:

* Connect virtual machines, containers, and physical network interfaces.
* Forward packets based on MAC addresses.
* Support VLANs, tunneling, and quality of service (QoS).
* Mirror traffic for monitoring.
* Enforce access control policies.
* Be centrally managed by SDN controllers.

## How it fits into a virtualized system

For example:

```text
                Physical Network
                       |
                  Physical NIC
                       |
               +----------------+
               | Open vSwitch   |
               +----------------+
              /        |        \
        VM1 (vNIC) VM2 (vNIC) VM3 (vNIC)
```

Instead of plugging VMs into a physical switch, their virtual network interfaces connect to Open vSwitch.

## Key features

Some of its major capabilities include:

| Feature             | Description                                         |
| ------------------- | --------------------------------------------------- |
| VLAN support        | Segments network traffic                            |
| VXLAN/Geneve/GRE    | Creates overlay networks                            |
| OpenFlow            | Supports SDN programming                            |
| Bonding             | Combines multiple NICs for redundancy or throughput |
| QoS                 | Controls bandwidth and traffic priority             |
| Port mirroring      | Copies traffic for analysis                         |
| NetFlow/sFlow/IPFIX | Exports traffic statistics                          |
| ACLs                | Filters traffic based on rules                      |

## Components

OVS consists of several parts:

* **ovs-vswitchd** – the main switching daemon that forwards packets.
* **ovsdb-server** – stores the switch configuration.
* **ovs-vsctl** – command-line tool for configuring OVS.
* **ovs-ofctl** – manages OpenFlow rules.
* Linux kernel data-path (or userspace data-path): performs fast packet forwarding.

## Example commands

Create a bridge:

```bash
ovs-vsctl add-br br0
```

Add a physical interface:

```bash
ovs-vsctl add-port br0 eth0
```

Add an internal interface:

```bash
ovs-vsctl add-port br0 vnet0
```

Show the configuration:

```bash
ovs-vsctl show
```

## Why use Open vSwitch instead of the Linux bridge?

The standard Linux bridge is simpler and sufficient for basic networking. 
Open vSwitch adds capabilities that are useful in larger or more dynamic environments:

| Linux Bridge            | Open vSwitch                    |
| ----------------------- | ------------------------------- |
| Basic Layer 2 switching | Advanced programmable switching |
| Basic VLAN support      | Rich VLAN and tunneling support |
| Limited monitoring      | NetFlow, sFlow, IPFIX           |
| No OpenFlow             | Full OpenFlow support           |
| Basic management        | Centralized SDN management      |
| Simpler                 | More feature-rich and scalable  |

## Common use cases

* **Cloud infrastructure:** Connect thousands of virtual machines with isolated tenant networks.
* **Container platforms:** Provide virtual networking for containers and Kubernetes clusters.
* **Network virtualization:** Build overlay networks using VXLAN or Geneve.
* **SDN:** Allow a centralized controller to install forwarding rules dynamically.
* **Network testing:** Create complex virtual network topologies without dedicated hardware.

In short, Open vSwitch is a software-based network switch that brings many of the advanced capabilities of
enterprise networking hardware into software, making it a core component of many modern cloud,
virtualization, and SDN deployments.

---

# Example OVS: 

To start, before involving another VM or DPDK, you want to answer one simple question:

> **Can I reliably get packets from a VirtIO VM, through OVS, out a ConnectX-5 PF, across the DAC, and into the Linux host?**

Once this works, everything else builds on it.

---

# Phase 1A Lab Topology

```text
                           Linux Host
+------------------------------------------------------------------+
|                                                                  |
|                Open vSwitch (Kernel Datapath)                    |
|                                                                  |
|                  +-----------------------+                       |
|                  |      br-test          |                       |
|                  +-----------------------+                       |
|                           |                                      |
|                        tap0                                      |
|                           |                                      |
|                     QEMU / KVM VM                                |
|                    VirtIO Network                                |
|                           |                                      |
|                    enp1s0f0np0                                   |
+---------------------------|--------------------------------------+
                            |
                     ConnectX-5 Port 0
                            |
======================= DAC Cable =======================
                            |
                     ConnectX-5 Port 1
                            |
                     enp1s0f1np1
                            |
                     Linux Network Stack
                     (iperf3 Server)
```

---

# Host Requirements

Ubuntu/Debian

```bash
sudo apt update

sudo apt install \
    qemu-kvm \
    qemu-utils \
    bridge-utils \
    openvswitch-switch \
    iproute2 \
    iperf3 \
    tcpdump
```

RHEL/Fedora

```bash
sudo dnf install \
    qemu-kvm \
    openvswitch \
    iproute \
    iperf3 \
    tcpdump
```

Verify KVM

```bash
lsmod | grep kvm
```

Verify OVS

```bash
// 1. Install:
sudo dnf install openvswitch openvswitch-dpdk

//2. Start openvswitch daemon:

$sudo systemctl status openvswitch

//if disabled:

$sudo systemctl start openvswitch

$sudo ovs-vsctl show

//sanity check before we configure ( fedora )

$sudo systemctl is-active openvswitch
active

$sudo ovs-vsctl show
0da738c6-3132-406e-84da-bb0c58d1fdcd
    ovs_version: "3.6.2-1.fc43"
ovs-vsctl show 
```



---

# Verify NICs

```bash
ip link
```

Expected

```text
enp4s0             (leave alone)
enp1s0f0np0        (ConnectX Port0)
enp1s0f1np1        (ConnectX Port1)
```

---

# Bring interfaces up

```bash
sudo ip link set enp1s0f0np0 up

sudo ip link set enp1s0f1np1 up
```

---

# Configure Host Interface

Assign an IP to Port 1.

```bash
sudo ip addr add 192.168.100.2/24 dev enp1s0f1np1
```

Verify

```bash
ip addr show enp1s0f1np1
```

---

# Create OVS Bridge

```bash
sudo ovs-vsctl add-br br-test
```

Verify

```bash
ovs-vsctl show
```

---

# Add PF Port

```bash
sudo ovs-vsctl add-port br-test enp1s0f0np0
```

Bridge now

```text
br-test
 └── enp1s0f0np0
```

---

# Create TAP Device

```bash
sudo ip tuntap add tap0 mode tap
```

Bring it up

```bash
sudo ip link set tap0 up
```

---

# Attach TAP to OVS

```bash
sudo ovs-vsctl add-port br-test tap0
```

Now

```text
br-test
├── tap0
└── enp1s0f0np0
```

---

# Launch QEMU

Example

wget https://download.fedoraproject.org/pub/fedora/linux/releases/42/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64.qcow2


```bash
sudo qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -smp 4 \
    -m 4096 \
    -drive file=ubuntu.qcow2,if=virtio \
    -netdev tap,id=hn0,ifname=tap0,script=no,downscript=no,vhost=on \
    -device virtio-net-pci,netdev=hn0,mq=on,vectors=10 \
    -serial mon:stdio
```

## Why these options?

### vhost=on

Moves packet forwarding into the kernel.

Lower latency.

Less CPU.

Almost every production VirtIO deployment enables it.

---

### virtio-net-pci

Standard VirtIO NIC.

---

### mq=on

Enable multiqueue.

Useful for benchmarking.

---

### cpu host

Expose host CPU features.

---

### vectors=10

Enough MSI-X vectors for multiqueue.

---

# Inside VM

Verify NIC

```bash
ip link
```

Configure

```bash
sudo ip addr add 192.168.100.1/24 dev eth0

sudo ip link set eth0 up

#activate queues inside vm ( as qemu uses queues=4 to match the 4 vCPUs:)
sudo ethtool -L eth0 combined 4 
```

---

# Verify Connectivity

From VM

```bash
ping 192.168.100.2
```

Should succeed.

---

Kernel reverse path filtering ( `rp_filter`)
Because both ports live on same Linux host, the kernel might see traffic originating from VM 192.168.0.1
arriving on enp1s0f1np1 look at its owtn routing table and find it weird or asymmetric.
To prevent the host kernel from silently dropping the test packets due to security checks, temporarily
disable Reverse path filtering on the test interface:
$sudo sysctl -w net.ipv4.conf.enp1s0f1np1.rp_filter=0
$sudo sysctl -w net.ipv4.conf.all.rp_filter=0

# Start iperf3

Host

```bash
iperf3 -s
```

VM

```bash
iperf3 -c 192.168.100.2
```

UDP

```bash
iperf3 -u \
    -b 0 \
    -t 30 \
    -c 192.168.100.2
```

---

# Verify Packet Path

Watch Port0

```bash
sudo tcpdump -i enp1s0f0np0
```

Watch Port1

```bash
sudo tcpdump -i enp1s0f1np1
```

You should see packets leaving `enp1s0f0np0`, traversing the DAC, and arriving on `enp1s0f1np1`.

---

# Check OVS Statistics

Ports

```bash
ovs-ofctl dump-ports br-test
```

Flows

```bash
ovs-ofctl dump-flows br-test
```

Configuration

```bash
ovs-vsctl show
```

---

# Benchmark Collection

For each run, record:

| Metric     | Command                                               |
| ---------- | ----------------------------------------------------- |
| Throughput | `iperf3`                                              |
| UDP Mpps   | `iperf3 -u` (convert pps to Mpps if needed)           |
| Host CPU   | `mpstat -P ALL 1` or `sar -u 1`                       |
| Guest CPU  | `mpstat` inside the VM                                |
| OVS stats  | `ovs-ofctl dump-ports br-test`                        |
| NIC stats  | `ethtool -S enp1s0f0np0` and `ethtool -S enp1s0f1np1` |

---

# Additional Host Utilities (Recommended)

I would install a few more tools that are invaluable during performance testing:

```bash
sudo apt install \
    ethtool \
    sysstat \
    numactl \
    linux-tools-common \
    linux-tools-$(uname -r)
```

These provide:

* `ethtool` — inspect NIC capabilities, offloads, and hardware counters.
* `mpstat` / `sar` (from `sysstat`) — monitor CPU utilization per core.
* `numactl` — useful later if you pin VMs and queues to specific NUMA nodes.
* `perf` — profile CPU hotspots in QEMU, OVS, or the kernel.

---

