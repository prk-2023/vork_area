# xdp-tools:

**xdp-tools** is a toolbox around Linux **XDP (eXpress Data Path)** and **eBPF** networking. 

It gives you tools to **load, attach, inspect, benchmark, debug, and manage XDP programs**.

If you're building the whole package, here's the tour:

## 1. First: where XDP fits

A simplified Linux packet path looks roughly like:

```
                    NIC
                     │
              ┌──────▼──────┐
              │ XDP program │  ← xdp-tools lives heavily here
              └──────┬──────┘
                     │
          ┌──────────┼──────────┐
          │          │          │
        DROP       PASS       TX/REDIRECT
          │          │          │
          ✕          ▼          ▼
                  Linux       another NIC/
                 networking   CPU/queue
```

XDP runs an eBPF program **very early in packet reception**, before the normal Linux networking stack.

That makes it useful for things such as:

- DDoS filtering
- packet filtering
- load balancing
- packet forwarding
- traffic measurement
- high-speed firewalls
- custom packet processing

---

## 2. The main xdp-tools programs

After installation, the most interesting commands are typically:

```
xdp-loader
xdp-monitor
xdpdump
xdp-bench
```

There are also libraries and example programs underneath the package.

Let's go through them.

---

## 3. `xdp-loader` — load and attach XDP programs

The first command to learn:

Think of it as:

> "Put this XDP/eBPF program onto this network interface."

For example:

```
sudo xdp-loader load eth0 my_xdp.o
```

You can then inspect what is attached:

```
sudo xdp-loader status
```

Typical output is conceptually like:

```
CURRENT XDP PROGRAMS

Interface   Prio  Program
eth0        50    xdp_filter
```

### Why is there a priority?

This is one of the interesting parts of xdp-tools.

Linux can have multiple XDP programs associated with an interface through **XDP dispatcher** support.

Conceptually:

```
                 eth0
                  │
                  ▼
          XDP dispatcher
          /      |      \
         /       |       \
        ▼        ▼        ▼
     filter   firewall   counter
```

The dispatcher allows multiple XDP programs to coexist.

You can therefore build a chain such as:

```
    packet
      │
      ▼
    XDP program #1
      │
      ▼
    XDP program #2
      │
      ▼
    XDP program #3
      │
      ▼
    normal networking stack
```

`xdp-loader` handles much of this machinery for you.

---

## 4. XDP modes

When you use `xdp-loader`, you'll encounter XDP modes.

The important ones are:

### Native / driver mode

```
    NIC driver
       │
       ▼
    XDP
       │
       ▼
    network stack
```

This is generally the mode you want when the NIC driver supports it.

It runs XDP inside the driver's receive path.

### Generic mode

You can explicitly request generic XDP, for example:

```
sudo xdp-loader load -m skb eth0 my_xdp.o
```

Conceptually:

```
    NIC
     │
     ▼
    driver
     │
     ▼
    SKB created
     │
     ▼
    XDP program
```

It's more portable but loses much of the performance advantage of early XDP processing.

### Offloaded mode

Some hardware/NIC combinations can execute XDP processing on the NIC itself:

```
             NIC
      ┌────────────────┐
      │ XDP offload    │
      │                │
      │  packet filter │
      └───────┬────────┘
              │
              ▼
             CPU
```

This depends heavily on hardware and driver support.

---

## 5. `xdpdump` : packet capture for XDP

This is one of the favorite `xdp-tools` utilities.

It's essentially:

> **tcpdump for XDP programs.**

For example:

```
sudo xdpdump -i eth0
```

You can use it to see packets at the XDP layer.

This is particularly useful because normal:

```
tcpdump -i eth0
```

observes traffic further down the networking path.

XDP can drop or redirect packets **before tcpdump would see them in the normal path**.

So you can have:

```
              NIC
               │
               ▼
           XDP program
            /      \
          DROP     PASS
           │        │
           ✕        ▼
                  tcpdump
```

`xdpdump` helps you investigate what's happening around that XDP boundary.

---

## 6. `xdp-monitor` : watch XDP events

`xdp-monitor` is for monitoring XDP-related activity.

For example:

```
sudo xdp-monitor
```

It's useful when you're trying to answer questions such as:

> "What XDP programs are being loaded?"

> "Why did an XDP program fail to attach?"

> "What is the dispatcher doing?"

> "What's happening with XDP program events?"

Think of it as the **observability/debugging companion** to `xdp-loader`.

