# Linux Traffic Control `tc`

- `tc` is the kernel system for controlling how pkts are *queued*, *scheduled*, *shaped*, *prioritized*
  *delayed*, *dropped*, or *classified* on NIC's 

- **`tc` is basically a programmable traffic pipeline attached to a network interface.** 

- Which means `tc` acts as a traffic cop and sorting facility sitting right between the OS's network stack
  and your physical NIC. 

Use case:

Suppose a server has 1 Gbit/s network interface, but you want:

    - limit one application to 100 Mbits/s. 
    - give SSH high priority over builk transfers.
    - precent a back from overwhelming other traffic.
    - simulate a slow/high-latency network. 
    - introduce a packet loss for testing. 
    - divide bandwidth among customers.
    - build shophisticated QoS policies. 

This is where `tc` comes in:

ex:
`tc qdisc add dev eth0 root tbf rate 100mbit burst 32kbit latency 400ms`

This says put a `tbf`: Token Bucket Filter on `eth0` and limit outgoing traffic to 100 Mbit/s. 

## How `tc` Operates: 

To understand `tc` you need to understand 3 core building blocks that work together:
1. Qdiscs ( Queueing Disciplines )
2. Classes
3. Filters ( Classifiers )

```
             packets
                │
                ▼
        ┌─────────────────┐
        │   classifier    │
        │ "which traffic?" │
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │      class      │
        │ "what treatment?"│
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │     qdisc       │
        │ "how do I queue?"│
        └────────┬────────┘
                 │
                 ▼
              NIC
```

These are not always present, but they are the core vocabulary. 

### Qdisc ( Queueing Discipline )

A qdisc determines what happens to packets waiting to leave an interface. 

Ex: `pfifo_fast`, `fq_codel`, `fq`, `htb`, `tbf`, `netem`, `cake` 

=> **qdisc = how pkts are queued and transmitted.**

The "buckets" or algorithms that hold and release pkts. 
Every interface has a default *qdisc*, which come in two flavors:
    - Classless: simple rules applied to all traffic equallt( dropping pkts when full, or basic fair queuing )
    - Classful: Adv struct that allows you to split traffic into different buckets ( classes ) with
      different guarantees. 

### Class:

A class is subdivision inside certain qdiscs, especially hierarchical onces.

Example: 
```txt 
    HTB
    ├── 100 Mbit/s total
    │
    ├── class 1:10 → 70 Mbit/s
    │
    └── class 1:20 → 30 Mbit/s

```
Classes allow you to create bandwidth hierarchies. 
Classes allow us to crave up your total bandwidth into smaller slices as show above.

### Filter:

A filter decided which packets go where. ( looking at IP address, Ports, protocol types, or firewall marks)
Filters inspect and decide which class or qdisc the pkt belongs to. 

Example:
```txt 
    destination port 22 → high-priority class
    destination port 443 → normal class
    everything else      → low-priority class
```

=> **Filter = classification**

## Shaping vs Policing:

### Shaping: 

Shaping **delays pkts** so traffic stays within a desired rate:

```
    Application
        │
        │  fast
        ▼
    ┌─────────┐
    │ shaper  │  ← holds packets
    └────┬────┘
         │
         │  controlled rate
         ▼
       network
```

Example:
```
tc qdisc add dev eth0 root tbf rate 100mbits burst 32kbit latency 400ms
```
The application generates traffic faster then 100 Mbits/s, but `tc` queues packets and releases them at
approximately 100 Mbit/s 

### Policing:

Policing generally says:
> If you are over the allowed rate, I'll drop packets. 

This is particularly useful for incoming traffic, because shaping incoming traffic is more complicated: 
By the time a packet arrives at your interface, it has already consumed the network capacity leading to you.


## Egress vs Ingress:


### Egress:

Traffic leaving the machine:
```text 
    Linux
      │
      │ egress
      ▼
    eth0 ─────────► Internet
```
This is where traditional `tc` shaping is easiest.

`tc qdisc add dev eth0 root ..... ` 


### Ingress: 

Traffic entering the system:

```text 
    Internet
       │
       ▼
    eth0 ────────► Linux
           ingress
```

You can attach an ingress qdisc and classify/policy traffic, but we can not hold an incoming pkt before it 
has traversed the physical link. 

For sophisticated ingress shaping, Linux commonly uses techniques such as IFB to redirect incoming traffic
through a virtual interface and shape it there.


## Examples: 

- Look at what qdisc are attached to a interface ( ) What a system is currently doing ): 
```
$ sudo tc qdisc show dev enp3s0
  qdisc fq_codel 0: root refcnt 2 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64

  or 
  qdisc mq 0: root
  qdisc fq_codel 0: parent :4 limit 10240p ...
  qdisc fq_codel 0: parent :3 limit 10240p ...
  ...
```

View statistics: 
```
$ tc -s qdisc show dev enp3s0
qdisc fq_codel 0: root refcnt 2 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
 Sent 48039638 bytes 177027 pkt (dropped 0, overlimits 0 requeues 807)
 backlog 0b 0p requeues 807
  maxpacket 12940 drop_overlimit 0 new_flow_count 94 ecn_mark 0
  new_flows_len 0 old_flows_len 0

```
This gives info on :
packets , bytes, drops, backlog, overlimits. 

