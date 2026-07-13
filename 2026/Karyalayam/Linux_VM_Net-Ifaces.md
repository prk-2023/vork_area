# Types of Network Interfaces in Linux and Virtualization:

There is a large number of network interface types. They can be grouped into Physical devices, virtual
devices, tunneling devices, virtualization devices, and special purpose interfaces:


- Ethernet: 

| Interface Type | Driver/Kind            | Purpose                                           |
| -------------- | ---------------------- | ------------------------------------------------- |
| Ethernet       | `eth*`, `enp*`, `ens*` | Standard wired NICs                               |
| Wi-Fi          | `wlan*`, `wlp*`        | Wireless interfaces                               |
| Loopback       | `lo`                   | Local host communication                          |
| Bridge         | `bridge`               | Software Layer-2 switch                           |
| Bond           | `bond`                 | Link aggregation/failover                         |
| Team           | `team`                 | Modern replacement for bonding (less common now)  |
| VLAN           | `vlan`                 | IEEE 802.1Q virtual LAN                           |
| MACVLAN        | `macvlan`              | Multiple MAC addresses on one NIC                 |
| IPVLAN         | `ipvlan`               | Multiple IP stacks sharing one MAC                |
| Dummy          | `dummy`                | Software-only interface                           |
| IFB            | `ifb`                  | Intermediate Functional Block for traffic shaping |
| TAP            | `tap`                  | Layer-2 virtual interface                         |
| TUN            | `tun`                  | Layer-3 virtual interface                         |
| VETH           | `veth`                 | Virtual Ethernet pair                             |
| VXLAN          | `vxlan`                | Layer-2 overlay over UDP                          |
| GENEVE         | `geneve`               | Modern overlay tunnel                             |
| GRE            | `gre`                  | Generic Routing Encapsulation                     |
| GRETAP         | `gretap`               | Ethernet over GRE                                 |
| IPIP           | `ipip`                 | IPv4 over IPv4 tunnel                             |
| SIT            | `sit`                  | IPv6 over IPv4                                    |
| IP6GRE         | `ip6gre`               | GRE over IPv6                                     |
| ERSPAN         | `erspan`               | Encapsulated port mirroring                       |
| WireGuard      | `wireguard`            | VPN interface                                     |
| XFRM           | `xfrm`                 | IPsec virtual interface                           |
| VRF            | `vrf`                  | Virtual routing tables                            |
| CAN            | `can`                  | Controller Area Network                           |
| VCAN           | `vcan`                 | Virtual CAN                                       |
| PPP            | `ppp`                  | Point-to-point links                              |
| SLIP           | `slip`                 | Serial Line IP                                    |
| WWAN           | `wwan`                 | Cellular modems                                   |
| BATMAN         | `batadv`               | Mesh networking                                   |
| Open vSwitch   | `ovs-system`           | Software virtual switch                           |


---

## 1. Physical interfaces

### Ethernet

Examples:

```
enp3s0
eth0
ens18
```

Represents a real NIC.

```
Host
 │
Ethernet NIC
 │
Switch
```

Created automatically by the hardware driver.

---

### Wi-Fi

Examples

```
wlp2s0
wlan0
```

Wireless network adapter.

Supports:

* AP mode
* Station mode
* Monitor mode
* Mesh mode

---

### Loopback

```
lo
```

Special interface that never leaves the machine.

```
127.0.0.1
::1
```

Packets sent here immediately return to the local host.

---

## 2. Software Layer-2 devices

### Bridge

```
br0
```

Acts like an Ethernet switch.

```
VM1
 \
  br0 ---- eth0
 /
VM2
```

Common uses:

* KVM
* Docker
* Kubernetes
* Hypervisors

---

### Bond

```
bond0
```

Combines multiple NICs.

```
eth0 \
      bond0
eth1 /
```

Modes include:

* Active-backup
* LACP
* Round robin
* XOR

---

### Team

```
team0
```