A useful mental model is:

```
                  xdp-loader
                      │
                      ▼
             ┌────────────────┐
             │ XDP subsystem  │
             └────────────────┘
                      │
                      ▼
                 xdp-monitor
                      │
                      ▼
                    you
```

---

## 7. `xdp-bench` : performance testing

`xdp-bench` is for benchmarking XDP-related functionality.

This becomes interesting when you're asking:

> "How fast can my system process packets?"

or:

> "How much overhead does my XDP program introduce?"

For example:

```
sudo xdp-bench
```

There are different benchmark modes.

The basic idea is to measure things like:

```
    packets/sec
    bits/sec
    CPU utilization
    drops
    redirects
```

For high-speed networking, **packets per second (PPS)** is often more important than bandwidth.

For example:

```
10 Gbit/s
```

doesn't tell you enough.

Compare:

```
10 Gbit/s of 1500-byte packets
```

with:

```
10 Gbit/s of 64-byte packets
```

The second case requires dramatically more packet processing.

That's where XDP's low overhead becomes important.

---

## 8. `libxdp` : the library underneath

This is perhaps the most important part if you're interested in **developing XDP applications**, rather
than merely using the commands.

`libxdp` provides an API for working with XDP programs.

The architecture looks approximately like:

```
             Your application
                    │
                    ▼
                 libxdp
                    │
           ┌────────┴────────┐
           ▼                 ▼
       libbpf              kernel
           │
           ▼
          BPF
```

 This is why your configure output checked things such as:

```
    bpf_xdp_attach support: yes
    bpf_xdp_query support: yes
    bpf_map_create support: yes
```

Those capabilities come from the interaction between **libxdp**, **libbpf**, and the kernel's BPF/XDP
APIs.

---

## 9. `libbpf` vs `libxdp`

This distinction is worth understanding.

### libbpf

`libbpf` is the general-purpose library for interacting with Linux BPF.

It handles things such as:

```
ELF BPF object
       │
       ▼
     libbpf
       │
       ├── load BPF programs
       ├── create BPF maps
       ├── load BTF
       ├── interact with verifier
       └── interact with kernel BPF APIs
```

### libxdp

`libxdp` is more specifically concerned with **XDP program management**, particularly things such as:

```
multiple XDP programs
        │
        ▼
    dispatcher
        │
   ┌────┼────┐
   ▼    ▼    ▼
 prog1 prog2 prog3
```

So a useful mental shortcut is:

```
libbpf = BPF plumbing

libxdp = XDP-specific plumbing
```

They complement each other.

---

## 10. XDP dispatcher

The dispatcher is one of the coolest pieces of xdp-tools.

Suppose you have:

```
firewall.o
stats.o
ddos_filter.o
```

You don't necessarily want to replace one program every time you want to add another function.

Instead:

```
                 NIC
                  │
                  ▼
          XDP dispatcher
             │   │   │
             ▼   ▼   ▼
           DDoS stats firewall
             │   │   │
             └───┴───┘
                  │
                  ▼
             XDP action
```

The dispatcher can execute multiple XDP programs according to their configuration and priorities.

This is a major reason `libxdp` exists.

---

## 11. XDP actions

Every XDP program ultimately returns an action.

The important ones are:

```
XDP_DROP
XDP_PASS
XDP_TX
XDP_REDIRECT
XDP_ABORTED
```

Think of them as:

### `XDP_DROP`

```
packet → ✕
```

Drop it immediately.

### `XDP_PASS`

```
packet → Linux networking stack
```

Let normal networking handle it.

### `XDP_TX`

```
    NIC RX
      │
      ▼
    XDP
      │
      ▼
    same NIC → transmit
```

Transmit the packet back out the interface.

### `XDP_REDIRECT`

```
    NIC A
     │
     ▼
    XDP
     │
     ▼
    redirect
     │
     ├────► NIC B
     ├────► CPU
     └────► XSK / AF_XDP
```

This is extremely important for high-performance packet processing.

### `XDP_ABORTED`

Something went wrong during program execution.

---

## 12. AF_XDP

xdp-tools also lives in the ecosystem around **AF_XDP**, which is a socket interface for getting packets
between XDP and user-space efficiently.

Conceptually:

```
                     NIC
                      │
                      ▼
                     XDP
                      │
                XDP_REDIRECT
                      │
                      ▼
                  AF_XDP
                      │
                      ▼
                user-space app
```