This stats are useful for debugging.

## `tc` has hierarchy:

```
$ tc qdisc add dev eth0 root handle 1: htb default 20
```

This translates:
    `dev eth0`  operates on eth0 
    `root` Attach this as the root qdisc. 
    `handle 1:` Gives this qdisc an identifier `:1`.
    `htb` use hierarchical token bucket qdisc. 
    `default 20` traffic that isn't otherwise classified goes to class 1:20. 

So conceptually:
```text 
    eth0
     │
     ▼
    1: HTB
     │
     ├── 1:10
     │
     └── 1:20 ← default
```
        
**HTB**: Hierarchical Token Bucket commonly used when you want to divide bandwidth.
```
    tc qdisc add dev eth0 root handle 1: htb default 20

    tc class add dev eth0 parent 1: \
        classid 1:10 htb rate 70mbit ceil 100mbit

    tc class add dev eth0 parent 1: \
        classid 1:20 htb rate 30mbit ceil 50mbit
```

Give me 30 Mbit/s but I may use up to 50 Mbit/s when there's available capacity.

HTB: they dont know what traffic belongs to a class, this is what *filters* do:

```example: 
             packet
                │
                ▼
           ┌──────────┐
           │  flower  │
           │  filter  │
           └────┬─────┘
                │
          TCP dst port 22?
             /       \
           yes        no
            │          │
            ▼          ▼
          1:10        1:20

    tc filter add dev eth0 protocol ip parent 1: \
          prio 1 flower ip_proto tcp dst_port 22 \
          flowid 1:10
```
packets matching TCP destination port 22 are classified into: `1:10`

-> `tc` often used the *flower classifier* as it match lots of packet properties. 

```
1. tc filter add dev eth0 protocol ip parent 1: \
    flower src_ip 10.0.0.5 \
    flowid 1:10c filter add dev eth0 protocol ip parent 1: \
    flower src_ip 10.0.0.5 \
    flowid 1:10

2. tc filter add dev eth0 protocol ip parent 1: \
    flower dst_ip 192.168.1.100 \
    flowid 1:20
```
You can match things like:

SRC/DST IP, protocol, TCP/UDP ports , VLAN IDs, interfaces, DSCP, various pkt metadata. 
Exact capabilites depend on your kernel/iproute2 version.

## tc operates on pkts and not applications:

```
    Application
        │
        ▼
    socket
        │
        ▼
    TCP/UDP
        │
        ▼
    IP packet
        │
        ▼
    tc filter
        │
        ▼
    qdisc/class
        │
        ▼
       NIC
```

## `tc` in Network stack:

```text 
    Application
         │
         ▼
       socket
         │
         ▼
     TCP / UDP
         │
         ▼
         IP
         │
         ▼
     routing
         │
         ▼
     qdisc / tc
         │
         ▼
     driver
         │
         ▼
       NIC
         │
         ▼
     network
```

So `tc` is closely associated with the point where pkts are queued before transmission. 

For Inbound pkts:
```txt 
    network
       │
       ▼
     NIC
       │
       ▼
     driver
       │
       ▼
     ingress processing
       │
       ▼
     IP stack
       │
       ▼
     application
```

## Modern Linux networking ecosystem: 

```txt 
    tc
    │
    ├── qdiscs
    │   ├── fq
    │   ├── fq_codel
    │   ├── HTB
    │   ├── TBF
    │   ├── netem
    │   └── CAKE
    │
    ├── classifiers
    │   ├── flower
    │   └── u32
    │
    ├── actions
    │   ├── drop
    │   ├── mirred
    │   └── police
    │
    └── eBPF
        └── tc-BPF

```
XDP is related to pkt processing but operates much earlier in the receive path that ordinary `tc`
processing.

## tc + containers: 

You can have 
```txt 
                    Host
                     │
          ┌──────────┴──────────┐
          │                     │
       veth A                 veth B
          │                     │
       container A          container B
```

You can attach traffic control to a veth interface: And then its possible to implement policies such as:
```
container A => 100 Mbit/s
container B => 10 Mbit/s
```

Understanding Network namespace + veth + tc is so useful.

## quick recap:

```text 
                    tc
                     │
           ┌─────────┼─────────┐
           │         │         │
        FILTER     CLASS     QDISC
           │         │         │
     "which?"    "bucket?"  "queue how?"
           │         │         │
           └─────────┴─────────┘
                     │
                    NIC
```
And:
- Qdisc → how packets are queued/scheduled
- Class → bandwidth hierarchy
- Filter → determines which class gets a packet
- Shaping → delay packets
- Policing → typically drop packets that exceed a policy
- HTB → hierarchical bandwidth allocation
- TBF → simple rate limiting
- netem → emulate bad networks
- FQ-CoDel → control queueing delay/bufferbloat
- flower → flexible packet classification

Once those concepts are solid, most tc commands stop looking like random incantations.

--- 

# `tc` with SmartNICs


Working with ConnectX + eSwitch + legacy/switchdev + different topologies, Its important to learn `tc` 
from the perspective of packet forwarding and hardware offload, rather than from the usual Linux QoS 
perspective.

The key mental model is:

`tc` is a Linux interface for describing packet-processing rules.

On ConnectX, those rules can sometimes be translated/offloaded into the NIC's eSwitch hardware.