Designed as a more flexible replacement for bonding. It saw some adoption but bonding remains more widely
used.

---

### VLAN

```
eth0.100
```

One physical NIC carries multiple VLANs.

```
eth0
 ├── VLAN10
 ├── VLAN20
 └── VLAN30
```

---

### MACVLAN

Creates multiple virtual NICs with different MAC addresses.

```
eth0

├── macvlan1
├── macvlan2
└── macvlan3
```

Useful for containers that should appear as separate hosts on the LAN.

---

### IPVLAN

Similar to MACVLAN.

Difference:

* one MAC
* many IP addresses

Often scales better in large container deployments.

---

## 3. Virtual interfaces

### Dummy

```
dummy0
```

A NIC that goes nowhere.

Useful for:

* testing
* routing
* assigning service IPs

---

### IFB

```
ifb0
```

Used with `tc`.

Allows shaping inbound traffic by redirecting it to a virtual interface.

---

### VETH

One of the most important virtual devices.

```
veth0 <------> veth1
```

Anything entering one side exits the other.

Used by:

* Docker
* Podman
* Kubernetes
* Linux network namespaces

---

### TAP

Layer-2 virtual Ethernet device.

```
VM
 │
 TAP
 │
 Bridge
```

Carries Ethernet frames.

Used by:

* KVM
* QEMU
* VirtualBox

---

### TUN

Layer-3 interface.

```
VPN daemon
      │
     tun0
      │
IP packets
```

Carries IP packets only.

Used by:

* OpenVPN
* Some user-space networking applications

---

## 4. Overlay / tunnel interfaces

### GRE

```
gre0
```

Encapsulates IP packets inside IP.

```
IP
 ↓
GRE
 ↓
IP
```

---

### GRETAP

Ethernet over GRE.

Useful for extending Layer-2 networks.

---

### VXLAN

```
vxlan100
```

Very popular in cloud networking.

```
VM
 │
Bridge
 │
VXLAN
 │
UDP
 │
Internet
```

Default UDP port:

```
4789
```

---

### GENEVE

Modern replacement for VXLAN.

Adds flexible metadata options.

Widely used by cloud platforms.

---

### IPIP

Simple IPv4 tunnel.

```
IPv4
 ↓
IPv4
```

Very lightweight.

---

### SIT

IPv6 carried over IPv4.

---

### IP6GRE

GRE running over IPv6.

---

### ERSPAN

Cisco-originated protocol for remote packet mirroring and traffic analysis.

---

# 5. VPN / security

### WireGuard

```
wg0
```

Kernel VPN.

Looks just like another NIC.

```
Application
      │
     wg0
      │
Encrypted UDP
```

---

### XFRM

```
ip link add ipsec0 type xfrm
```

Virtual interface for IPsec.

Separates encrypted traffic from normal routing.

---

## 6. Virtualization

### TAP

Used by QEMU.

```
Guest
 │
virtio-net
 │
tap0
 │
Bridge
 │
eth0
```

Often accelerated with `vhost_net`, which moves much of the packet processing into the kernel.

---

### VETH

Containers usually connect like this:

```
Container
    │
 veth123
    │
veth456
    │
 bridge
    │
 eth0
```

---

## 7. Routing

### VRF

```
vrf-blue
vrf-red
```

Multiple routing tables.

```
App A
 │
VRF blue

App B
 │
VRF red
```

Used by ISPs and large enterprise networks.

---

## 8. Industrial

### CAN

```
can0
```

Automotive Controller Area Network.

---

### VCAN

```
vcan0
```

Virtual CAN.

Perfect for testing.

---

## 9. Legacy interfaces

### PPP

```
ppp0
```

Still used by:

* DSL
* Some VPNs
* Cellular links

---

### SLIP

Very old serial networking protocol.

Rarely used today.

---

## 10. Mesh networking

### BATMAN Advanced

```
bat0
```

Creates self-healing Layer-2 mesh networks.