This allows you to build applications where user-space directly processes packets at high rates.

For example:

```
                ┌─────────────┐
NIC ──► XDP ───►│ AF_XDP      │
                │ application │
                └─────────────┘
```

This is used in high-performance networking applications.

---

## 13. BPF maps

Another major piece you'll encounter is the **BPF map**.

An XDP program can't simply maintain arbitrary normal user-space data structures.

Instead, BPF maps provide kernel-managed storage.

For example:

```
             XDP program
                  │
                  ▼
             BPF HASH MAP
        ┌──────────────────┐
        │ 10.0.0.1 → 1234  │
        │ 10.0.0.2 → 5678  │
        │ 10.0.0.3 → 9012  │
        └──────────────────┘
                  ▲
                  │
             user-space
```

user-space can inspect/update the map while the XDP program uses it.

That's how you can build things such as:

```
    XDP firewall
         │
         ▼
    blocked-IP map
         ▲
         │
    control application
```

---

## 14. BTF

Your configure output also showed:

```
btf__load_from_kernel_by_id support: yes
btf__type_cnt support: yes
```

BTF means **BPF Type Format**.

It provides type information for BPF programs and kernel data structures.

Conceptually:

```
BPF program
     │
     ▼
   BTF
     │
     ├── types
     ├── structures
     ├── fields
     └── metadata
```

BTF is particularly important for modern BPF tooling, debugging, CO-RE, and introspection.

---

## 15. The complete picture

Putting all of this together:

```
                         user-space
 ┌─────────────────────────────────────────────────────┐
 │                                                     │
 │  xdp-loader       xdpdump       xdp-monitor         │
 │       │              │                │             │
 │       └──────────────┼────────────────┘             │
 │                      │                              │
 │                   libxdp                            │
 │                      │                              │
 │                    libbpf                           │
 │                      │                              │
 └──────────────────────┼──────────────────────────────┘
                        │
                        ▼
                  Linux BPF API
                        │
                        ▼
 ┌─────────────────────────────────────────────────────┐
 │                     KERNEL                          │
 │                                                     │
 │                    XDP                              │
 │                     │                               │
 │              ┌──────▼──────┐                        │
 │              │ Dispatcher  │                        │
 │              └──────┬──────┘                        │
 │                     │                               │
 │             ┌───────┼───────┐                       │
 │             ▼       ▼       ▼                       │
 │           prog1   prog2   prog3                     │
 │             │       │       │                       │
 │             └───────┼───────┘                       │
 │                     │                               │
 │                 BPF maps                            │
 │                     │                               │
 └─────────────────────┼───────────────────────────────┘
                       │
                       ▼
                      NIC
```

---

## 16. Understanding xdp-tools:

Tu  **really understand xdp-tools**, suggested order is as below:

 1. **XDP fundamentals**
   - RX path
   - XDP actions
   - native vs generic vs offload
2. **`xdp-loader`**
   - load
   - unload
   - status
   - modes
   - dispatcher
3. **Write a tiny XDP program**
    Something as simple as:

   ```
   SEC("xdp")
   int xdp_pass(struct xdp_md *ctx)
   {
       return XDP_PASS;
   }
   ```
4. **Load it with `xdp-loader`**
5. **Use `xdpdump`**
   - observe packets
   - understand where XDP sees them
6. **Learn BPF maps**
7. **Learn `libxdp`**
8. **Learn AF\_XDP**
9. **Use `xdp-bench`**
   - measure what you've built
10. **Use `xdp-monitor`**
    - understand what's happening under the hood

---

## One particularly useful experiment

Once you've built xdp-tools, I'd suggest doing this on a **non-critical test interface**:

```
                    packet
                       │
                       ▼
                  ┌─────────┐
                  │ XDP     │
                  │ program │
                  └────┬────┘
                       │
                ┌──────┴──────┐
                │             │
             PASS            DROP
                │             │
                ▼             ✕
          Linux stack
```

 Make three tiny programs:

```
xdp_pass
xdp_drop
xdp_tx
```

Load each with `xdp-loader`, observe with `xdpdump`, inspect with `xdp-monitor`, and benchmark with `xdp-bench`.

That exercise makes the relationship between **XDP → libxdp → libbpf → kernel → NIC** much easier to understand than reading the source tree first.

And your configure output is actually a good starting point: **your clang, bpftool, libbpf, BTF, XDP attach/query, and BPF map capabilities are all detected**, so you're in a good position to explore the full stack.