That distinction—Linux software path vs mlx5 hardware path—is the important part.

I'll build this from the ground up.

1. What exactly is tc?

`tc` stands for Traffic Control and is part of Linux's iproute2 suite.

Historically, tc was mainly used for:
    - traffic shaping, queues, scheduling, packet classification, policing

But today, tc is also an important programmable packet-processing interface, particularly for 
NIC hardware offloads.

Conceptually:

                    Linux
                      |
                      | tc
                      v
              +----------------+
              | qdisc / filter  |
              |    / action     |
              +----------------+
                      |
             +--------+--------+
             |                 |
        software           hardware
        processing         offload
             |                 |
             v                 v
        Linux kernel       NIC / eSwitch


For your ConnectX work, we're particularly interested in:

tc
 ├── qdisc
 ├── filter
 │    └── flower
 └── action
      ├── drop
      ├── mirred
      ├── redirect
      ├── vlan
      ├── tunnel_key
      └── ...


The most important combination to understand is:

tc filter ... flower ... action ...

2. The basic tc grammar

A useful way to think about a rule is:

tc filter add
       |
       +-- where?
       |
       +-- what packets?
       |
       +-- what do I do with them?


For example:

tc filter add dev eth0 ingress \
    protocol ip \
    flower dst_ip 10.0.0.10 \
    action drop


Read it as:

On eth0, for packets arriving at ingress, match IPv4 packets whose destination IP is 10.0.0.10, and drop them.

There are three fundamental pieces:

             MATCH                    ACTION
               |                        |
               v                        v
        +--------------+         +-------------+
packet ->| flower      |-------->| drop        |
        | dst_ip=...  |         +-------------+
        +--------------+
               ^
               |
             FILTER


Once this becomes intuitive, tc becomes much less mysterious.

3. qdisc: where does the rule live?

Before understanding filters, you need to understand qdiscs.

A qdisc is a queueing discipline.

For example:

tc qdisc show dev eth0


might show:

qdisc mq 0: root
qdisc fq_codel ...
...


Traditional qdiscs are about egress:

Application
    |
    v
 Linux networking
    |
    v
 +-----------+
 |   qdisc   |
 +-----------+
    |
    v
 NIC


But tc also gives us ingress hooks.

The important one for your use case is:

tc qdisc add dev eth0 clsact


clsact gives you two classifier locations:

                  eth0
                   |
        +----------+----------+
        |                     |
      ingress               egress
        |                     |
        v                     v
     filters               filters


So:

tc qdisc add dev eth0 clsact


is often the first command when experimenting with tc flower.

Then:

tc filter add dev eth0 ingress ...


means:

Apply this filter to packets entering eth0.

And:

tc filter add dev eth0 egress ...


means:

Apply this filter to packets leaving eth0.

4. flower: the important classifier

For ConnectX work, flower is probably the most important tc concept.

flower is a packet classifier.

It lets you describe packet fields such as:

Ethernet
 ├── src MAC
 ├── dst MAC
 └── VLAN

IP
 ├── src IP
 ├── dst IP
 ├── protocol

TCP/UDP
 ├── src port
 └── dst port


For example:

tc filter add dev eth0 ingress \
    protocol ip \
    flower \
    dst_ip 10.0.0.10 \
    action drop


You can make the match more specific:

tc filter add dev eth0 ingress \
    protocol ip \
    flower \
    src_ip 10.0.0.1 \
    dst_ip 10.0.0.10 \
    ip_proto tcp \
    dst_port 443 \
    action drop


This says:

                packet
                   |
                   v
          +----------------+
          | src IP         |
          | dst IP         |
          | TCP?           |
          | dst port 443?  |
          +----------------+
                   |
                  YES
                   |
                   v
                 DROP

5. flower is not doing the forwarding

This distinction is extremely important.

Consider:

tc filter add dev eth0 ingress \
    flower dst_ip 10.0.0.10 \
    action drop


flower answers:

Which packets?

action drop answers:

What should happen to them?

So think:

               tc filter
                   |
          +--------+--------+
          |                 |
       classifier         action
        flower              |
          |                 |
          v                 v
        MATCH              DROP


A more interesting example is:

tc filter add dev eth0 ingress \
    flower dst_ip 10.0.0.10 \
    action mirred egress redirect dev eth1


Now:

                  eth0
                   |
                   | ingress
                   v
              +----------+
              |  flower  |
              | dst_ip   |
              +----------+
                   |
                 match
                   |
                   v
               mirred
               redirect
                   |
                   v
                  eth1


This is where tc starts looking like a software switch.

6. mirred: one of the most important actions

For your ConnectX work, learn this command very well:

action mirred egress redirect dev <device>


It means roughly:

Redirect this packet to another network device.

Example:

tc filter add dev eth0 ingress \
    flower dst_ip 10.0.0.10 \
    action mirred egress redirect dev eth1


Conceptually:

              eth0
                |
                | packet
                v
          +-----------+
          |   flower  |
          | dst=...   |
          +-----------+
                |
                | match
                v
          +-----------+
          |  mirred   |
          | redirect  |
          +-----------+
                |
                v
              eth1


This is particularly interesting with representors.

7. Now connect this to ConnectX eSwitch

This is where things become much more interesting.

Suppose you have:

              ConnectX
          +----------------+
          |                |