Popular in community mesh projects.

---

## 11. Open vSwitch

```
ovs-system
```

Not a traditional interface type but part of the Open vSwitch datapath. It provides programmable switching with features such as VLANs, VXLAN, ACLs, QoS, and OpenFlow, and is widely used in cloud platforms like OpenStack.

---

### Which interface types are most common?

On a typical desktop:

```
lo
enp3s0
wlp2s0
```

On a Docker host:

```
lo
eth0
docker0 (bridge)
veth*
```

On a Kubernetes node:

```
eth0
cni0 (bridge)
veth*
vxlan.calico
flannel.1
genev_sys_* (depending on the CNI)
```

On a KVM virtualization host:

```
eth0
br0
tap*
vnet*
```

The `vnet*` interfaces are the host-side ends of TAP devices created automatically by libvirt/QEMU.

---

There are also many niche interface types (for example `nlmon` for monitoring Netlink messages, `hsr` for
High-availability Seamless Redundancy, `macsec` for IEEE 802.1AE link-layer encryption, `ipoib` for
InfiniBand, `6lowpan` for low-power wireless networks, and `bareudp` for lightweight encapsulation). Most
Linux systems only ever use a small subset of the interface types listed above.


--- 

# Virtualization Interfaces:


Virtualization networking in Linux is a deep topic because there are **three separate layers** involved:

1. **The guest virtual NIC** (what the VM sees)
2. **The host network interface** (how packets enter the Linux networking stack)
3. **The acceleration mechanism** (how packets are moved efficiently)

Understanding these layers makes the kernel modules much easier to understand.

---

## Typical KVM/QEMU networking stack

A modern KVM VM usually looks like this:

```text
              Guest
        +----------------+
        |  virtio-net    |
        +----------------+
                │
         Virtqueue (shared memory)
                │
        +----------------+
        | vhost_net      |   (kernel)
        +----------------+
                │
            TAP device
                │
        Linux Bridge / OVS
                │
        Physical NIC
```

Notice that **virtio**, **vhost**, and **tap** are all different things.

---

### 1. virtio-net

This is **inside the guest**.

The guest thinks it owns a network card.

Instead of emulating an Intel e1000 card, QEMU presents a **VirtIO network device**, which is specifically designed for virtualization.

Guest sees:

```text
eth0
```

or

```text
ens3
```

Internally it's actually

```text
virtio-net
```

Kernel module (guest):

```
virtio_net
```

Dependencies:

```
virtio
virtio_ring
virtio_pci
```

These modules exist **inside the VM**, not on the host.

---

### 2. TAP device

The TAP device exists on the host.

Example:

```
tap0
```

or

```
vnet0
```

(libvirt creates `vnet0` automatically.)

A TAP interface behaves exactly like an Ethernet NIC.

```
Guest Ethernet frame
          ↓
      TAP interface
          ↓
 Linux bridge
```

Kernel module:

```
tun
```

Yes—the **`tun` module provides both TUN and TAP devices**.

```
modprobe tun
```

creates

```
/dev/net/tun
```

Userspace (QEMU) requests a TAP interface through this device.

---

### 3. Linux bridge

Usually

```
br0
```

or

```
virbr0
```

Kernel module:

```
bridge
```

It behaves exactly like an Ethernet switch.

```
          bridge
        /    |     \
     tap0   tap1   eth0
```

Every VM simply plugs into this software switch.

---

### 4. vhost_net

This is where performance comes from.

Without it:

```
Guest
 ↓
QEMU
 ↓
Kernel
 ↓
NIC
```

Every packet enters userspace.

Lots of context switches.

---

With

```
vhost_net
```

```
Guest
 ↓
Kernel
 ↓
NIC
```

QEMU stays out of the fast path.

Kernel module:

```
vhost_net
```

Depends on

```
vhost
```

You can see it with

```bash
lsmod | grep vhost
```

Example