wire <--> | PF0            |
          |                |
          |   eSwitch      |
          |                |
          | VF0            |
          | VF1            |
          +----------------+


The eSwitch is essentially an internal hardware switch.

The Linux representation can look like:

                Linux
                  |
       +----------+----------+
       |          |          |
      PF0        VF0        VF1
       |          |          |
       +----------+----------+
                  |
               eSwitch
                  |
                 wire


But in switchdev mode, the Linux host gets representor netdevices.

For example, conceptually:

                Linux
                  |
       +----------+----------+
       |          |          |
     uplink      rep0       rep1
       |          |          |
       +----------+----------+
                  |
              mlx5 eSwitch
                  |
            +-----+-----+
            |           |
           VF0         VF1


A representor is essentially the Linux-side handle through which software can control traffic associated with a particular eSwitch port.

NVIDIA's documentation explicitly describes representors as the mechanism used to represent PF/VF ports and configure the embedded switch. 
N
NVIDIA Docs
+1

And this is one of the fundamental differences between legacy and switchdev.

8. Legacy vs switchdev

The Linux mlx5 driver documentation describes the eSwitch as providing internal SR-IOV packet steering/switching, with legacy SR-IOV and switchdev as the two modes. 
L
Linux Kernel Documentation

Very roughly:

Legacy
                 ConnectX
              +-----------+
wire -------->| eSwitch   |
              |           |
              | PF        |
              | VF0       |
              | VF1       |
              +-----------+


The NIC firmware/driver handles things like:

MAC/VLAN steering
VF isolation
SR-IOV switching


The Linux host generally does not treat each eSwitch port as a normal switch port represented by a netdev.

Switchdev

Now:

                       Linux
                         |
              +----------+----------+
              |          |          |
            uplink      rep0       rep1
              |          |          |
              +----------+----------+
                         |
                    +---------+
                    | eSwitch |
                    +---------+
                    /         \
                   VF0        VF1


Now you can do things such as:

tc filter add dev rep0 ingress \
    flower ... \
    action mirred egress redirect dev rep1


And, when supported, mlx5 can translate that tc rule into an eSwitch hardware flow rule.

This is the key idea:

tc is the control-plane interface; the packet may never actually traverse the Linux software implementation of that rule.

9. Software vs hardware offload

This is probably the single most important concept for your work.

Consider:

tc filter add dev eth0 ingress \
    protocol ip \
    flower dst_ip 10.0.0.10 \
    action drop


There are potentially two implementations.

Software
packet
  |
  v
NIC
  |
  v
Linux kernel
  |
  v
tc flower
  |
  v
drop

Hardware offload
packet
  |
  v
ConnectX
  |
  v
mlx5 eSwitch
  |
  +---- flower rule
  |
  +---- drop


In the second case:

packet
   |
   | never reaches host networking stack
   |
   v
NIC hardware


This is why tc is so relevant to SmartNIC/DPU/NIC switching.

10. skip_sw and skip_hw

These two options are extremely useful.

skip_sw
flower ... skip_sw


means:

Do not install this rule in the software datapath. It must be offloaded to hardware.

For example:

tc filter add dev rep0 ingress \
    protocol ip \
    flower dst_ip 10.0.0.10 \
    skip_sw \
    action drop


This is very useful when testing ConnectX hardware offload.

If hardware cannot support the rule, you want it to fail rather than silently falling back to software.

skip_hw

Conversely:

flower ... skip_hw


means:

Do not offload this rule; keep it in software.

This is useful when debugging.

So:

             tc rule
                |
       +--------+--------+
       |                 |
    skip_sw            skip_hw
       |                 |
       v                 v
    hardware          software


Without either option, the driver may choose to offload when possible.

11. How to see whether something was offloaded

This is where tc becomes very useful.

Run:

tc -s filter show dev rep0 ingress


You might see something like:

filter protocol ip pref 10 flower chain 0
filter protocol ip pref 10 flower chain 0 handle 0x1
  eth_type ipv4
  dst_ip 10.0.0.10
  skip_sw
  in_hw
        action order 1: gact action drop
         index 1 ref 1 bind 1
         installed 1 sec
         Action statistics:
         Sent 1000 bytes 10 pkt


The important word is:

in_hw


That tells you the rule is installed in hardware.

You may also see:

not_in_hw


which is obviously important when troubleshooting.

12. tc -s is your friend

Always learn to use:

tc -s filter show dev <interface> ingress


The -s means statistics.

For example:

tc -s filter show dev rep0 ingress


You can use packet/byte counters to answer:

Is my rule actually seeing traffic?

This becomes incredibly valuable when debugging an eSwitch topology.

13. A simple lab

Let's forget ConnectX for a moment.

Imagine:

eth0 ---- Linux ---- eth1


Create a clsact:

tc qdisc add dev eth0 clsact


Add a rule:

tc filter add dev eth0 ingress \
    protocol ip \
    flower dst_ip 10.10.10.10 \
    action drop


Look at it:

tc filter show dev eth0 ingress


Then with counters:

tc -s filter show dev eth0 ingress


Delete it:

tc filter del dev eth0 ingress


Remove clsact:

tc qdisc del dev eth0 clsact


That's the basic lifecycle:

CREATE
   |
   v
qdisc
   |
   v
filter
   |
   v
match
   |
   v
action
   |
   v
inspect
   |
   v
delete

14. The syntax you should memorize

Don't memorize hundreds of options.

Memorize this structure:

tc filter add dev DEV \
    ingress \
    protocol PROTO \
    flower MATCH_FIELDS \
    action ACTION


For example:

tc filter add dev eth0 ingress \
    protocol ip \
    flower \
    src_ip 192.168.1.10 \
    dst_ip 192.168.2.10 \
    ip_proto tcp \
    dst_port 443 \
    action drop


Or:

tc filter add dev eth0 ingress \
    protocol ip \
    flower \
    dst_ip 192.168.2.10 \
    action mirred egress redirect dev eth1

15. Matching Ethernet

You can match MAC addresses:

tc filter add dev eth0 ingress \
    protocol all \
    flower \
    src_mac 00:11:22:33:44:55 \
    dst_mac aa:bb:cc:dd:ee:ff \
    action drop


Conceptually:

Ethernet frame

+-------------------+
| dst MAC           |
+-------------------+
| src MAC           |
+-------------------+
| EtherType         |
+-------------------+
| payload           |
+-------------------+


flower can inspect those fields.

16. Matching VLAN

For example:

tc filter add dev eth0 ingress \
    protocol 802.1Q \
    flower \
    vlan_id 100 \
    action drop


You can also match VLAN priority, encapsulation, etc., depending on the driver/kernel support.

This is especially relevant to eSwitch rules because VLAN/MAC steering is a common part of NIC switching.

17. Matching IPv4

Typical fields:

flower \
    src_ip 10.0.0.1 \
    dst_ip 10.0.0.2 \
    ip_proto tcp


You can think of this as:

             IPv4 header

+---------------------------+
| src_ip     10.0.0.1       |
+---------------------------+
| dst_ip     10.0.0.2       |
+---------------------------+
| protocol   TCP             |
+---------------------------+

18. Matching TCP/UDP

Example:

tc filter add dev eth0 ingress \
    protocol ip \
    flower \
    ip_proto tcp \
    dst_port 443 \
    action drop


Or UDP:

tc filter add dev eth0 ingress \
    protocol ip \
    flower \
    ip_proto udp \
    dst_port 4791 \
    action drop


That second example is particularly interesting in RDMA environments because UDP/4791 is the conventional RoCEv2 destination port.

19. Multiple matches = AND

This is an important rule.

Consider:

flower \
    src_ip 10.0.0.1 \
    dst_ip 10.0.0.2 \
    ip_proto tcp \
    dst_port 443


This means:

src_ip == 10.0.0.1
       AND
dst_ip == 10.0.0.2
       AND
protocol == TCP
       AND
dst_port == 443


Not OR.

So:

flower
  |
  +-- src_ip
  |
  +-- dst_ip
  |
  +-- protocol
  |
  +-- port
  |
  v
 ALL must match

20. Priorities

You can have multiple filters.

For example:

tc filter add dev eth0 ingress \
    pref 10 \
    protocol ip \
    flower dst_ip 10.0.0.10 \
    action drop


and:

tc filter add dev eth0 ingress \
    pref 20 \
    protocol ip \
    flower dst_ip 10.0.0.0/24 \
    action mirred egress redirect dev eth1


pref gives you ordering.

Generally:

pref 10
   |
pref 20
   |
pref 30


Lower preference number is evaluated first.

This becomes particularly important when you start using chains.

21. Chains

This is where tc begins to resemble a real programmable switch pipeline.

Instead of:

ingress
   |
   v
filter
   |
   v
action


you can have:

                    ingress
                       |
                       v
                  chain 0
                       |
                 +-----+-----+
                 |           |
              match       match
                 |           |
                 v           v
              chain 10   chain 20
                 |           |
                 v           v
               action      action


For example:

tc filter add dev eth0 ingress \
    chain 10 \
    protocol ip \
    flower dst_ip 10.0.0.10 \
    action drop


Chains become very important when dealing with sophisticated hardware pipelines.

Don't worry about mastering them yet.

22. The big connection to eSwitch

Now let's put everything together.

Suppose:

                    ConnectX
               +----------------+
               |                |
wire ----------| uplink         |
               |                |
               |   eSwitch      |
               |    /    \      |
               |   /      \     |
               | VF0      VF1   |
               +----------------+


Switchdev exposes something conceptually like:

                Linux netdevs

                  pf0
                   |
             uplink representor

                  rep0
                   |
              VF0 representor

                  rep1
                   |
              VF1 representor


You can install:

tc filter add dev rep0 ingress \
    protocol ip \
    flower dst_ip 10.0.0.20 \
    skip_sw \
    action mirred egress redirect dev rep1


Conceptually:

                    ConnectX
                       |
                       |
                  +---------+
                  | eSwitch |
                  +---------+
                   ^       ^
                   |       |
                 rep0    rep1
                   |       |
                  VF0     VF1


The Linux command describes:

             rep0 ingress
                  |
               MATCH
                  |
          dst_ip = 10.0.0.20
                  |
               REDIRECT
                  |
                 rep1


The mlx5 driver can translate that into the hardware steering representation.

That's the part I suspect you actually care about.

23. tc is not the eSwitch

This distinction is worth emphasizing.