```
vhost_net
vhost
```

---

### 5. vhost

This is the generic framework.

Think of it like

```
vhost
    ↑
    ├── vhost_net
    ├── vhost_scsi
    ├── vhost_vsock
    └── vhost_vdpa
```

The common infrastructure lives here.

---

### 6. vhost_vsock

Provides VM ↔ host sockets.

Instead of TCP/IP:

```
Guest
  |
AF_VSOCK
  |
Host
```

Used by

* Kata Containers
* Firecracker
* VMware
* Hyper-V

Kernel module

```
vhost_vsock
```

---

### 7. vhost_scsi

Accelerates virtual SCSI devices.

Instead of

```
Guest
 ↓
QEMU
 ↓
Host disk
```

Much of the I/O is handled directly in the kernel.

Kernel module

```
vhost_scsi
```

---

### 8. vDPA

Very new.

```
Guest
   │
virtio
   │
vDPA
   │
SmartNIC
```

The NIC itself performs much of the virtualization work.

Kernel modules include

```
vhost_vdpa
vdpa
mlx5_vdpa
```

depending on the hardware.

---

# Default networking for libvirt

If you install

```
libvirt
```

and create a VM without changing anything:

```
          Guest
            │
       virtio-net
            │
         vhost_net
            │
          vnet0
            │
         virbr0
            │
         NAT (iptables/nftables)
            │
          eth0
```

Kernel modules commonly loaded:

```
virtio
virtio_net      (inside guest)

tun
bridge
vhost
vhost_net
```

---

# Common kernel modules on a KVM host

| Module                  | Purpose                                          |
| ----------------------- | ------------------------------------------------ |
| `kvm`                   | Core virtualization support                      |
| `kvm_intel` / `kvm_amd` | CPU virtualization extensions                    |
| `tun`                   | Creates TUN/TAP devices (`/dev/net/tun`)         |
| `bridge`                | Software Ethernet bridge                         |
| `vhost`                 | Common vhost infrastructure                      |
| `vhost_net`             | Kernel acceleration for virtio-net               |
| `vhost_vsock`           | Host↔guest socket acceleration                   |
| `vhost_scsi`            | SCSI acceleration                                |
| `macvlan`               | Optional alternative host networking             |
| `8021q`                 | VLAN support if VMs use VLANs                    |
| `openvswitch`           | If Open vSwitch is used instead of Linux bridges |

---

# Alternatives to TAP + Bridge

While **TAP + bridge + virtio-net + vhost_net** is the default and most common configuration, there are several other host networking approaches:

| Backend                      | Kernel modules                                                           | Typical use                                                                  |
| ---------------------------- | ------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| TAP + bridge                 | `tun`, `bridge`, `vhost_net`                                             | General-purpose virtualization (default)                                     |
| TAP + Open vSwitch           | `tun`, `openvswitch`, `vhost_net`                                        | OpenStack, SDN, cloud platforms                                              |
| macvtap                      | `macvlan`, `tun`                                                         | Connect a VM directly to a physical NIC without a bridge                     |
| SR-IOV Virtual Function (VF) | Hardware-specific NIC driver (for example, `ixgbe`, `i40e`, `mlx5_core`) | Near-native performance by assigning a virtual PCI function directly to a VM |
| PCI passthrough (VFIO)       | `vfio`, `vfio_pci`, `vfio_iommu_type1`                                   | Gives a VM exclusive control of an entire PCI device                         |

The last two options reduce or eliminate software switching by allowing the guest to access network hardware much more directly, at the cost of reduced flexibility compared to TAP-based networking.

In practice, if you inspect a typical KVM host running standard libvirt-managed VMs, the most relevant networking modules you'll encounter are:

```text
kvm_intel (or kvm_amd)
kvm

tun
bridge

vhost
vhost_net

virtio (inside each guest)
virtio_net (inside each guest)
```

These modules form the foundation of the default Linux virtualization networking stack.