You have several layers:

             User space
                 |
                 |
                tc
                 |
                 v
          Linux networking
                 |
                 |
              mlx5 driver
                 |
                 v
          mlx5 hardware
                 |
                 v
             eSwitch
                 |
                 v
          ConnectX ASIC


tc is not the eSwitch.

tc is one mechanism by which you tell Linux:

"I want this packet-processing rule."

The mlx5 driver can then say:

"I can implement this rule in the ConnectX hardware."

and install an appropriate hardware flow rule.

24. What happens to a packet?

This is the mental model I'd recommend you keep in your head.

Suppose:

wire
 |
 | packet
 v
ConnectX
 |
 | hardware steering
 v
eSwitch
 |
 +---- does packet match an offloaded tc rule?
 |
 +---- YES ---> action
 |
 +---- NO ----> normal/default path


For an offloaded rule:

packet
   |
   v
NIC parser
   |
   v
match fields
   |
   v
flow table
   |
   +---- dst_ip == X
   |
   v
redirect to VF/representor/etc.


The host CPU doesn't necessarily see that packet.

This is why you can get extremely high packet rates even though you're using a Linux tc command.

25. Why skip_sw is so useful for ConnectX debugging

Imagine:

tc filter add dev rep0 ingress \
    flower dst_ip 10.0.0.10 \
    skip_sw \
    action mirred egress redirect dev rep1


If it succeeds and you see:

in_hw


you know:

tc
 |
 v
mlx5
 |
 v
ConnectX hardware


accepted the rule.

If you get an error, that's useful information.

It may mean:

unsupported match
unsupported action
unsupported topology
unsupported offload
wrong device
wrong mode


rather than silently giving you a software implementation.

26. A very useful debugging workflow

When working on a ConnectX topology, I recommend this sequence.

Step 1 — Identify the PCI devices
lspci -nn | grep -i mellanox

Step 2 — Identify netdevs
ip -br link

Step 3 — Inspect mlx5 devices
devlink dev show

Step 4 — Check eSwitch mode
devlink dev eswitch show


You might see:

pci/0000:xx:00.0: mode switchdev ...


or:

pci/0000:xx:00.0: mode legacy ...


NVIDIA's current documentation uses devlink dev eswitch show and devlink dev eswitch set ... mode switchdev/legacy for this. 
N
NVIDIA Docs
+1

Step 5 — Look for representors
ip -d link show


The detailed output can expose things such as:

portname pf0vf1
switchid ...


which NVIDIA documents as useful for mapping representors to PF/VF ports. 
N
NVIDIA Docs

Step 6 — Create clsact
tc qdisc add dev <representor> clsact

Step 7 — Install a simple rule
tc filter add dev <representor> ingress \
    protocol ip \
    flower dst_ip 10.0.0.10 \
    skip_sw \
    action drop

Step 8 — Inspect
tc -s filter show dev <representor> ingress


Look for:

in_hw


and packet counters.

27. The four things I want you to mentally separate

When you're looking at a command like:

tc filter add dev rep0 ingress protocol ip \
    flower dst_ip 10.0.0.10 \
    skip_sw \
    action mirred egress redirect dev rep1


break it into four questions:

① Where?
dev rep0 ingress


Which interface and which direction?

② What?
flower dst_ip 10.0.0.10


Which packets?

③ Where should it execute?
skip_sw


Hardware only.

④ What should happen?
action mirred egress redirect dev rep1


Redirect to rep1.

That's the fundamental tc grammar.

28. tc vs iptables/nftables

It's useful to understand why tc is interesting here.

iptables/nftables are primarily designed around the Linux networking stack:

                 packet
                   |
                   v
             Linux network
                   |
             nftables
                   |
                   v
                 stack


tc can operate at a lower networking layer:

             packet
                |
                v
              NIC
                |
              tc
                |
        +-------+-------+
        |               |
      kernel         hardware
                    offload


That makes tc particularly useful for:

NIC switching
SR-IOV
representors
switchdev
hardware flow steering
OVS hardware offload
SmartNIC/DPU datapaths
29. One subtle but important point

Don't assume:

tc command succeeded


means:

rule is in hardware


Those are different questions.

Always distinguish:

RULE EXISTS
     vs
RULE IS OFFLOADED


For example:

tc filter show dev rep0 ingress


answers roughly:

Does the Linux tc rule exist?

Whereas:

tc -s filter show dev rep0 ingress


and the presence of:

in_hw


helps answer:

Is it installed in hardware?

This distinction will save you a lot of debugging time.

30. The learning path I'd recommend for you

Since your goal isn't generic Linux traffic shaping, I'd learn tc in this order:

                 tc
                  |
       +----------+----------+
       |                     |
     basic                 eSwitch
       |                     |
       v                     v
    qdisc                 switchdev
       |                     |
       v                     v
    clsact                representor
       |                     |
       v                     v
   ingress                flower
       |                     |
       v                     v
     filter                action
                             |
                    +--------+--------+
                    |                 |
                 redirect           drop
                    |
                    v
                 mirred
                    |
                    v
               hardware offload
                    |
                    v
                  mlx5
                    |
                    v
                 eSwitch


Then move into:

flower
mirred
skip_sw / skip_hw
in_hw
representors
chains
goto chain
VLAN actions
tunnel actions
connection tracking
OVS → tc → mlx5 offload
hardware steering architecture
31. The most important conceptual picture

If you remember only one picture from this tutorial, make it this:

                         USER SPACE
                             |
                             | tc
                             v
                    +------------------+
                    | Linux TC         |
                    |                  |
                    | filter           |
                    |  + flower        |
                    |  + action        |
                    +--------+---------+
                             |
                             | mlx5 driver
                             v
                    +------------------+
                    | ConnectX         |
                    |                  |
                    |  Hardware        |
                    |  steering        |
                    +--------+---------+
                             |
                             v
                       +-----------+
                       | eSwitch   |
                       +-----------+
                         /   |   \
                        /    |    \
                      PF    VF0   VF1
                             ^
                             |
                       representor
                             |
                         Linux netdev


Once you understand this diagram, commands such as:

tc filter add dev enp8s0f0_0 \
    ingress \
    protocol ip \
    flower dst_ip 7.7.7.7 \
    action mirred egress redirect dev enp8s0f1


stop looking like cryptic tc syntax and start looking like:

                  MATCH
                    |
             dst_ip == 7.7.7.7
                    |
                    v
               REDIRECT
                    |
                    v
                enp8s0f1


NVIDIA's own MLNX_EN documentation uses essentially this kind of tc flower + mirred rule in its switchdev examples. 
N
NVIDIA Docs

Where I'd go next

Given your specific work with ConnectX topologies, I think a generic tc tutorial is only the first layer. The really useful next tutorial would be:

tc flower + ConnectX eSwitch deep dive, starting with a concrete topology such as:

                         ConnectX
                    +----------------+
                    |                |
       wire <------>| PF0/uplink     |
                    |      |         |
                    |   eSwitch      |
                    |    /   \       |
                    |   VF0  VF1      |
                    +----|----|------+
                         |    |
                        rep0 rep1
                         |    |
                         +----+


and then trace one packet end-to-end through:

wire
 → ConnectX parser
 → eSwitch
 → representor
 → tc ingress
 → flower
 → mirred redirect
 → eSwitch
 → VF


Then we can compare the exact same topology in legacy mode vs switchdev mode, including what exists as a Linux netdev, what exists only inside the ASIC, what tc actually controls, and where the mlx5 driver inserts the rule. That is the part that will make the different ConnectX topologies much easier to reason about.

Sources:
- https://docs.kernel.org/next/networking/device_drivers/ethernet/mellanox/mlx5/kconfig.html
- https://docs.nvidia.com/doca/archive/doca-v2.2.0/switching-support/index.html

---

# CX + tx : Control plane framework:

It's primarily the mlx5 driver, with tc/Linux providing the control-plane framework.

The Linux networking stack does not itself translate a tc flower rule into ConnectX hardware instructions.

Think of the path as:

                  User
                   |
                   | tc filter add ...
                   v
             +-------------+
             |   tc /      |
             | Linux TC    |
             +-------------+
                   |
                   | kernel API
                   v
             +-------------+
             |   mlx5      |
             |   driver    |  <--- THIS does the hardware-specific work
             +-------------+
                   |
                   | mlx5 commands
                   v
             +-------------+
             | ConnectX HW |
             | flow tables |
             | eSwitch     |
             +-------------+

More precisely

When you run:

tc filter add dev rep0 ingress \
    protocol ip \
    flower dst_ip 10.0.0.10 \
    skip_sw \
    action mirred egress redirect dev rep1


there are several layers involved.

1. tc parses your request

The tc userspace program constructs a netlink message describing:

device = rep0
hook = ingress

classifier = flower
    dst_ip = 10.0.0.10

action = mirred
    redirect -> rep1

flags:
    skip_sw


It sends that to the kernel through Netlink.

2. Linux TC subsystem receives it

Inside the kernel, the generic TC infrastructure handles things like:

TC
 |
 +-- classifier framework
 |      |
 |      +-- flower
 |
 +-- action framework
 |      |
 |      +-- mirred
 |
 +-- device driver offload interface


This part is generic Linux infrastructure.

The kernel understands what a flower classifier and mirred action mean.

But Linux doesn't know how to program:

ConnectX flow table #37
FTE
modify-header
eswitch vport
mlx5 steering domain


That's hardware-specific.

3. The mlx5 driver gets involved

This is the important part.

The mlx5 driver registers support for TC offload with the kernel's TC infrastructure.

Conceptually:

              TC core
                 |
                 | "Can you offload this?"
                 v
              mlx5
                 |
          +------+------+
          |             |
       supported?    unsupported?
          |             |
          v             v
       hardware       software


The mlx5 driver examines the TC rule.

For example:

flower:
    dst_ip = 10.0.0.10

action:
    redirect -> rep1


The driver converts those generic TC concepts into mlx5-specific hardware steering objects.

So:

TC flower
    |
    | mlx5 translation
    v
mlx5 hardware flow rule


This is why the driver is the crucial piece.

4. What does the kernel actually do?

The kernel provides the framework and API.

You can roughly divide responsibilities like this:

Component	Responsibility
tc userspace	Express the desired rule
TC core	Generic classifier/action/offload framework
flower	Generic packet-match representation
mirred	Generic redirect/mirror action
mlx5 driver	Translate generic rule → ConnectX-specific rule
ConnectX firmware/hardware	Actually execute the rule

So if you ask:

"Does Linux kernel network stack perform the hardware offload?"

I'd say:

No, not in the sense of implementing the hardware offload.

The kernel's TC subsystem coordinates it, but the mlx5 driver implements the ConnectX-specific offload.

5. And there's an important distinction: software TC vs hardware TC

Without offload:

packet
  |
  v
NIC
  |
  v
Linux kernel
  |
  v
TC ingress
  |
  v
flower
  |
  v
mirred
  |
  v
another interface


Here the Linux kernel actually processes the packet.

With ConnectX hardware offload:

                         CONTROL PLANE
                              |
tc filter ----------------> Linux
                              |
                              v
                           mlx5
                              |
                              v
                         ConnectX HW
                              |
                              |
                         FLOW RULE
                              |
                              |
                         DATA PLANE
                              |
packet ---------------------> eSwitch
                                |
                                v
                              VF/VF


The packet can bypass the host kernel entirely.

That's the beauty of this architecture.

6. skip_sw makes this especially obvious

Suppose:

tc filter add dev rep0 ingress \
    flower dst_ip 10.0.0.10 \
    skip_sw \
    action drop


skip_sw effectively tells the TC infrastructure:

Do not install a software version of this rule. I require hardware offload.

The TC framework asks the driver to offload it.

Conceptually:

TC
 |
 | skip_sw
 v
mlx5 driver
 |
 +-- "Can ConnectX implement this?"
 |
 +-- YES --> program hardware
 |
 +-- NO  --> fail


That's very useful for experiments because otherwise you might accidentally think:

"My TC rule works, therefore the NIC is doing it."

It may actually be working in software.

7. What about in_hw?

This is the other half of the story.

When you run:

tc -s filter show dev rep0 ingress


and see:

in_hw


that's evidence that the driver successfully installed the rule into hardware.

So:

tc command
    |
    v
TC core
    |
    v
mlx5 driver
    |
    v
ConnectX
    |
    v
hardware rule
    |
    v
TC reports:
    in_hw

8. But there's another layer: firmware

For ConnectX, don't think of it simply as:

Linux kernel
    ↓
ASIC


There is also the NIC firmware / device command interface.

A simplified picture is:

                 Linux
                   |
                  tc
                   |
                   v
             TC subsystem
                   |
                   v
              mlx5 driver
                   |
                   | mlx5 device commands
                   v
            ConnectX firmware
                   |
                   v
              HW steering
                   |
                   v
                eSwitch
                   |
                   v
             ConnectX ASIC


The exact internal implementation is more complicated, but this is the right conceptual model.

9. And this explains switchdev

This is where your original question about legacy vs switchdev becomes really important.

In switchdev:

Linux
 |
 +-- PF netdev
 |
 +-- uplink representor
 |
 +-- VF representor
 |
 +-- VF representor
 |
 +-- ...
 |
 +-- tc
       |
       v
     mlx5
       |
       v
   eSwitch HW


The representors provide Linux netdevices corresponding to eSwitch ports.

So when you say:

tc filter add dev rep0 ...


you're effectively telling Linux:

"Install a forwarding/processing rule associated with this eSwitch port."

The mlx5 driver understands that rep0 corresponds to a particular hardware vport and programs the eSwitch accordingly.

10. This is why I would not think of tc as a packet-processing engine

This is a subtle but important mental shift.

Don't think:

tc = packet processing


Think:

tc = packet-processing RULE INTERFACE


It can describe:

MATCH:
    MAC
    VLAN
    IPv4
    IPv6
    TCP
    UDP
    tunnel fields
    ...

ACTION:
    drop
    redirect
    mirror
    modify
    VLAN operations
    tunnel operations
    ...


Then the implementation can be:

             TC rule
                |
       +--------+---------+
       |                  |
       v                  v
    software           hardware
       |                  |
 Linux kernel          mlx5 driver
                          |
                          v
                     ConnectX HW

11. One analogy

Think of tc like a SQL query.

You write:

SELECT ...
WHERE dst_ip = '10.0.0.10';


The SQL language doesn't know how your database internally implements the query.

Likewise:

flower dst_ip 10.0.0.10


doesn't inherently know how a ConnectX ASIC implements that match.

The mlx5 driver is analogous to the database-specific execution layer:

generic TC rule
       |
       v
mlx5 interpretation
       |
       v
ConnectX-specific hardware programming

The key answer

So, if you ask:

"Who provides ConnectX NIC hardware offloading using tc—the Linux network stack or the driver?"

The best answer is:

The Linux kernel TC subsystem provides the generic offload framework; the mlx5 driver provides the ConnectX-specific hardware offload implementation; the ConnectX hardware/firmware executes the resulting rule.

Or in one line:

tc = WHAT you want
TC core = framework
mlx5 = HOW ConnectX can do it
ConnectX = WHERE it executes


And this is exactly why the same tc flower command can work in software on one NIC, be hardware-offloaded on another NIC, or fail with skip_sw depending on what the driver/hardware supports.

The next piece I'd recommend understanding is the actual kernel call path—from tc filter add → Netlink → cls_flower → ndo_setup_tc() / TC offload API → mlx5e → mlx5 flow steering → eSwitch FDB. That will make the architecture completely concrete.



