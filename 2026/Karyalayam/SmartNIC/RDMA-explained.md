# RDMA:

Remote DMA: A specialized networking technology that allows computers to exchange data directly 
between there application memories over a network without involving either CPU/OS or cache. 

**How RDMA Works**:

- **kernel bypass**: Data moves straight from application space to the network card, skipping OS's 
  software layer and network stack.
  
- **Zero-Copy**: The NIC transfers bytes directly from sender's memory to the receiver's memory, 
  eliminating intermediate copying steps.
  
- **No CPU interruptions**: The main processor is left free to focus 100% of its resources on 
  computing tasks rather then processing network pkts. 
  
**Benifits**:

- Ultra-Low Latency: Cuts down communication delays to fractions of a microsecond.
- High Throughput: Maximizes available network bandwidth for massive data streams.
- High Efficiency: Consumes almost zero CPU overhead during transfers.

RDMA defines How the two RDMA NICs communicate, but the bits still require a physical network. 
There are several possible networks:

```text 
    RDMA
    │
    ├── InfiniBand
    ├── RoCE
    └── iWARP
```
=> RDMA is like language
=> IB, RoCE, iWARP are different services that deliver messages in that language. 

**Common Standards and Use cases**
- InfiniBand: A native HW technology built entirely for high-performance computing (HPC) and RDMA.
- RoCEv2 (RDMA over Converged Ethernet): Encapsulates RDMA inside standard UDP/IP packets so it can run 
  across typical enterprise data center Ethernet switches.
- AI & Machine Learning: Widely used to move massive datasets quickly between high-powered GPUs during
  multi-node AI training. 
  
--- 

## The problem RDMA solves

Imagine two computers connected by a network:

```text
Computer A                    Computer B
+-----------+                +-----------+
| CPU       |                | CPU       |
| Memory    |                | Memory    |
| NIC       |<-------------> | NIC       |
+-----------+                +-----------+
```

Suppose Computer A wants to send 1 MB of data to Computer B.

### Traditional networking

With TCP/IP, the data takes a long path:

```text
        Application
            │
            ▼
        Kernel
            │
        TCP/IP stack
            │
           NIC
~~~~~~~ Network ~~~~~~~~
           NIC
            │
        Kernel
            │
        TCP/IP stack
            │
        Application
```

On the receiving side:

1. The NIC receives the packet.
2. The CPU is interrupted.
3. The kernel processes the packet.
4. The kernel copies the data into an application buffer.
5. The application can finally use it.

The CPU and operating system are heavily involved.

---

## RDMA takes a different approach

RDMA asks:

> "Why involve the remote CPU just to move data into memory?"

Instead, the remote computer says:

> "Here's a region of my memory. You are allowed to write here."

Then Computer A can directly place data into that memory.

```text
Computer A                    Computer B

Application
      │
      ▼
 RDMA NIC  ==================>  RDMA NIC
                                   │
                                   ▼
                             Memory Buffer
```

Notice that the **remote CPU isn't involved in the data transfer itself**.

---

## What makes this possible?

The remote machine doesn't expose all of its memory. 
It must first **register** a memory region with its RDMA NIC.

For example:

```text
        Memory

        +-----------------------+
        | OS Memory             |
        +-----------------------+
        | Application Memory    |
        +-----------------------+
        | RDMA Buffer           |  <-- Registered
        +-----------------------+
```

Only that registered buffer can be accessed remotely.

The RDMA NIC enforces these permissions.

---

## The three main RDMA operations

### 1. RDMA Write

Computer A writes directly into Computer B's memory.

```text
    A Memory  ------------->  B Memory
```

B's CPU doesn't have to receive or copy the data.

---

### 2. RDMA Read

Computer A reads data directly from Computer B's memory.

```text
    A Memory  <-------------  B Memory
```

Again, B's CPU doesn't perform the data movement.

---

### 3. Send/Receive

This is more like traditional messaging.

Computer A sends a message, and Computer B has already posted a receive buffer.

```text
A Send  ------------->  B Receive Buffer
```

The transfer is still handled efficiently by the RDMA hardware.

---

## Why is this faster?

Traditional networking:

```text
          NIC
           ↓
         Kernel
           ↓
          CPU
           ↓
          Copy
           ↓
      Application
```

RDMA:

```text
        NIC 
         ↓
  Application Memory
```

By avoiding multiple software layers and copies, RDMA reduces latency and CPU overhead.

---

## An analogy

Imagine two warehouses.

**Traditional networking:**

1. Truck arrives.
2. Workers unload boxes.
3. Supervisor checks everything.
4. Workers move boxes into storage.

**RDMA:**

The destination warehouse reserves a storage area and gives the truck permission to place boxes directly there.

The warehouse manager (the CPU) doesn't have to supervise every box.

---

## The key idea

RDMA is **not just a faster network**. 
It's a different communication model.

Instead of saying:

> "Send me this data."

you're effectively saying:

> "Here's a memory location you're authorized to access. Read from it or write to it directly."

That ability to access remote memory with minimal CPU involvement is what "Remote Direct Memory Access" means.

Next question: **"How do the RDMA-capable NICs communicate over a network?"** 
That's where transports such as **RoCE**, **InfiniBand**, and **iWARP** come in.

--------------------

## HW Point of View:

That's exactly the right question. In fact, **RDMA doesn't really make sense until you understand what the NICs
are doing.** The magic is in the **RDMA-capable NIC (RNIC)**.

Let's go through it from the hardware's point of view.

---

### Step 1: Normal Ethernet NIC

A normal NIC doesn't understand your application.

Suppose you do:

```c
    send(sock, buffer, 4096);
```

The NIC only knows:

> "Here's a packet to transmit."

On the receiving side:

```
    Packet arrives
        │
        ▼
 NIC DMA copies packet into kernel memory
        │
    Interrupt CPU
        │
    Kernel processes TCP/IP
        │
    Copy to application
```

The NIC's job is basically:

* transmit packets
* receive packets
* calculate checksums
* maybe some offloads

The CPU does the rest.

---

### Step 2: RDMA NIC (RNIC)

An RNIC is much smarter.

Instead of only understanding Ethernet packets, it understands RDMA operations.

For example:

```
    WRITE
    Remote Address = 0x200000
    Length = 4096
```

or

```
    READ
    Remote Address = 0x800000
    Length = 8192
```

These are **RDMA commands**, not just raw bytes.

---

### Step 3: Before communication starts

The two machines first establish an RDMA connection and exchange information such as:

* memory address
* memory key (called an **rkey**)
* queue information
* queue pair numbers

For example:

Machine B says:

```
You may write here:

    Address = 0x10000000
    Length  = 1 MB
    rkey    = 0x12345678
```

Think of the **rkey** as a capability or access token. 
It authorizes access to that registered memory region.

---

### Step 4: Machine A wants to write

The application doesn't build Ethernet packets itself.

Instead, it tells the RNIC:

```
Write

    Local buffer:
    0x500000

    Remote buffer:
    0x10000000

    Length:
    4096 bytes

    rkey:
    0x12345678
```

This instruction is placed into a **work queue**.

```
    Application
        │
        ▼
    Work Queue
        │
        ▼
      RNIC
```

The RNIC now takes over.

---

### Step 5: The RNIC builds RDMA packets

The RNIC creates packets that include information like:

```
    Operation = WRITE

    Remote Address

    Length

    rkey

    Payload
```

These packets travel across the network.

This is where different transports come into play:

* InfiniBand
* RoCE
* iWARP

Each transport defines **how these RDMA packets are carried**.

---

### Step 6: Receiving RNIC

The receiving RNIC gets the packet.

It doesn't ask the CPU what to do.

Instead, it checks:

```
    Is the rkey valid?

    Is this memory registered?

    Does the address match?

    Is the sender allowed?
```

If everything is valid:

```
   DMA Engine

    Packet
      │
      ▼
    Memory
```

The RNIC uses its DMA engine to write the data directly into system memory.

The CPU is not involved in copying the data.

---

### Step 7: Completion

Once finished, the RNIC places a completion entry into a **Completion Queue (CQ)**.

The application later checks:

```
    Write completed.
```

Often this is done by polling the completion queue rather than taking an interrupt, 
which further reduces latency.

---

### Putting it together

```
    Application
        │
        ▼
    Post RDMA Write
        │
        ▼
       RNIC
        │
    Creates RDMA packet
        │
    Ethernet / InfiniBand
        │
    Receiving RNIC
        │
    Checks permissions
        │
    DMA Engine
        │
    Writes directly into RAM
```

Notice that the receiving CPU never has to execute a `recv()` call or copy the data into the 
application's buffer.

---

### So where does RoCE fit?

Now we're ready for the missing piece.

The packet the RNIC creates is an **RDMA packet**. That packet still has to travel over some physical network.

If the network is:

* **InfiniBand**, the packet uses the InfiniBand link-layer protocol.
* **RoCE**, the packet is encapsulated for transport over Ethernet.
* **iWARP**, the packet is carried over TCP/IP.

The **RDMA command itself doesn't change**. A WRITE is still a WRITE, and a READ is still a READ. 
What changes is **how that command is packaged and transported** across the network.

An analogy is sending a letter:

* The **letter's content** is the RDMA operation ("write these 4096 bytes to this memory address").
* The **delivery service** is the transport.

  * InfiniBand is one delivery service.
  * RoCE is another, using Ethernet.
  * iWARP is another, using TCP/IP.

So when people say "we use RoCE," they mean **the RNICs are exchanging RDMA messages over an Ethernet network**.

A natural next step is to look at **the exact format of an RDMA WRITE packet over RoCE v2**, 
tracing it from the application to the Ethernet frame on the wire. 

That makes the relationship between RDMA and RoCE very concrete.

---------------------------------------------------------------------------

This is where everything starts to click. 

We'll follow **one RDMA Write operation** from the application all the way to the Ethernet wire.

We'll assume we're using **RoCE v2**, since it's the most common RDMA deployment on Ethernet today.

## The Setup

We have two servers:

```text
        Server A                              Server B
    +----------------+                  +----------------+
    | Application    |                  | Application    |
    |                |                  |                |
    | RAM            |                  | RAM            |
    | RNIC           |==================| RNIC           |
    +----------------+   Ethernet       +----------------+
```

Before any RDMA operation can occur, some setup has already happened.

### Step 1: Register Memory

The application on Server B allocates a buffer:

```c
    char buffer[4096];
```

To the CPU, this is just ordinary memory.

Now the **application asks** the RNIC:

> "Please register this memory for RDMA."

The RNIC and operating system cooperate to:

* Pin the pages (prevent them from being swapped out)
* Record their physical addresses
* Create a protection entry
* Generate an **rkey (Remote Key)**

Now the RNIC has an internal table like this:

| Virtual Address | Length | rkey       |
| --------------- | ------ | ---------- |
| 0x10000000      | 4096   | 0xABCD1234 |

This table exists **inside the RNIC driver/hardware**.

---

### Step 2: Exchange Connection Information

Server A cannot magically know:

* where the buffer is
* what the rkey is
* which queue pair to use

So the applications exchange this information using some ordinary communication channel.

This might be:

* TCP socket
* gRPC
* MPI
* Custom protocol

Server B sends something like:

```text
    Remote Address = 0x10000000
    Length         = 4096
    rkey           = 0xABCD1234
    QP Number      = 42
```

Notice something important:

> **RDMA does not define how this exchange happens.**

This is called the **control plane**. RDMA only defines the **data plane**.

---

### Step 3: The Application Posts a Work Request

Now Server A wants to write.

It creates a structure like this (simplified):

```c
    struct RDMA_WRITE {
        local_addr = 0x50000000;
        remote_addr = 0x10000000;
        length = 4096;
        rkey = 0xABCD1234;
    };
```

Then it calls something like:

```c
    ibv_post_send(qp, &wr);
```

Notice:

**No packet is created.**

The application merely tells the RNIC:

> "Please perform this write."

---

### Step 4: The RNIC Reads the Work Queue

Every Queue Pair (QP) has a **Send Queue (SQ)**.

Think of it as a command queue:

```text
    Send Queue
    +----------------------------+
    | RDMA WRITE                 |
    | local=0x50000000           |
    | remote=0x10000000          |
    | rkey=0xABCD1234            |
    | length=4096                |
    +----------------------------+
```

The RNIC continuously watches this queue.
As soon as it sees the request:
It begins executing it.

---

### Step 5: DMA Reads Local Memory

The RNIC now needs the data.
Instead of asking the CPU:

```text
    CPU:
    Copy these bytes...
```

it performs **DMA (Direct Memory Access).**

```text
   RAM
    │
    │ DMA
    ▼
   RNIC
```

The CPU isn't copying the data. The RNIC fetches it directly from RAM using the PCIe bus.

This is the first "Direct" in **Remote Direct Memory Access**.

---

### Step 6: Build the RoCE Packet

Now the RNIC has:

* payload
* remote address
* rkey
* operation

It constructs an RDMA message.

Conceptually:

```text
    RDMA Header
    Opcode = WRITE
    Remote Address = 0x10000000
    rkey = 0xABCD1234
    Length = 4096
    Payload...
```

But this cannot yet travel on Ethernet.

So the RNIC encapsulates it.

For **RoCE v2**, the packet on the wire looks roughly like this:

```text
    +---------------------+
    | Ethernet Header     |
    +---------------------+
    | IP Header           |
    +---------------------+
    | UDP Header          |
    +---------------------+
    | IB Transport Header |
    +---------------------+
    | RDMA Header         |
    +---------------------+
    | User Data           |
    +---------------------+
    | CRC                 |
    +---------------------+
```

This is a crucial point:

> **RoCE v2 reuses the InfiniBand transport protocol**, but carries it inside UDP/IP over Ethernet.

So even though the physical network is Ethernet, the RNICs are still speaking the InfiniBand 
transport protocol to each other.

That's why many RDMA concepts, such as Queue Pairs, Work Queue Elements, and 
Completion Queues—come from InfiniBand.

---

### Step 7: The Ethernet Switch

The Ethernet switch sees only:

```
    Ethernet
    IP
    UDP
```

It does **not** understand:

* RDMA
* rkey
* remote address
* queue pair

To the switch, it's simply forwarding UDP packets.

The RDMA semantics are interpreted only by the RNICs at each end.

---

### Step 8: Receiving RNIC

When the packet reaches Server B:
The RNIC extracts:

```
    Opcode = WRITE

    Remote Address

    Length

    rkey
```

Before touching memory, it checks:

```
    Does this Queue Pair exist?
    Is this rkey valid?
    Is the address inside the registered region?
    Are the access permissions correct?
```

If any of these checks fail, the RNIC reports an error rather than writing to memory.

---

### Step 9: DMA Write into RAM

If the checks succeed:

```text
     RNIC
      │
      │ DMA
      ▼
     RAM
```

Again, no CPU copy is involved.

The RNIC writes directly into the registered memory region.

The application's buffer now contains the new data.

---

### Step 10: Completion

Finally:

The RNIC places a completion entry into a **Completion Queue (CQ)**.

The application later polls the CQ:

```
    RDMA Write completed.
```

Polling is common because it avoids interrupt overhead and helps achieve very low latency.

---

### Putting it all together

```text
  Application
      │
      │ Post Work Request
      ▼
  Send Queue
      │
      ▼
    RNIC
      │
      │ DMA Read
      ▼
  Local RAM
      │
      ▼
 RoCE Packet
      │
Ethernet Switch
      │
RoCE Packet
      ▼
Receiving RNIC
      │
Permission Check
      │
  DMA Write
      ▼
  Remote RAM
      │
Completion Queue
      ▼
  Application
```

### The key insight

There are really **three independent layers** involved:

1. **RDMA programming model** — concepts like Queue Pairs, Work Requests, RDMA Read/Write, Completion Queues.
2. **RoCE transport** — how those RDMA messages are encapsulated and carried over Ethernet/IP/UDP.
3. **Ethernet network** — switches that simply forward frames based on Ethernet and IP headers, without
   understanding RDMA.

Once you separate these layers, the architecture becomes much easier to reason about.

A logical next topic is the **Queue Pair (QP)**, because it is the central abstraction in RDMA.
Every RDMA operation flows through a QP, and understanding how Send Queues, Receive Queues, and 
Completion Queues interact will make the entire RDMA stack much more intuitive.

--------------------------------------------------------------------------------------

## Queue Pairs:

**Queue Pairs (QPs)** are arguably the most important concept in RDMA. 
Once you understand QPs, you'll see that an RNIC behaves much more like a specialized processor 
than a simple network card.

I'll build this up from first principles.

---

### Why do we need a Queue Pair?

Imagine you have an RNIC that can perform operations like:

* RDMA Write
* RDMA Read
* Send
* Receive

The application needs some way to tell the RNIC:

> "Here's the next operation I want you to perform."

One approach would be to make a system call every time:

```text
    Application
        |
        | ioctl()
        |
      RNIC
```

But this would be slow because every operation would involve a kernel transition.

Instead, RDMA uses **memory-based queues**.

The application and the RNIC **share queues in memory**.

Think of it like a restaurant kitchen.

```
    Customer (Application)
         |
    Writes order
         |
    Order Queue
         |
    Chef (RNIC)
```

The chef continuously watches the order queue.
No one has to ring a bell every time.

---

### What exactly is a Queue Pair?

A Queue Pair consists of two queues:

```
        Queue Pair (QP)

    +----------------+
    | Send Queue (SQ)|
    +----------------+
            |
            |
            |
    +----------------+
    | Receive Queue  |
    |      (RQ)      |
    +----------------+
```

Every communication endpoint owns one Queue Pair.

Notice something interesting:

A Queue Pair **does not contain the network connection itself**.

It contains **work that needs to be performed**.

---

#### The Send Queue

The Send Queue contains commands for the RNIC.

For example:

```
    Send Queue
    +-------------------------+
    | RDMA WRITE              |
    +-------------------------+
    | SEND                    |
    +-------------------------+
    | RDMA READ               |
    +-------------------------+
    | SEND                    |
    +-------------------------+
```

Each entry is called a **Work Queue Element (WQE)** or **Work Request (WR)**.

Each entry describes one operation.

Example:

```
    Operation:
    RDMA WRITE

    Local Buffer:
    0x500000

    Remote Buffer:
    0x800000

    Length:
    4096

    rkey:
    0x123456
```

The RNIC simply executes these entries in order.

---

#### The Receive Queue

The Receive Queue is different.

Suppose another server sends you data.

Where should the RNIC put it?

It can't guess.

So before data arrives, the application posts receive buffers.

Example:

```
    Receive Queue
    +----------------+
    | Buffer A       |
    +----------------+
    | Buffer B       |
    +----------------+
    | Buffer C       |
    +----------------+
```

Each entry says:

> "If someone sends me a message, place it here."

This is used for **SEND/RECEIVE** operations.

Notice something important:

**RDMA WRITE does not require the remote Receive Queue.**

This is one of the biggest differences between SEND and WRITE.

---

##### Example: SEND

Suppose Machine A performs:

```
SEND
```

Machine B must already have:

```
Receive Queue

Buffer #1
```

Otherwise the RNIC has nowhere to place the incoming data.

---

##### Example: RDMA WRITE

Suppose Machine A performs:

```
WRITE

Remote Address = 0x900000
```

Machine B does **not** need a Receive Queue entry.

The RNIC writes directly to the registered memory region using the remote address and rkey.

This distinction is worth emphasizing:

| Operation  | Needs Receive Queue? |
| ---------- | -------------------- |
| SEND       | Yes                  |
| RDMA WRITE | No                   |
| RDMA READ  | No                   |

---

#### What is a Completion Queue?

After the RNIC finishes an operation, how does the application know?

The RNIC writes a completion record into another queue.

```
    Completion Queue

    +--------------------+
    | WRITE Complete     |
    +--------------------+
    | READ Complete      |
    +--------------------+
    | SEND Complete      |
    +--------------------+
```

The application polls this queue:

```
    while (...) {
        
        ibv_poll_cq(...);
    }
```

Instead of interrupting the CPU for every packet, many high-performance applications poll the 
Completion Queue continuously. This reduces latency at the cost of using CPU cores for polling.

---

#### Putting the queues together

```
  Application
      |
      | Post Work Request
      ▼
+--------------------+
| Send Queue         |
+--------------------+
      |
      ▼
    RNIC
      |
Executes operation
      |
   Network
      |
    RNIC
      |
Writes completion
      |
      ▼
+--------------------+
| Completion Queue   |
+--------------------+
      |
  Application polls
```

---

### Why is it called a Queue Pair?

Originally, in InfiniBand, communication was designed around two peers.

```
Machine A                Machine B

QP #15  <------------->  QP #42
```

One Queue Pair communicates with another Queue Pair.

Each QP has:

```
    SQ
    RQ
```

Together:

```
    Machine A
    
    SQ ---->
    
    RQ <----

    Machine B

    SQ ---->

    RQ <----
```

This allows **full-duplex** communication: each side can send and receive independently.

---

### Multiple Queue Pairs

A server usually has many QPs.

```
    RNIC
    QP1
    QP2
    QP3
    QP4
    QP5
    ...
    QP5000
```

For example:

```
Database Client A
    ↓
  QP 10
Database Client B
    ↓
  QP 11
Database Client C
    ↓
  QP 12
```

Each QP represents an independent communication endpoint, similar to how a TCP socket 
represents one communication endpoint. 

Unlike a TCP socket, however, a QP is tied to RDMA semantics and the RNIC's work queues.

---

### Life of a Work Request

Let's follow one request.

Application:

```
    Post WRITE
```

    ↓

```
Send Queue

+-------------+
| WRITE       |
+-------------+
```
    ↓
RNIC reads it.
    ↓

RNIC performs DMA.
    ↓
RNIC builds a RoCE packet.
    ↓
Packet traverses the network.
    ↓
Remote RNIC performs DMA.
    ↓
Completion Queue
```
WRITE completed
```
    ↓
Application polls CQ.

Notice that the CPU on the sending side is involved only in posting the work request and later
checking the completion. The actual data movement is handled by the RNIC.

---

### A subtle but important point

The queues themselves are **ordinary memory buffers** shared between the application and the RNIC.

When you call a function such as:
```c
    ibv_post_send(qp, &wr);
```
the library is not sending a network packet. It is writing a new **Work Queue Element** into the 
Send Queue in memory and notifying the RNIC (often via a lightweight "doorbell" register write over 
PCIe) that new work is available.

From there, the RNIC takes over:

```
Application
     │
     │ Write WQE into memory
     ▼
Shared Send Queue
     │
     │ Doorbell
     ▼
   RNIC
     │
DMA read local data
     │
Build RoCE packet
     │
  Transmit
```

This "shared queue + doorbell" design is one of the reasons RDMA achieves such low latency and high throughput.

---

### Where to go next

Now that QPs are clear, there are two natural directions:

1. **Queue Pair states and connection establishment**: how two QPs discover each other, transition through states like `RESET → INIT → RTR (Ready to Receive) → RTS (Ready to Send)`, and exchange queue numbers, PSNs, and keys.

2. **RoCE packet format on the wire**: dissect every field of a real RoCE v2 packet—from the Ethernet header down to the InfiniBand Base Transport Header (BTH), RDMA Extended Transport Headers, and payload—to see exactly what the RNIC transmits.

I recommend covering **QP state transitions first**, because it explains how two RNICs are able to trust and communicate with each other before diving into the packet fields. That foundation makes the wire format much easier to understand.

----------------------------------------------------------------------------------------------------

## QP state transitions:

This is where RDMA starts to feel like a protocol stack instead of just an API.

One thing to keep in mind throughout this discussion:

> **A Queue Pair (QP) is much closer to a TCP socket than to an Ethernet port.**

Just as a TCP socket goes through states (`LISTEN`, `SYN_SENT`, `ESTABLISHED`, ...), an 
RDMA Queue Pair also goes through a well-defined state machine before data can flow.

---

### Why does a QP have states?

Suppose Server A suddenly sent this command:

```
    RDMA WRITE
    Remote Address = 0x10000000
    rkey = 0x1234
```

The receiving RNIC would have many questions:

* Which Queue Pair is this for?
* Is the sender trusted?
* What packet sequence number should I expect?
* Which protection domain does it belong to?
* Is the QP ready?
* Is the remote QP expecting packets?

Until all this information is configured, the RNIC **must reject traffic**.

That's why every QP starts in a disabled state.

---

### The Complete State Machine

The common state transitions for a Reliable Connection (RC) Queue Pair are:

```text
              +---------+
              | RESET   |
              +---------+
                  |
                  v
              +---------+
              | INIT    |
              +---------+
                  |
                  v
              +---------+
              | RTR     |
              | Ready   |
              | Receive |
              +---------+
                  |
                  v
              +---------+
              | RTS     |
              | Ready   |
              | Send    |
              +---------+

                Runtime
                  |
             Error occurs
                  |
                  v
              +---------+
              | ERROR   |
              +---------+
                  |
                  v
              +---------+
              | RESET   |
              +---------+
```

Let's understand each state.

---

#### State 1 — RESET

Everything begins here.

```
    QP
    
    State = RESET
```

The QP exists, but it knows nothing.

Think of it as buying a new mobile phone.

It has:

* no SIM
* no Wi-Fi
* no contacts

It simply exists.

The RNIC will reject every packet.

No send.

No receive.

No DMA.

Nothing.

---

#### State 2 — INIT

The application now initializes the QP.

Typical information configured includes:

```
Port Number

Access Flags

Protection Domain

P_Key (InfiniBand)

```

For RoCE, some InfiniBand-specific items are not used, but the QP abstraction remains the same.

At this point the RNIC now knows:

> "This QP belongs to this application."

But notice:

It still doesn't know anything about the remote machine.

```
    Machine A
    QP 15
      ↓
    INIT
  Remote ??
```

It cannot communicate yet.

---

### Where does the remote information come from?

This is one of the biggest misconceptions beginners have.

The RNIC does **not** discover remote peers automatically.

The application exchanges this information itself.

Usually using TCP.

Example:

```
Application A
      |
 TCP Socket
      |
Application B
```

They exchange information such as:

```
    QP Number
     LID/GID
      PSN
      rkey
   Memory Address
```

This exchange is often called **connection management**.

---

### What is a QP Number (QPN)?

Every Queue Pair has a unique identifier.

Example:

```
    Machine A
      QP 15
    Machine B
      QP 28
```

When Machine A sends packets,

it tells the RNIC:

```
    Destination QP = 28
```

The receiving RNIC immediately knows:

> "This packet belongs to Queue Pair 28."

Think of it like a TCP destination port, except it's local to the RNIC rather than a globally 
defined protocol port.

---

### State 3 — RTR (Ready to Receive)

Now the remote information is configured.

Example:

```
    My QP
     15
    Remote QP
     28
    Remote GID
    ...
    Expected PSN
    ...
```

Now the RNIC says:

> "I know who is allowed to send me packets."

Notice the wording:

**Ready to Receive**

Not Ready to Send.

Why?

Because if both machines started sending immediately without agreeing on packet sequencing, 
they could become unsynchronized.

So the protocol first prepares each side to receive traffic.

---

### Packet Sequence Number (PSN)

Every RDMA packet has a sequence number.

Imagine packets:

```
    Packet 1
    Packet 2
    Packet 3
    Packet 4
```

Each carries a PSN:

```
    100
    101
    102
    103
```

When entering RTR,

the RNIC is told:

```
    Expect first packet = 100
```

If packet 103 arrives first:

```
    103
```

The RNIC knows something is wrong.

Reliable Connection (RC) transport uses these sequence numbers to detect loss, duplicates, 
and ordering issues, much like TCP does, but the processing is performed by the RNIC hardware.

---

### State 4 — RTS (Ready to Send)

Finally:

```
State = RTS
```

Now everything is known.

The RNIC knows:

* Remote QP
* Packet sequence numbers
* Retry counts
* Timeout values
* Path information
* Access permissions

Now the application can post:

```
    RDMA WRITE
    RDMA READ
    SEND
```

The RNIC immediately starts executing work requests.

---

### Why two separate states?

People often ask:

> Why not go directly from INIT to RTS?

Imagine two servers.

Server A

```
RTS
```

Server B

```
RESET
```

A sends:

```
Packet 100
```

B has no idea what to do with it.

The packet is discarded.

Instead:

Both sides first become:

```
RTR
```

Now both RNICs are ready to accept packets.

Only then do they become:

```
RTS
```

This prevents race conditions during connection setup.

---

### A complete connection timeline

Let's walk through the entire process.

#### Step 1

Create QP.

```
QP

↓

RESET
```

---

#### Step 2

Configure local properties.

```
RESET

↓

INIT
```

---

#### Step 3

Exchange connection information over TCP.

```
Machine A ---------------- Machine B

QPN

PSN

GID

Memory Info
```

Notice that **no RDMA packets are flowing yet**. The TCP connection is only being used to exchange the metadata that lets the RNICs communicate.

---

#### Step 4

Configure remote information.

```
INIT

↓

RTR
```

Now both RNICs know who their peer is.

---

#### Step 5

Enable transmission.

```
RTR

↓

RTS
```

Now data can flow.

---

#### Step 6

Application posts work requests.

```
WRITE

READ

SEND
```

The RNIC begins moving data.

---

### Who changes the QP state?

This is another important point.

The **RNIC does not change QP states automatically**. The application (through the RDMA verbs library) explicitly requests each transition.

A typical sequence in code looks like this:

```c
ibv_create_qp(...);           // QP starts in RESET

ibv_modify_qp(...INIT...);

exchange_connection_info();   // Usually over TCP

ibv_modify_qp(...RTR...);

ibv_modify_qp(...RTS...);
```

Each `ibv_modify_qp()` call updates the RNIC's internal context for that Queue Pair.

---

### What's inside the RNIC?

By the time a QP reaches `RTS`, the RNIC has an internal context that might conceptually look like this:

```
QP #15
├── State: RTS
├── Remote QP: 28
├── Local PSN: 100
├── Expected Remote PSN: 500
├── MTU: 1024 bytes
├── Retry Count: 7
├── Timeout: 20
├── Path Information
├── Send Queue Pointer
├── Receive Queue Pointer
└── Completion Queue Pointer
```

The RNIC consults this context every time it processes a work request or an incoming packet.

---

## The big picture

At this point, we've covered:

1. **Memory registration** – which memory is accessible by the RNIC.
2. **Queue Pairs** – where the application posts work.
3. **QP state transitions** – how two RNICs become ready to communicate.

The next major piece is **Connection Management (CM)**. 
That's the layer that automates much of the metadata exchange we've glossed over. 

It answers questions like:

* How does one server discover another?
* How are QP numbers, GIDs, and PSNs exchanged?
* What role do `librdmacm` and the RDMA Connection Manager play?
* How does RoCE use IP addresses while the RNIC ultimately communicates using GIDs?

Once you understand Connection Management, you'll have a complete end-to-end picture of how an 
RDMA session is established before the first RDMA packet is ever sent.


-----------------------------------------------------------------------------------------

## Connection Management (CM)

At this point we've learned **what the RNIC does**. Now we'll answer the question:

> **How do two RNICs even find each other?**

This is one of the least understood parts of RDMA because **connection management is not actually RDMA**.

Think of it this way:

```
            +----------------------+
            |   Connection Mgmt    |
            | (Who are you?)       |
            +----------------------+
                     ↓
            +----------------------+
            |    RDMA Transport    |
            | (Move the data)      |
            +----------------------+
```

These are two completely different phases.

---

### A TCP Analogy

Let's first look at TCP because everyone knows it.

When you write

```c
connect(sockfd, "10.1.1.20", 8080);
```

What happens?

The kernel performs:

```
SYN
   --------->

          SYN+ACK
<---------

ACK
---------->
```

After this handshake, the kernel knows:

* remote IP
* remote port
* sequence numbers
* window size
* MSS
* retransmission timers

Only then can you send application data.

---

RDMA has the exact same idea.

Before an RDMA Write can happen, both RNICs must agree on:

* Who is the peer?
* Which Queue Pair?
* Which packet sequence number?
* Which path?
* Which MTU?
* Which memory keys?

---

### The RDMA Connection Problem

Suppose we have:

```
Server A                     Server B

QP 17                     QP 42
```

Server A wants to perform:

```
RDMA WRITE
```

How does it know:

* that the remote QP is 42?
* the remote GID?
* the remote PSN?
* the remote MTU?

It doesn't.

Someone has to tell it.

---

### Solution #1 (Manual Exchange)

The simplest possible RDMA application does this.

Open a normal TCP socket.

```
Application A

      TCP

Application B
```

Then exchange a small structure.

For example:

```c
struct qp_info {

    uint32_t qpn;

    uint32_t psn;

    uint16_t lid;

    uint8_t gid[16];

};
```

Machine A sends:

```
My QP = 17

My PSN = 1234

My GID = ...
```

Machine B sends:

```
My QP = 42

My PSN = 8765

My GID = ...
```

After exchanging this information:

Each application calls

```c
ibv_modify_qp(...)
```

to move the QP through:

```
INIT

↓

RTR

↓

RTS
```

Many RDMA tutorials and examples use this approach because it's easy to understand.

---

### But Why Use TCP?

This surprises many people.

The answer is:

**TCP is only used once.**

Only for setup.

Once the RDMA connection is ready:

```
TCP
```

is no longer used.

The data path becomes:

```
RNIC

↓

RoCE

↓

RNIC
```

The TCP socket often remains open only for application-level coordination, not for moving the bulk data.

---

### Manual Exchange Doesn't Scale

Imagine a storage cluster with 500 servers.

Every server would have to exchange:

* GID
* QPN
* PSN
* MTU
* timeout
* retry count

with every other server.

That becomes cumbersome.

So RDMA defines a Connection Manager.

---

### Enter RDMA CM

This is the **RDMA Connection Manager**.

Usually implemented through

```
librdmacm
```

It provides an API similar to sockets.

Instead of:

```c
socket()

bind()

listen()

accept()

connect()
```

you use:

```c
rdma_create_id()

rdma_bind_addr()

rdma_listen()

rdma_accept()

rdma_connect()
```

Notice how familiar that looks.

---

### What Does RDMA CM Actually Do?

This is the key idea.

It does **not** move your application data.

Instead, it automates all the tedious setup.

Think of it as an assistant.

Instead of you writing:

```
Send my QPN

Receive his QPN

Send my PSN

Receive his PSN

Configure RTR

Configure RTS
```

You simply say:

```
rdma_connect()
```

The library handles the exchange and configuration.

---

### Under the Hood

Suppose you call:

```c
rdma_connect(id, ...)
```

Internally something like this happens.

#### Step 1

Resolve the destination.

```
10.1.1.20
```

↓

Find the destination RNIC.

---

#### Step 2

Exchange RDMA parameters.

```
Machine A

↓

QPN

PSN

GID

MTU

↓

Machine B
```

---

#### Step 3

Create Queue Pair.

---

#### Step 4

Move

```
RESET

↓

INIT

↓

RTR

↓

RTS
```

---

#### Step 5

Notify application:

```
Connection established.
```

Now the application can post work requests.

---

### Wait... How Does RoCE Find the Remote RNIC?

This is another subtle point.

RoCE runs over Ethernet.

Applications typically know only an IP address:

```
10.1.1.20
```

But the RNIC doesn't communicate using IP addresses internally; it uses a **Global Identifier (GID)** to identify RDMA endpoints.

So there's a translation step:

```
Application

↓

IP Address

↓

RDMA CM

↓

GID

↓

RNIC
```

The Connection Manager resolves the destination IP into the appropriate GID and network path.

---

### What Is a GID?

A GID is a **128-bit Global Identifier**.

It plays a role similar to an IPv6 address within the RDMA architecture.

For RoCE:

```
Application

↓

192.168.1.20

↓

RDMA CM

↓

GID

↓

RNIC
```

The application usually doesn't need to manipulate the GID directly when using RDMA CM.

---

### The Complete Connection Timeline

Let's put everything together.

```
Application A                     Application B

Create QP                      Create QP

RESET                          RESET

INIT                           INIT

Resolve Address

----------------------------->

Exchange RDMA Information

<---------------------------->

RTR                            RTR

RTS                            RTS

RDMA WRITE

==============================>

Completion
```

Notice:

The first half is entirely about **connection setup**.

The second half is **RDMA data movement**.

---

### Who Talks During Connection Setup?

This is another interesting point.

During setup, the CPUs are very much involved.

```
CPU

↓

RDMA CM

↓

RNIC
```

Once the QPs reach RTS:

```
RNIC

↓

RNIC
```

The CPUs step out of the critical data path.

This separation between a CPU-driven **control plane** and an RNIC-driven **data plane** is a recurring design pattern in high-performance networking.

---

### A Real-Life Analogy

Imagine two companies want to exchange packages automatically.

Before the first package is shipped, they agree on:

* Warehouse address
* Dock number
* Security credentials
* Receiving hours
* Tracking sequence
* Package size limits

That's **Connection Management**.

Once everything is agreed:

Trucks simply drive back and forth delivering packages.

The office staff don't need to negotiate every shipment.

The trucks are like the RNICs, and the office staff are like the CPUs handling the control plane.

---

### Where does `librdmacm` fit?

The Linux RDMA software stack is often visualized like this:

```
                 Your Application
                        │
        ┌───────────────┴───────────────┐
        │                               │
   librdmacm (Connection Mgmt)    libibverbs (RDMA Verbs)
        │                               │
        └───────────────┬───────────────┘
                        │
                 Kernel RDMA Subsystem
                        │
                     RNIC Driver
                        │
                        RNIC
```

The two libraries have distinct responsibilities:

* **`librdmacm`**: discovers peers, resolves addresses, exchanges connection information, and drives the QP state transitions.
* **`libibverbs`**: creates protection domains, registers memory, creates QPs, posts work requests, and polls completion queues.

---

### We've now built almost the entire RDMA stack

At this point you understand:

1. ✓ Why RDMA exists.
2. ✓ How the RNIC performs DMA.
3. ✓ Memory registration and `rkey`.
4. ✓ Queue Pairs.
5. ✓ Send Queue and Receive Queue.
6. ✓ Completion Queue.
7. ✓ QP state transitions.
8. ✓ Connection Management.

The next topic I'd recommend is **Protection Domains (PDs)**. They are the security boundary in RDMA and explain *why* an `rkey` from one application cannot be used by another, even if they share the same RNIC. Once PDs are clear, the remaining concepts—Memory Regions (MRs), Memory Windows (MWs), and the exact RoCE packet format—fit together naturally.

--------------------------------------------------------------------------------------

## Protection Domains (PDs)

**Protection Domains (PDs)** are one of the most fundamental—and initially confusing—concepts in RDMA. 
Most tutorials introduce them with a sentence like:

> "A Protection Domain groups RDMA resources."

While that's technically true, it doesn't explain **why they exist**.

The best way to understand PDs is to imagine **what would happen if they didn't exist.**

---

### The Problem: Multiple Applications Sharing One RNIC

Suppose you have a server running two completely unrelated applications:

```text
+---------------------------------------+
|               Server                  |
|                                       |
|  Database Server      Web Server      |
|                                       |
|  Process A            Process B       |
|                                       |
|              One RNIC                 |
+---------------------------------------+
```

Both applications use RDMA.

Question:

> **How does the RNIC know that Process A must never access Process B's memory?**

Without protection, a bug—or a malicious application—could write into another process's registered memory.

That would be catastrophic.

---

### A Naive RNIC (No Protection)

Imagine the RNIC has a table like this:

```text
Registered Memory

Address         Length

0x10000000      4 KB

0x20000000      4 KB

0x30000000      8 KB
```

Now Process A submits:

```text
RDMA WRITE

Address = 0x30000000
```

Should the RNIC allow it?

It has no idea:

* Who owns that memory?
* Which application registered it?
* Whether this Queue Pair is allowed to access it?

The RNIC needs a security model.

---

### The Solution: Protection Domains

A Protection Domain is essentially a **security container** inside the RNIC.

Think of it as a sandbox.

```text
RNIC

+-----------------------------------+

   Protection Domain #1

      QP
      CQ
      Memory Region

+-----------------------------------+

   Protection Domain #2

      QP
      CQ
      Memory Region

+-----------------------------------+
```

Resources inside one PD can work together.

Resources in different PDs cannot.

---

### Think of a Hotel

Imagine a hotel.

Each room has:

* a door
* a key
* guests

```text
Room 101

Alice

Laptop

Bag

--------------------

Room 102

Bob

Laptop

Phone
```

Alice's key opens only Room 101.

Bob's key opens only Room 102.

The hotel is like the RNIC.

The room is the Protection Domain.

The key is the permission enforced by the RNIC.

---

### What Lives Inside a Protection Domain?

Nearly every RDMA resource belongs to exactly one PD.

```text
Protection Domain

    |

    +---- Queue Pair

    |

    +---- Memory Region

    |

    +---- Memory Window

    |

    +---- Shared Receive Queue
```

Notice that a Completion Queue (CQ) is **not** tied to a single PD. A CQ can be associated with QPs from different PDs, depending on the RNIC implementation and API usage. This is a subtle point that many introductions gloss over.

---

### Creating a Protection Domain

One of the first things an RDMA application does is:

```c
struct ibv_pd *pd;

pd = ibv_alloc_pd(context);
```

This doesn't allocate memory.

It doesn't create a queue.

It simply tells the RNIC:

> "Create a new security container for my RDMA resources."

The RNIC returns a handle.

Everything created afterward references this PD.

---

### Registering Memory

Suppose your application has:

```c
char buffer[4096];
```

Now you register it:

```c
ibv_reg_mr(
    pd,
    buffer,
    sizeof(buffer),
    flags
);
```

Notice the first argument:

```text
pd
```

Not optional.

Why?

Because the RNIC records:

```text
Memory Region

Address = 0x10000000

Length = 4096

Owner PD = 17
```

The memory now belongs to **Protection Domain 17**.

---

### Creating a Queue Pair

Later:

```c
ibv_create_qp(pd, ...);
```

Again:

The Queue Pair belongs to:

```text
PD = 17
```

The RNIC records:

```text
QP 42

Owner PD = 17
```

---

### What Happens During an RDMA Write?

Suppose:

```text
QP 42

belongs to

PD 17
```

It tries to access:

```text
Memory Region

belongs to

PD 17
```

The RNIC checks:

```text
Same PD?

YES
```

Operation allowed.

---

Now imagine:

```text
QP 42

belongs to

PD 17
```

tries:

```text
Memory Region

belongs to

PD 22
```

The RNIC checks:

```text
Same PD?

NO
```

Immediate failure.

The packet never reaches memory.

This check is performed in hardware.

---

### Visualizing the Check

Imagine the RNIC stores:

```text
QP Table

QP 42

PD = 17
```

Memory table:

```text
MR

Address

PD

0x10000000

17

0x20000000

22
```

When executing:

```text
WRITE

QP = 42

Address = 0x20000000
```

The RNIC performs:

```text
QP.PD == MR.PD ?

17 == 22 ?

FALSE
```

Reject.

No DMA occurs.

---

### Why Isn't the rkey Enough?

This is a great question.

You might think:

> "The rkey already protects memory. Why do we need PDs?"

Because they solve different problems.

#### Protection Domain

Answers:

> **Who owns this resource?**

#### rkey

Answers:

> **Is the remote peer authorized to access this memory?**

Think of it like this:

A company office has:

* Employee badge (PD)
* Meeting room reservation code (rkey)

Your badge gets you into the correct office.

The reservation code gets you into a particular meeting room.

You need both.

---

### Life of an RDMA Write

Let's follow a request.

Application:

```text
PD = 17

QP = 42

MR = buffer
```

↓

Post WRITE.

↓

RNIC receives:

```text
Use

QP 42

MR 5
```

↓

RNIC checks:

```text
Does

QP.PD == MR.PD ?
```

↓

If yes:

Continue.

↓

Check:

```text
rkey
```

↓

If valid:

DMA.

Notice the order:

1. Protection Domain
2. Memory permissions
3. rkey
4. DMA

Security checks happen before any memory transfer.

---

### Multiple Applications

Imagine again:

```text
RNIC

+--------------------------------+

PD 1

Database

QP1

MR1

MR2

+--------------------------------+

PD2

Web Server

QP8

MR5

MR6

+--------------------------------+
```

Even though everything shares one physical RNIC:

Neither application can accidentally access the other's RDMA resources because the RNIC enforces the PD boundaries.

---

### Why Does the Application Never See the PD Number?

You may have noticed that I used numbers like:

```text
PD = 17
```

In reality:

The application never knows that number.

It only gets:

```c
struct ibv_pd *pd;
```

Internally the RNIC may use:

```text
17
```

or

```text
428
```

or

```text
0x81
```

The hardware implementation is free to choose.

The application only keeps the opaque handle.

---

### Where PDs Fit in the Stack

By now, the RDMA object hierarchy should look like this:

```text
                RNIC Context
                     │
         ibv_open_device()
                     │
                     ▼
          Protection Domain (PD)
                     │
      ┌──────────────┼──────────────┐
      │              │              │
      ▼              ▼              ▼
 Memory Region      Queue Pair   Shared Receive Queue
     (MR)             (QP)              (SRQ)
      │                │
      └───────┬────────┘
              ▼
       Completion Queue (CQ)
```

The PD is the **ownership and isolation boundary**. Every memory region and every queue pair is created within a PD, and the RNIC uses that association to ensure that only compatible resources can interact.

---

### The Big Picture So Far

Notice how each concept we've learned adds one layer of responsibility:

| Component                  | Responsibility                                     |
| -------------------------- | -------------------------------------------------- |
| **Protection Domain (PD)** | Ownership and isolation between applications       |
| **Memory Region (MR)**     | Which memory is registered for RDMA                |
| **rkey/lkey**              | Authorization to access a particular memory region |
| **Queue Pair (QP)**        | Communication endpoint that issues RDMA operations |
| **Completion Queue (CQ)**  | Reports completed operations                       |
| **RNIC**                   | Executes operations and enforces all of the above  |

This layered design is what allows multiple independent applications to safely share the same RNIC without interfering with each other.

---

## Where to go next

We're now at the point where we can dive into **Memory Regions (MRs)** in detail.

That's where we'll answer questions like:

* What exactly happens inside `ibv_reg_mr()`?
* Why must memory be **pinned**?
* What are **lkey** and **rkey**, and how are they generated?
* How does the RNIC translate a virtual address from your process into physical pages for DMA?
* Why is memory registration considered one of the most expensive RDMA operations?

Understanding MRs reveals what many consider the "magic" behind RDMA: how an RNIC can safely perform DMA directly into a user process's memory without involving the CPU in the data path.


-----------------------------------------------------------------------------------------------

## Memory Regions (MRs)

It looks like you want to revisit **Memory Regions (MRs)** and go through them again in the same deep, step-by-step style. I'll expand the explanation further and focus more on **what the RNIC actually needs, what happens in hardware, and how MRs interact with RDMA operations**.

---

# 1. Why Memory Regions exist

The central promise of RDMA is:

> A NIC can directly read from or write to application memory without involving the CPU.

But this immediately creates a problem:

A normal application sees memory like this:

```
Application Process

Virtual Address Space

+----------------------+
| Code                 |
+----------------------+
| Heap                 |
+----------------------+
| Buffer               |
| 0x7f12345000         |
+----------------------+
| Stack                |
+----------------------+
```

The address:

```
0x7f12345000
```

is only meaningful inside that process.

The RNIC is a PCIe device. It does not naturally understand:

* Linux virtual addresses
* process ownership
* page permissions
* whether memory can move

The RNIC needs a controlled way to say:

> "This exact range of this process's memory is approved for DMA."

That approved object is a **Memory Region**.

---

# 2. Normal CPU memory access vs RDMA memory access

## Normal CPU access

When your program does:

```c
buffer[10] = 'A';
```

the CPU does:

```
Virtual Address
       |
       v
CPU MMU
       |
       v
Physical RAM
```

The CPU uses page tables.

---

## RDMA access

Now consider:

```
Remote RNIC

      |
      |
      v

Your Server RAM
```

The RNIC is not the CPU.

It cannot simply use the CPU's MMU translation path.

Instead, the RNIC needs its own translation information.

That information comes from the Memory Region.

---

# 3. What is inside a Memory Region?

A Memory Region is not just:

```
Address + Size
```

Internally it contains much more.

Conceptually:

```
Memory Region

+--------------------------------+
| Virtual start address          |
+--------------------------------+
| Length                         |
+--------------------------------+
| Physical page mappings         |
+--------------------------------+
| Access permissions             |
+--------------------------------+
| Protection Domain              |
+--------------------------------+
| Local Key (lkey)               |
+--------------------------------+
| Remote Key (rkey)              |
+--------------------------------+
```

The actual implementation differs between RNIC vendors, but the concept is similar.

---

# 4. Creating a Memory Region

A typical RDMA program:

```c
mr = ibv_reg_mr(
        pd,
        buffer,
        size,
        access_flags);
```

Example:

```
Application memory:

buffer
 |
 |
 v

0x700000000000
```

The application says:

> "RNIC, I want this memory available for RDMA."

---

# 5. What happens during ibv_reg_mr()?

This is the important part.

The function looks simple, but internally many things happen.

---

## Step 1: The kernel receives the request

User space:

```
Application

ibv_reg_mr()

       |
       v

libibverbs

       |
       v

Kernel RDMA subsystem
```

The kernel verifies:

* Is this process allowed to register this memory?
* Is the address valid?
* Is the size valid?

---

# Step 2: Memory pages are pinned

Normally Linux has freedom to move memory.

Example:

Before:

```
Virtual Address

0x100000

      |
      v

Physical RAM Page A
```

Linux may later move it:

```
Virtual Address

0x100000

      |
      v

Physical RAM Page B
```

The application does not care.

The CPU's page tables are updated.

---

But RDMA cannot work this way.

Imagine:

```
RNIC starts DMA

Write to physical page A
```

Then Linux moves the page:

```
Page A removed

Page B now contains data
```

The RNIC continues writing into the wrong physical address.

Therefore:

Registered pages become:

```
Pinned

Cannot be swapped
Cannot be migrated
```

---

# Step 3: Physical page list is built

Suppose your buffer is:

```
Virtual Memory

0x10000000
|
+----------------+
| Page 0         |
+----------------+
| Page 1         |
+----------------+
| Page 2         |
+----------------+
```

The kernel finds:

```
Virtual          Physical

0x10000000  --> 0x90000000

0x10001000  --> 0x91000000

0x10002000  --> 0x92000000
```

This mapping is given to the RNIC.

---

# Step 4: RNIC creates translation entries

The RNIC stores something similar to:

```
Memory Translation Table


MR #100

Virtual Base:
0x10000000

Length:
12 KB


Pages:

0x90000000

0x91000000

0x92000000
```

Now the RNIC knows:

"If I receive an RDMA WRITE to virtual address 0x10000000, these are the physical pages I should DMA into."

---

# 6. Local Key (lkey)

Every MR gets two keys.

The first is:

```
lkey
```

Local Key.

This is used by the local machine.

Example:

Application posts:

```
RDMA SEND

Source buffer:

0x10000000

lkey:

0xABC
```

The RNIC checks:

```
Does lkey 0xABC describe this buffer?

YES

Proceed
```

Without the lkey, a program could tell the RNIC:

```
Read from any random address
```

which would be unsafe.

---

# 7. Remote Key (rkey)

The second key:

```
rkey
```

is for remote access.

Suppose Server B has:

```
Memory Region

Address:
0x80000000

Length:
1 MB

rkey:
0x123456
```

Server B gives this information to Server A.

Server A can now issue:

```
RDMA WRITE

Remote Address:
0x80000000

rkey:
0x123456
```

The receiving RNIC checks:

```
Does this rkey exist?

YES

Does address belong to this MR?

YES

Does MR allow remote write?

YES
```

Then:

```
DMA WRITE
```

happens.

---

# 8. Why expose rkey?

A natural question:

> "Why give another machine a memory address and key? Isn't that dangerous?"

The design assumes:

* You intentionally share selected memory regions.
* You control who receives the rkey.
* The rkey acts like a capability.

For example:

A storage server may expose:

```
Buffer:
4GB cache area

rkey:
0x778899
```

to trusted compute nodes.

Only nodes holding that rkey can access it.

---

# 9. Access Flags

When creating an MR:

```c
IBV_ACCESS_LOCAL_WRITE
```

means:

```
Local RNIC can write here
```

Example:

```
Incoming SEND

Network
  |
  v
Memory
```

---

```c
IBV_ACCESS_REMOTE_WRITE
```

means:

```
Remote RNIC may perform RDMA WRITE
```

Example:

```
Server A

WRITE

       --->

Server B Memory
```

---

```c
IBV_ACCESS_REMOTE_READ
```

means:

```
Remote RNIC may perform RDMA READ
```

Example:

```
Server A

READ

       <---

Server B Memory
```

---

# 10. RDMA WRITE with MR: Full path

Let's put all pieces together.

## Server B

Registers:

```
Memory Region

Address:
0x80000000

Size:
4096 bytes

rkey:
9999

Permission:
REMOTE_WRITE
```

Sends:

```
Address = 0x80000000

rkey = 9999
```

to Server A.

---

## Server A

Creates:

```
Work Request

Operation:
RDMA WRITE


Local buffer:
0x40000000

lkey:
5555


Remote:

Address:
0x80000000

rkey:
9999
```

---

## Sending RNIC

Checks:

```
lkey valid?

YES
```

DMA reads:

```
Server A RAM
       |
       v
RNIC
```

---

## Network

Packet contains:

```
RDMA WRITE

Remote Address

rkey

Payload
```

---

## Receiving RNIC

Checks:

```
rkey valid?

YES


Address belongs to MR?

YES


Permission allows write?

YES
```

---

Then:

```
RNIC

       |
       v

Server B RAM
```

No CPU copy.

---

# 11. Why MR registration is expensive

Registration requires:

* kernel interaction
* page pinning
* DMA mapping
* RNIC hardware programming

Therefore:

Bad design:

```
Send message

Register MR

Transfer data

Deregister MR
```

for every message.

Good design:

```
Startup:

Allocate buffers

Register MRs


Runtime:

Reuse buffers thousands/millions of times
```

High-performance systems usually maintain memory pools.

Examples:

* databases
* MPI applications
* AI training systems
* distributed storage

---

# 12. MR and Protection Domain relationship

The security hierarchy:

```
Protection Domain
        |
        |
        +----------------+
        |                |
        v                v

     Queue Pair      Memory Region

        |                |

        +------- Must match -------+

```

During RDMA:

The RNIC verifies:

```
QP belongs to PD X

MR belongs to PD X
```

Only then does it allow access.

The PD prevents one application from using another application's MR.

---

# 13. Complete RDMA object model now

At this point:

```
                    RNIC

                     |
              Protection Domain

                     |
        +------------+-------------+
        |                          |

       QP                         MR

        |                          |

 Send Queue                  Memory Mapping

 Receive Queue               lkey/rkey


        |
        v

 Completion Queue
```

The data path is:

```
Application

   |
   | Work Request

   v

Queue Pair

   |

RNIC

   |

Check:

- QP state
- PD ownership
- lkey/rkey
- permissions

   |

DMA

   |

Memory
```

---

## The key mental model

A **Memory Region is a contract between your application and the RNIC**:

> "For this range of memory, I guarantee it will stay in place. In return, the RNIC guarantees it can safely perform DMA operations according to these permissions."

That contract is what makes RDMA possible.

---

The next logical topic after MRs is **Memory Windows (MWs)**, because they address the limitation of MRs:

> "An MR is relatively static. What if I want to dynamically grant and revoke access to parts of memory without repeatedly registering/deregistering memory?"

That leads directly into how large distributed systems implement secure, high-performance memory sharing.

-------------------------------------------------------------------------------------

## Memory Windows (MWs)

Excellent. **Memory Windows (MWs)** are the next natural concept after Memory Regions (MRs), because they solve a very specific limitation of MRs.

The short version:

> A Memory Region defines a large registered memory area. A Memory Window allows you to dynamically grant (and revoke) remote access to a portion of that memory.

If Memory Regions are like **owning a warehouse**, Memory Windows are like **temporarily giving someone a key to one shelf inside the warehouse**.

Let's go deep.

---

# 1. The limitation of Memory Regions

Recall what happens with an MR.

You allocate memory:

```text
Application Memory

+--------------------------------+
|                                |
|        Large Buffer            |
|                                |
|        1 GB                    |
|                                |
+--------------------------------+
```

You register it:

```c
ibv_reg_mr()
```

The RNIC creates:

```text
Memory Region

Base address:
0x10000000

Length:
1 GB

rkey:
0xABCDEF
```

Now a remote machine can access it.

Example:

```text
Remote Server

RDMA WRITE

Address:
0x10001000

rkey:
0xABCDEF
```

Works.

---

But now imagine:

You have a 1 GB memory pool.

You want to temporarily give another server access to:

```text
Only this 4 KB area
```

Not the whole 1 GB.

You could create another MR:

```text
Register 4 KB

Deregister later
```

But that is expensive.

Remember:

MR registration requires:

* pinning pages
* DMA mapping
* programming RNIC hardware

Doing this thousands of times is inefficient.

This is where Memory Windows help.

---

# 2. The Memory Window idea

Instead of creating a new registered memory object:

```text
Old way:

Memory
   |
   |
Create MR
   |
   |
Give rkey
```

We do:

```text
Existing MR

       |
       |
Attach Memory Window

       |
       |
Generate temporary rkey
```

The Memory Window does not own memory.

It references memory that is already registered.

---

# 3. The relationship between MR and MW

The hierarchy looks like this:

```text
Protection Domain

        |
        |
        +----------------+
        |                |
        v                v

       MR               QP


        |
        |
        v

       MW
```

More explicitly:

```text
Memory Region

+--------------------------------+
|                                |
|       1 GB Buffer              |
|                                |
|   +---------+                  |
|   |   MW1   |                  |
|   | 4 KB    |                  |
|   +---------+                  |
|                                |
|   +---------+                  |
|   |   MW2   |                  |
|   | 8 KB    |                  |
|   +---------+                  |
|                                |
+--------------------------------+
```

The MR provides:

* physical memory mapping
* DMA capability
* base registration

The MW provides:

* temporary access rights
* smaller access scope
* dynamic sharing

---

# 4. Why not just use the MR rkey?

Good question.

Suppose you have:

```text
MR:

Address:
0x10000000

Size:
1 GB

rkey:
1234
```

If you give this rkey away:

The remote machine can access:

```text
0x10000000

through

0x13FFFFFFF
```

The whole region.

You cannot easily say:

> "Access only this small section."

The MR's rkey represents the entire MR.

A Memory Window creates a **new rkey with narrower permissions**.

---

# 5. Creating a Memory Window

Conceptually:

```c
mw = ibv_alloc_mw(
        pd,
        IBV_MW_TYPE_1
);
```

The MW itself is empty.

It does not point anywhere yet.

Think:

```text
Memory Window

rkey:
98765

Memory:
???

Length:
???
```

It needs to be bound to an MR.

---

# 6. Binding a Memory Window

The application creates a bind request.

Conceptually:

```text
Bind MW

Attach to:

MR:
Large Buffer

Offset:
64 KB

Length:
4 KB

Permissions:
REMOTE_WRITE
```

After binding:

```text
MR

+--------------------------------+
|                                |
| 0                              |
|                                |
| 64KB                           |
| +----------------+             |
| | Memory Window  |             |
| | 4KB            |             |
| +----------------+             |
|                                |
| 1GB                            |
+--------------------------------+
```

The MW now represents:

```text
Address:

MR base + 64KB

Length:

4KB
```

---

# 7. The MW rkey

After binding:

Before:

```text
MR

rkey = 1234
```

After:

```text
MW

rkey = 98765
```

The application sends:

```text
Remote Address:

0x10010000

rkey:

98765
```

to the remote machine.

Now the remote machine can access only:

```text
4 KB window
```

not the whole MR.

---

# 8. Type 1 vs Type 2 Memory Windows

RDMA defines two kinds:

* Type 1 MW
* Type 2 MW

They are very different.

---

# Type 1 Memory Window

Type 1 is the older and simpler model.

Characteristics:

* Bound explicitly by the local application.
* Associated with a specific MR.
* Access controlled by the local side.

Conceptually:

```text
Application

bind()

   |
   v

Memory Window

   |
   v

Memory Region
```

The local application controls:

* address
* length
* permissions

---

# Type 2 Memory Window

Type 2 is more flexible.

The important difference:

> The remote side can be involved in rebinding.

A Type 2 MW can be:

* bound
* invalidated
* rebound dynamically

This is useful in highly dynamic systems.

---

A Type 2 MW has:

```text
MW

rkey

+

associated QP
```

The QP can perform:

```text
Bind MW operation
```

This allows more flexible remote memory management.

---

# 9. Why Type 2 exists

Imagine a distributed storage system.

You have:

```text
Storage Server

Memory Pool

+-----------------------+
| Block A               |
| Block B               |
| Block C               |
| Block D               |
+-----------------------+
```

Clients access blocks dynamically.

Today:

```text
Client 1 → Block A
```

Tomorrow:

```text
Client 1 → Block C
```

You don't want to:

```
Deregister MR
Register MR
```

every time.

Instead:

```
Rebind MW
Generate new rkey
```

Much cheaper.

---

# 10. Revoking access

One of the biggest benefits of MWs:

**Fast revocation.**

Suppose:

```text
Client A

has:

rkey = 5555
```

for a memory window.

The server decides:

> "You should no longer access this."

It invalidates the MW.

Now:

```text
rkey 5555
```

is useless.

If Client A tries:

```text
RDMA WRITE

rkey=5555
```

The RNIC rejects it.

No memory deregistration needed.

---

# 11. Memory Window lifecycle

Typical flow:

```text
Create MR

       |
       |
       v

Allocate MW

       |
       |
       v

Bind MW to MR

       |
       |
       v

Get MW rkey

       |
       |
       v

Send rkey to remote peer

       |
       |
       v

Remote performs RDMA

       |
       |
       v

Invalidate MW

       |
       |
       v

Reuse MW
```

---

# 12. Example: RDMA storage server

Let's build a realistic example.

A storage server has:

```text
Memory Region:

4 GB cache
```

Registered once:

```text
MR rkey:

1000
```

It creates:

```text
MW1

points to:

Cache block 100

rkey:

5001
```

Client receives:

```text
Address:

0x20000000

rkey:

5001
```

Client performs:

```text
RDMA READ

rkey=5001
```

Gets data.

Later:

Server wants to give the client block 200.

Instead of registering again:

```text
Rebind MW1

Now points to:

Cache block 200

new rkey:

5002
```

The client must use:

```text
rkey=5002
```

The old access:

```text
rkey=5001
```

is invalid.

---

# 13. MR vs MW comparison

| Feature                   | Memory Region | Memory Window          |
| ------------------------- | ------------- | ---------------------- |
| Owns memory registration  | Yes           | No                     |
| Creates physical mapping  | Yes           | No                     |
| Has lkey                  | Yes           | No                     |
| Has rkey                  | Yes           | Yes                    |
| Covers large memory area  | Usually       | Usually smaller subset |
| Dynamic permissions       | Limited       | Strong                 |
| Registration cost         | High          | Low                    |
| Can revoke access quickly | Difficult     | Easy                   |

---

# 14. Where MW fits in the RDMA object model

Now our complete picture:

```text
                     RNIC

                      |
                      |

             Protection Domain

                      |
        +-------------+--------------+
        |                            |
        v                            v

   Queue Pair                  Memory Region

        |                            |
        |                            |
        |                            v

        |                    Memory Window
        |                            |
        |                            |
        +------------+---------------+
                     |
                     |
                 rkey/lkey

                     |
                     |
                 RDMA Operation
```

---

# 15. The mental model

The easiest way to remember:

### Memory Region (MR)

> "This memory belongs to RDMA."

It establishes:

* pinned pages
* DMA mapping
* ownership
* base permissions

---

### Memory Window (MW)

> "Give someone temporary access to part of that memory."

It establishes:

* smaller scope
* temporary permissions
* revocable access

---

A good analogy:

```
Memory Region = Building ownership

Memory Window = Temporary room access badge
```

The building exists permanently.

You can issue and revoke room badges without rebuilding the building.

---

Now we have covered the major RDMA memory model:

1. **Protection Domain** → who owns the resources.
2. **Memory Region** → what memory can participate in RDMA.
3. **Memory Window** → how to dynamically expose portions of that memory.
4. **lkey/rkey** → hardware-enforced access capabilities.

The next logical layer would be **the actual RDMA verbs operations (SEND, RECEIVE, RDMA WRITE, RDMA READ, Atomic operations)** and how they use QPs, MRs, MWs, and Completion Queues together. This is where all the pieces finally become a working RDMA transaction.


-----------------------------------------------------------------------------------

## RDMA Verb Operations:

Excellent. We now have all the building blocks:

* **Protection Domain (PD)** → security boundary
* **Memory Region (MR)** → registered memory that RNIC can access
* **Memory Window (MW)** → dynamically granted access to part of an MR
* **Queue Pair (QP)** → communication endpoint
* **Completion Queue (CQ)** → reports finished operations

Now we can look at the thing that actually moves data:

> **RDMA Verbs — the operations submitted by an application to the RNIC.**

The important idea is:

> The CPU does not perform the data movement. The CPU describes the operation, places it in a Queue Pair, and the RNIC executes it asynchronously.

---

# 1. The RDMA execution model

A normal socket model:

```text
Application

   |
   |
write()

   |
   v

Kernel

   |
   |
TCP stack

   |
   v

NIC
```

The CPU participates heavily.

---

RDMA model:

```text
Application

   |
   |
Post Work Request

   |
   v

Queue Pair

   |
   v

RNIC

   |
   |
DMA

   |
   v

Memory
```

The CPU says:

> "RNIC, please perform this operation."

Then the RNIC does the work.

---

# 2. What is an RDMA Verb?

A **verb** is an operation requested from the RNIC.

Examples:

| Verb              | Purpose                  |
| ----------------- | ------------------------ |
| SEND              | Message passing          |
| RECEIVE           | Receive a message        |
| RDMA WRITE        | Remote memory write      |
| RDMA READ         | Remote memory read       |
| Atomic operations | Hardware synchronization |

These are exposed through APIs such as:

```c
libibverbs
```

---

# 3. The Work Request (WR)

The application does not call:

```c
rdma_write(buffer)
```

Instead it creates a **Work Request**.

Conceptually:

```text
Work Request

+-------------------------+
| Operation Type          |
|                         |
| Buffer Address          |
|                         |
| Length                  |
|                         |
| lkey                    |
|                         |
| Remote Address          |
|                         |
| rkey                    |
+-------------------------+
```

Then it posts it to the Queue Pair.

---

Example:

```c
ibv_post_send(qp, &wr, &bad_wr);
```

Meaning:

> "Put this operation into the Send Queue of this QP."

---

# 4. Queue Pair: where verbs execute

A QP contains:

```
Queue Pair

+----------------+
| Send Queue     |
|                |
| WR WR WR WR    |
+----------------+

+----------------+
| Receive Queue  |
|                |
| WR WR WR WR    |
+----------------+
```

Important:

* Send operations go to the Send Queue.
* Receive operations go to the Receive Queue.

---

# 5. Completion Queue

The RNIC works asynchronously.

Example:

Application:

```text
Post RDMA WRITE
```

Immediately continues.

The operation may take:

* microseconds
* milliseconds

The application needs a notification.

That is the Completion Queue.

---

Completion flow:

```text
Application

post WR

   |
   v

Send Queue

   |
   v

RNIC executes

   |
   v

Completion Queue Entry

   |
   v

Application polls CQ
```

---

# 6. Completion Queue Entry (CQE)

A CQ contains completion records.

Example:

```
Completion Queue

+-----------------------+
| WR ID                 |
| Status                |
| Bytes transferred     |
| Opcode                |
+-----------------------+
```

Example:

```
WR ID:

12345

Status:

SUCCESS

Operation:

RDMA_WRITE
```

---

# 7. RDMA SEND / RECEIVE

Let's start with the simplest operation.

SEND is message passing.

Think:

```text
send()

recv()
```

from sockets.

---

## Setup

Machine A:

```text
QP A

Send Queue
```

Machine B:

```text
QP B

Receive Queue
```

Before sending, B must post receive buffers.

Why?

Because RDMA hardware does not allocate memory automatically.

---

## Receiver posts Receive WR

B:

```text
Receive Queue

+-------------+
| Buffer      |
| Address     |
| lkey        |
+-------------+
```

Meaning:

> "RNIC, if a message arrives, put it here."

---

## Sender posts SEND WR

A:

```
SEND

Buffer:

0x100000

lkey:

555
```

---

The path:

```
Application A

SEND WR

     |
     v

Send Queue

     |
     v

RNIC A

     |
     |
     | Network
     |
     v

RNIC B

     |
     v

Receive Queue entry

     |
     v

Memory
```

---

Both sides get completions:

Sender:

```
SEND complete
```

Receiver:

```
RECEIVE complete
```

---

# 8. Why SEND requires a receive buffer

This is important.

RDMA SEND is **receiver controlled**.

The sender does not know:

* where memory exists
* where data should go

The receiver already told the RNIC:

```
Put incoming message here.
```

This is similar to traditional networking.

---

# 9. RDMA WRITE

Now we reach the famous RDMA operation.

RDMA WRITE is different.

The sender directly writes remote memory.

---

Example:

Machine B registers:

```
MR

Address:

0x80000000

rkey:

9999

Permission:

REMOTE_WRITE
```

B sends:

```
Address = 0x80000000

rkey = 9999
```

to A.

---

A creates:

```
RDMA WRITE WR

Local:

Address:
0x40000000

lkey:
1111


Remote:

Address:
0x80000000

rkey:
9999
```

---

Execution:

```
RNIC A

DMA READ local memory

        |

        v

Network packet

        |

        v

RNIC B

Validate rkey

        |

        v

DMA WRITE

        |

        v

Remote RAM
```

---

Notice something important:

**B does not post a Receive WR.**

That is why RDMA WRITE is called one-sided.

The remote CPU does not participate.

---

# 10. RDMA READ

RDMA READ is the opposite.

The requester pulls data.

Example:

A wants data from B.

A posts:

```
RDMA READ

Remote Address:

0x90000000

rkey:

7777
```

---

Flow:

```
RNIC A

Request READ

        |

        v

RNIC B

Check rkey

        |

        v

Read memory

        |

        v

Return data

        |

        v

RNIC A

DMA into local buffer
```

---

Again:

B's CPU does nothing.

---

# 11. RDMA Atomic Operations

RDMA also provides hardware synchronization.

Examples:

## Compare and Swap

Equivalent:

```c
if (*ptr == old)
    *ptr = new;
```

performed atomically.

---

## Fetch and Add

Equivalent:

```c
old = counter;

counter += value;
```

performed atomically.

---

Why?

Distributed systems need synchronization.

Example:

```
10 servers

all updating

shared counter
```

The RNIC can perform atomic operations without CPU locks.

---

# 12. How MRs participate in verbs

Every local buffer reference requires an lkey.

Example:

RDMA WRITE:

```
Work Request

Local Buffer

Address:
0x10000000

lkey:
1234
```

The RNIC checks:

```
Does this address belong to lkey 1234?
```

If yes:

DMA allowed.

---

# 13. How MWs participate in verbs

A Memory Window replaces the MR rkey.

Example:

Without MW:

```
Remote Access:

Address:

Large MR

rkey:

1111
```

With MW:

```
Remote Access:

Address:

Small region

rkey:

8888
```

The verb does not know whether the rkey came from:

* MR
* MW

The RNIC just validates the key.

---

# 14. Full RDMA WRITE lifecycle

Let's combine everything.

## Application setup

```
Create PD

       |
       v

Register MR

       |
       v

Create QP

       |
       v

Create CQ
```

---

## Exchange information

Over TCP/RDMA CM:

```
Exchange:

QP number

GID

rkey

address
```

---

## Application posts:

```
RDMA WRITE WR

Local:

buffer

lkey


Remote:

address

rkey
```

---

## RNIC:

Checks:

```
QP state = RTS?

YES


QP PD matches?

YES


lkey valid?

YES


Remote rkey valid?

YES


Permission OK?

YES
```

---

## Hardware executes:

```
DMA READ

     |

     v

Network

     |

     v

DMA WRITE
```

---

## Completion:

```
CQE

Status:

SUCCESS
```

Application sees:

```
write completed
```

---

# 15. The complete RDMA object interaction

Now the whole picture:

```
                   Application

                        |
                        |
                 Work Request

                        |
                        v

                   Queue Pair
                        |
                        |
        +---------------+---------------+
        |                               |
        v                               v

   Send Queue                    Receive Queue


                        |
                        v

                      RNIC

                        |
        +---------------+---------------+
        |                               |

   Memory Region                 Memory Window

        |                               |

       lkey                           rkey

                        |
                        v

                       DMA

                        |
                        v

                      Memory

                        |
                        v

                 Completion Queue
```

---

# 16. The mental model

Think of RDMA like hiring a highly specialized courier:

### CPU:

Writes the instruction:

> "Move this data from here to there."

### QP:

The courier's mailbox.

### Work Request:

The instruction slip.

### MR:

The approved warehouse location.

### lkey/rkey:

The access badge.

### RNIC:

The courier who performs the movement.

### CQ:

The delivery confirmation.

---

# Where we are now

We have covered almost the entire RDMA programming model:

✅ RNIC architecture
✅ QPs
✅ QP state transitions
✅ Connection management
✅ Protection Domains
✅ Memory Regions
✅ Memory Windows
✅ RDMA verbs
✅ Completion Queues

The next deep topic that ties everything together is:

**"What actually goes on the wire?"**

Meaning:

* How does an RDMA WRITE packet look?
* How does RoCE encapsulate RDMA over Ethernet/IP?
* What are BTH, RETH, PSN, ACK packets?
* How does reliable delivery work without TCP?

That is where we move from the **software model** into the **RoCE wire protocol**.

--------------------------------------------------------------------------

## RoCE Wire protocol:

Good approach. For programming RDMA applications, you usually **do not need to memorize every bit field in the RoCE packet format**. What is useful is understanding:

1. **What layers exist on the wire**
2. **What information the RNIC puts into packets**
3. **How the receiver RNIC knows where to put data**
4. **How reliability works without TCP**
5. **Which fields map back to QP/MR concepts you already know**

Let's move from the software model into the wire view.

---

# 1. The big picture: Software object → Wire packet

At the software level:

```
Application

   |
   |
Work Request

   |
   v

Queue Pair

   |
   v

RNIC

   |
   v

Network
```

On the wire, the RNIC converts that operation into packets:

```
+----------------+
| Ethernet Frame |
+----------------+
| IP Header      |
+----------------+
| UDP Header     |
+----------------+
| RDMA Header    |
+----------------+
| Payload        |
+----------------+
```

For RoCE, the important point is:

> RDMA is carried inside Ethernet frames, and in RoCE v2 it is carried over UDP/IP.

---

# 2. RoCE versions: RoCE v1 vs RoCE v2

There are two generations.

## RoCE v1

```
Ethernet
    |
    |
InfiniBand Network Layer
    |
    |
RDMA Transport
```

Characteristics:

* Layer 2 only
* No IP routing
* Limited to a single Ethernet broadcast domain

Conceptually:

```
NIC A
 |
 |
Ethernet Switch
 |
 |
NIC B
```

---

## RoCE v2

This is what modern data centers mostly use.

Stack:

```
Application
    |
RDMA Verbs
    |
RDMA Transport
    |
UDP
    |
IP
    |
Ethernet
```

Now packets can be routed:

```
Server A

  |
  |
IP Network

  |
  |

Server B
```

This is why RoCE v2 became popular.

---

# 3. Where is the Queue Pair number on the wire?

Earlier we saw:

```
Machine A

QP 15

      communicates with

Machine B

QP 42
```

The packet needs to identify:

> "This packet belongs to QP 42."

That information exists in the RDMA transport headers.

A simplified packet:

```
Ethernet
 |
IP
 |
UDP
 |
BTH
 |
Payload
```

The key RDMA header is:

```
BTH
```

---

# 4. Base Transport Header (BTH)

BTH = Base Transport Header.

Almost every RDMA packet has one.

Conceptually:

```
+----------------------+
| Opcode               |
+----------------------+
| Destination QP       |
+----------------------+
| Packet Sequence Num  |
+----------------------+
| Flags                |
+----------------------+
```

The important fields:

---

## Opcode

Tells the receiver what operation this is.

Examples:

```
SEND

RDMA WRITE

RDMA READ Request

RDMA READ Response

Atomic
```

The receiving RNIC sees:

```
Opcode = RDMA WRITE
```

and knows:

> "I need to perform a memory write."

---

## Destination QP

This maps directly to the QP concept we discussed.

Packet arrives:

```
Destination QP = 42
```

RNIC lookup:

```
QP Table

QP 42
 |
 +-- State = RTS
 +-- PD = 7
 +-- Memory mappings
```

Now the packet is associated with the correct RDMA endpoint.

---

## Packet Sequence Number (PSN)

This is the RDMA equivalent of TCP sequence numbers.

Example:

```
Packet 1

PSN = 100


Packet 2

PSN = 101


Packet 3

PSN = 102
```

The receiver expects:

```
next PSN = 103
```

If:

```
105 arrives
```

the RNIC knows packets are missing.

---

# 5. RDMA WRITE packet

Let's map it to what we already know.

Application:

```
RDMA WRITE

Local buffer

        --->

Remote memory
```

The packet contains:

```
+----------------+
| BTH            |
+----------------+
| RETH           |
+----------------+
| Data           |
+----------------+
```

The important new header is:

```
RETH
```

Remote Extended Transport Header.

---

# 6. RETH: How does the remote RNIC know where to write?

This is the magic part.

The packet carries:

```
Remote Address

Remote Key (rkey)

Length
```

Example:

```
RETH

Virtual Address:

0x80000000


rkey:

9999
```

The receiving RNIC does:

```
Packet arrives

       |
       v

Find QP

       |
       v

Check rkey

       |
       v

Find Memory Region

       |
       v

DMA write
```

This directly connects:

```
Wire packet
     |
     |
rkey
     |
     |
Memory Region
```

---

# 7. What happens inside the receiving RNIC?

Suppose packet arrives:

```
RDMA WRITE

Destination QP:
42


Remote Address:
0x80000000


rkey:
9999
```

The RNIC performs:

---

## Step 1

Find QP:

```
QP table

42

State:
RTS
```

---

## Step 2

Check protection:

```
QP PD

=

MR PD
```

Must match.

---

## Step 3

Validate rkey:

```
rkey 9999 exists?

YES
```

---

## Step 4

Check permission:

```
Remote WRITE allowed?

YES
```

---

## Step 5

DMA:

```
Network packet

       |

       v

RNIC

       |

       v

RAM
```

CPU never executes a copy.

---

# 8. RDMA READ is different

RDMA READ is interesting because it has two directions.

Application:

```
Read remote memory
```

Packet flow:

```
Requester                 Responder


READ Request
--------------------->


                 READ Response
<---------------------


```

The request contains:

```
Remote address

rkey
```

The response contains:

```
Data
```

The responder RNIC:

* validates rkey
* reads memory
* sends data back

The responder CPU is not involved.

---

# 9. SEND packet

SEND is different because it does not contain a remote address.

Why?

Because the receiver already posted a buffer.

Packet:

```
+-------------+
| BTH         |
+-------------+
| Payload     |
+-------------+
```

Receiver:

```
Receive Queue

Buffer A
Buffer B
Buffer C
```

When packet arrives:

```
RNIC

matches SEND

to Receive WR

copies data

generates CQE
```

---

# 10. Reliability: how RDMA replaces TCP

A common question:

> "RoCE uses UDP. How can it be reliable?"

Important:

UDP is only the outer transport.

RDMA provides its own reliability.

For Reliable Connection (RC):

```
Sender

SEND packet
    |
    |
    v

Receiver

ACK packet
```

The receiver sends acknowledgments at the RDMA layer.

The RNIC handles:

* packet ordering
* duplicate detection
* retransmission
* timeout
* retry counters

The CPU is not involved.

---

# 11. ACK packets

Conceptually:

```
Sender:

PSN 100
PSN 101
PSN 102


Receiver:

ACK 102
```

Meaning:

> "I received everything up to 102."

If sender does not receive ACK:

```
Timeout
```

RNIC retransmits.

---

# 12. Why RoCE needs lossless Ethernet

This is one of the most important practical points.

Traditional Ethernet:

```
Packet lost

      |

TCP retransmits
```

The CPU/software stack handles recovery.

RoCE:

```
Packet lost

      |

RNIC retransmits
```

But RNICs need predictable behavior.

Packet loss causes:

* retries
* congestion
* performance collapse

Therefore RoCE deployments often use:

* Priority Flow Control (PFC)
* Explicit Congestion Notification (ECN)

to reduce packet loss.

---

# 13. Mapping software objects to wire objects

This is the important programming view.

| Software concept | Wire equivalent                 |
| ---------------- | ------------------------------- |
| QP               | Destination QP in BTH           |
| QP state         | RNIC validation                 |
| PSN              | Packet ordering                 |
| MR               | Remote memory target            |
| rkey             | Permission capability in packet |
| RDMA WRITE       | Opcode + RETH + data            |
| RDMA READ        | Request/response packets        |
| SEND             | Payload matched to Receive WR   |
| CQE              | Completion after wire operation |

---

# 14. The complete RDMA WRITE journey

Let's put everything together.

## Application

Creates:

```
QP
MR
CQ
```

Registers memory:

```
Address:
0x80000000

rkey:
9999
```

---

## Connection setup

Exchange:

```
QP number

GID

PSN

rkey

Address
```

---

## Application posts:

```
RDMA WRITE WR
```

---

## RNIC creates packet:

```
Ethernet

IP

UDP

BTH:

 opcode = WRITE
 QP = 42
 PSN = 100


RETH:

 address = 0x80000000
 rkey = 9999


DATA
```

---

## Remote RNIC:

```
Receive packet

        |

Find QP

        |

Validate rkey

        |

DMA write

        |

Generate completion
```

---

# 15. What should an RDMA programmer know?

For normal RDMA programming, the most useful wire-level knowledge is:

### Must understand

✅ QP number identifies the endpoint
✅ PSN provides ordering/reliability
✅ rkey identifies remote memory permission
✅ RDMA WRITE carries address + rkey
✅ SEND requires posted receives
✅ RNIC performs ACK/retry without CPU

---

### Usually not necessary initially

You can postpone:

* exact BTH bit layouts
* opcode numeric values
* CRC calculations
* UDP port details
* InfiniBand link-layer fields

Those matter when debugging with packet captures or writing RNIC firmware/drivers.

---

# The complete mental model

You can now visualize the entire path:

```
Application

    |
    |
RDMA Verb

    |
    |
Work Request

    |
    |
Queue Pair

    |
    |
RNIC

    |
    |
Creates:

Ethernet
   +
IP/UDP
   +
RDMA headers
   +
Payload

    |
    |
Network

    |
    |
Remote RNIC

    |
    |
Validate:

QP
PD
rkey
permissions

    |
    |
DMA

    |
    |
Remote Memory
```

This is the bridge between the software model and the hardware/network model.

A very natural next topic after this would be **RoCE performance engineering**: why latency is low, where bottlenecks appear, how MTU, CQ moderation, inline data, doorbells, PCIe, and NUMA affect real RDMA applications. That is where RDMA programming moves from "making it work" to "making it fast."


-----------------------------------------------------------------------------------------------

## RoCE performance engineering

Excellent. This is where RDMA moves from **"understanding the mechanism"** to **"making systems actually fast."**

A common misconception is:

> "RDMA is fast because it bypasses the CPU."

That is only part of the story.

Real RoCE performance comes from optimizing the entire path:

```text
Application
    |
    |
CPU / NUMA
    |
    |
Memory
    |
    |
PCIe
    |
    |
RNIC
    |
    |
Ethernet Fabric
    |
    |
Remote RNIC
    |
    |
Remote Memory
```

Every section can become a bottleneck.

We'll go through the major performance engineering topics:

1. Latency breakdown
2. CPU and NUMA effects
3. PCIe bottlenecks
4. Doorbells and posting efficiency
5. Inline data
6. MTU optimization
7. Completion Queue tuning
8. Queue Pair scaling
9. Memory registration cost
10. RoCE congestion control
11. Practical tuning methodology

---

# 1. Understanding RDMA latency

Let's start with a simple RDMA WRITE.

Application:

```text
Post WR
```

until remote memory changes:

```text
Remote Memory Updated
```

The latency consists of:

```
Application
    |
    | 1. Build Work Request
    |
    v
Doorbell
    |
    | 2. Notify RNIC
    |
    v
RNIC Processing
    |
    | 3. DMA Read local data
    |
    v
PCIe Transfer
    |
    | 4. Ethernet transmission
    |
    v
Switch Fabric
    |
    | 5. Remote NIC receive
    |
    v
Remote DMA Write
    |
    v
Remote Memory
```

A typical modern system might look approximately like:

```
Software overhead       : hundreds of ns
RNIC processing         : hundreds of ns
PCIe transfer           : sub-us range
Network fabric          : sub-us to several us
Remote DMA              : hundreds of ns
```

The exact numbers depend heavily on hardware.

The important point:

> RDMA removes CPU copies, but it does not remove physics.

---

# 2. CPU affinity and NUMA (one of the biggest factors)

Modern servers are usually NUMA systems.

Example:

```
          CPU Socket 0
              |
              |
          Memory 0
              |
              |
            PCIe
              |
              |
            RNIC


          CPU Socket 1
              |
              |
          Memory 1
```

The ideal path:

```
Application Thread

CPU Socket 0

      |
      |

Memory 0

      |
      |

RNIC attached to Socket 0
```

The bad path:

```
Application Thread

CPU Socket 1

      |
      |

Memory 1

      |
      |

Remote NUMA Access

      |
      |

RNIC on Socket 0
```

Now every DMA operation crosses the CPU interconnect.

Possible effects:

* higher latency
* lower bandwidth
* more CPU utilization

---

## NUMA rule

A good RDMA design tries to align:

```
Application thread
        |
        |
Memory buffer
        |
        |
RNIC PCIe location
```

on the same NUMA node.

---

Useful Linux commands:

Find NIC PCI location:

```bash
lspci -vv
```

Find NUMA topology:

```bash
numactl --hardware
```

Find CPU/NIC locality:

```bash
lstopo
```

---

# 3. PCIe bottleneck

The RNIC is a PCIe device.

Data path:

```
CPU Memory

    |
    |
PCIe Bus

    |
    |
RNIC

    |
    |
Network
```

The PCIe link limits throughput.

Example:

A 200Gb/s NIC:

```
200 Gb/s

≈ 25 GB/s
```

requires a lot of PCIe bandwidth.

If the NIC is installed in:

```
PCIe Gen3 x8
```

it may not sustain full speed.

---

Modern high-speed NICs usually require:

```
PCIe Gen4 x16
```

or

```
PCIe Gen5 x16
```

depending on the NIC.

---

# 4. Doorbells: how the CPU talks to the RNIC

This is a very important RDMA performance concept.

When you post a Work Request:

```c
ibv_post_send()
```

the CPU writes a Work Queue Entry (WQE).

Something like:

```
Application

creates WQE

        |
        |
        v

Send Queue memory
```

But the RNIC does not automatically know:

> "A new WQE exists."

The CPU must notify it.

That notification is called a:

```
Doorbell
```

Conceptually:

```
CPU

writes WQE

   |

rings doorbell

   |

RNIC starts processing
```

---

## Why doorbells matter

If you send many tiny messages:

```
Message
Doorbell
Message
Doorbell
Message
Doorbell
```

the CPU spends significant time notifying the NIC.

---

Optimization:

Batch WQEs:

```
Write WQE 1
Write WQE 2
Write WQE 3
Write WQE 4

Ring doorbell once
```

This reduces CPU overhead.

---

# 5. Inline data

Normally an RDMA SEND looks like:

```
Application buffer

      |
      |
DMA READ

      |
      |
RNIC

      |
      |
Network
```

For small messages, this DMA read is unnecessary overhead.

Instead:

The data can be placed directly inside the WQE.

Example:

Normal:

```
WQE
 |
 |
pointer -> memory buffer
```

Inline:

```
WQE

+----------------+
| Header         |
| Data           |
+----------------+
```

The RNIC immediately sends it.

---

Advantages:

* lower latency
* fewer PCIe transactions
* less memory access

Typical use:

```
Small control messages
RPC headers
Metadata operations
```

---

Example:

Without inline:

```
CPU
 |
 | write WQE
 |
RNIC
 |
 | DMA read data
 |
Network
```

With inline:

```
CPU
 |
 | WQE contains data
 |
RNIC
 |
Network
```

---

# 6. MTU optimization

MTU determines packet size.

Common Ethernet MTUs:

```
1500 bytes
9000 bytes (jumbo frame)
```

---

Small MTU:

```
1 MB transfer

requires many packets
```

Example:

MTU 1500:

```
1,000,000 bytes

≈ 667 packets
```

MTU 9000:

```
≈112 packets
```

Fewer packets means:

* fewer headers
* fewer interrupts
* fewer RNIC operations

---

For RoCE deployments:

Jumbo frames are commonly used:

```
MTU = 9000
```

But every device must support it:

```
Server NIC
 |
Switch
 |
Router (if any)
 |
Remote NIC
```

A mismatch causes problems.

---

# 7. Completion Queue tuning

The naive model:

```
Send request

Wait for completion

Send next request
```

This is terrible for performance.

---

Better:

Post many operations:

```
Send Queue:

WR1
WR2
WR3
WR4
WR5
```

Then poll:

```
Completion Queue:

CQE1
CQE2
CQE3
CQE4
```

---

## CQ polling vs interrupts

Two models:

### Interrupt driven

```
Operation completes

       |
       |
Interrupt CPU
```

Good for:

* low traffic
* power saving

Bad for:

* high throughput

---

### Polling

CPU continuously checks:

```
while(1)
{
    poll CQ
}
```

Advantages:

* lowest latency
* high throughput

Disadvantage:

* consumes CPU

High-performance systems usually poll.

---

# 8. CQ moderation

Instead of generating completion for every operation:

```
WR1 complete
interrupt

WR2 complete
interrupt

WR3 complete
interrupt
```

The RNIC can delay:

```
Generate completion after:

100 operations

or

50 microseconds
```

This reduces CPU overhead.

Tradeoff:

Lower CPU usage

but

Higher latency.

---

# 9. Queue Pair scaling

A single QP may not achieve maximum throughput.

Why?

Because one QP has:

* ordering constraints
* limited outstanding operations

Applications often create:

```
Many QPs

QP1
QP2
QP3
...
QP100
```

distributed across threads.

Example:

```
CPU core 0
 |
 QP1
 |
 RNIC


CPU core 1
 |
 QP2
 |
 RNIC
```

This improves parallelism.

---

# 10. Outstanding operations and pipeline depth

RDMA performance depends heavily on keeping the pipeline full.

Bad:

```
POST

WAIT

POST

WAIT
```

Only one operation in flight.

---

Good:

```
POST
POST
POST
POST
POST

wait for completions later
```

The RNIC can now have many operations outstanding.

This is similar to CPU instruction pipelining.

---

# 11. Memory registration optimization

Remember:

```
ibv_reg_mr()
```

is expensive.

Bad:

```
For every message:

register memory

send

deregister
```

Good:

```
Startup:

allocate buffer pool

register once


Runtime:

reuse buffers
```

---

Many RDMA applications use:

```
Memory pool

+----------------+
| Buffer 1       |
| Buffer 2       |
| Buffer 3       |
| Buffer 4       |
+----------------+
```

---

# 12. RoCE congestion control

This is unique compared with InfiniBand.

RoCE runs over Ethernet.

Ethernet networks can drop packets.

RDMA hates packet loss.

Therefore RoCE deployments usually use:

## PFC

Priority Flow Control

Idea:

```
Switch queue filling

        |
        |
Pause sender
```

Prevents packet loss.

---

## ECN

Explicit Congestion Notification.

Switch marks packets:

```
Congestion detected

      |

Set ECN bit
```

Receiver tells sender:

```
Slow down
```

---

The goal:

```
High bandwidth

+

Low packet loss
```

---

# 13. Latency vs throughput tuning

There is always a tradeoff.

## Low latency configuration

Prefer:

* inline data
* polling
* small queues
* fewer outstanding operations
* no CQ moderation

Example:

```
RPC system
Trading system
```

---

## High throughput configuration

Prefer:

* batching
* large messages
* jumbo MTU
* many outstanding WRs
* CQ moderation

Example:

```
Storage
AI training
Large data transfer
```

---

# 14. A practical tuning checklist

When tuning a RoCE application:

## Hardware

Check:

```
NIC speed

PCIe generation

NUMA locality

Switch capability
```

---

## Network

Check:

```
MTU

PFC

ECN

Congestion
```

---

## Application

Check:

```
Memory registration reuse

QP count

WR batching

CQ polling

Inline thresholds
```

---

# 15. The performance mental model

A fast RoCE system keeps this pipeline full:

```
CPU thread

   |
   | produces WQEs

   v

Queue Pair

   |
   | doorbell

   v

RNIC

   |
   | DMA

   v

PCIe

   |
   | packets

   v

Network

   |
   v

Remote RNIC

   |
   | DMA

   v

Remote Memory
```

Performance problems happen when any stage is starved or overloaded.

---

## The most important practical lessons

If you remember only a few things:

1. **NUMA placement matters enormously.**
2. **Avoid frequent memory registration.**
3. **Batch work requests and doorbells.**
4. **Use inline data for small messages.**
5. **Use jumbo MTU for large transfers.**
6. **Keep enough outstanding operations to fill the pipeline.**
7. **Tune CQ handling based on latency vs throughput goals.**
8. **RoCE requires careful congestion management.**

---

A very useful next step would be a **complete walk-through of a real RoCE application architecture** (for example, a distributed storage system or AI parameter server) showing how threads, QPs, MRs, CQs, NUMA placement, and network tuning come together in a production design.

-------------------------------------------------------------------------------------

## complete walk-through of a real RoCE application architecture

Great. Let's now put all the RDMA pieces together into a **real production-style RoCE application architecture**.

I'll use a **distributed storage system** as the example first because it uses almost every RDMA feature:

* QPs
* PDs
* MRs
* MWs
* CQs
* SEND/RECEIVE
* RDMA READ/WRITE
* NUMA tuning
* batching
* congestion control

After that, we can map the same concepts to **AI training (parameter servers / AllReduce)**.

---

# Example System: RDMA-based Distributed Storage

Imagine:

```
             Client Nodes

        +----------------+
        | Application    |
        +----------------+
                |
                |
              RoCE
                |
                |
        +----------------+
        | Storage Server |
        +----------------+
```

The application wants to read/write data from a remote storage server.

Traditional path:

```
Application
    |
    |
Kernel TCP stack
    |
    |
Storage server
```

RDMA path:

```
Application

    |
    |
RDMA Verbs

    |
    |
RNIC

    |
    |
RoCE Network

    |
    |
Remote RNIC

    |
    |
Storage Memory
```

---

# 1. High-level architecture

A typical high-performance storage server:

```
+------------------------------------------------+
|                 Storage Server                  |
|                                                |
|                                                |
|  CPU Cores                                     |
|                                                |
|  +-------------+                               |
|  | IO Threads  |                               |
|  +-------------+                               |
|          |                                     |
|          |                                     |
|          v                                     |
|                                                |
|  RDMA Resources                                |
|                                                |
|  +-------------+                               |
|  | QP Pool     |                               |
|  +-------------+                               |
|                                                |
|  +-------------+                               |
|  | CQ Pool     |                               |
|  +-------------+                               |
|                                                |
|  +-------------+                               |
|  | MR Pool     |                               |
|  +-------------+                               |
|                                                |
|                                                |
|          RNIC                                  |
|            |                                   |
+------------|-----------------------------------+
             |
             |
          RoCE Fabric
```

---

# 2. Startup phase

RDMA systems usually have two phases:

## Phase 1: Initialization

Expensive operations happen here.

Example:

```
Create:

PD
CQ
QP
MR

Exchange:

QP information
rkeys
addresses
```

---

## Phase 2: Runtime

Only fast operations happen:

```
Post Work Request

Poll Completion

Reuse memory
```

The design goal:

> Move all expensive operations out of the data path.

---

# 3. Memory design

This is probably the most important part.

A storage server does NOT do:

```
Request arrives

Allocate memory

Register MR

Transfer

Deregister MR
```

That would destroy performance.

Instead:

```
Startup:

Allocate memory pool


+--------------------------------+
|                                |
| Registered Memory Pool         |
|                                |
| Buffer 1                       |
| Buffer 2                       |
| Buffer 3                       |
| Buffer 4                       |
|                                |
+--------------------------------+
```

Register once:

```
MR:

Base:
0x10000000

Size:
64GB

rkey:
12345
```

---

Runtime:

A request gets:

```
Buffer 23

Address:
0x10230000

rkey:
12345
```

The RNIC already knows this memory.

---

# 4. Connection establishment

RDMA needs connection setup.

Usually:

```
Application
    |
    |
TCP connection
    |
    |
Exchange:

- IP/GID
- QP number
- PSN
- rkey
- memory address
```

Example:

Client receives:

```
Storage Server

QP:
500


Memory:

Address:
0x80000000


rkey:
9000
```

Now the client can issue:

```
RDMA WRITE
RDMA READ
```

---

# 5. Queue Pair architecture

A common mistake is:

> "One application = one QP"

High-performance systems usually do:

```
CPU Core 0
    |
    QP 0


CPU Core 1
    |
    QP 1


CPU Core 2
    |
    QP 2


CPU Core 3
    |
    QP 3
```

Why?

Because QPs provide:

* ordering
* parallelism
* isolation

---

Example:

A storage server with:

```
64 CPU cores
```

might have:

```
64 IO threads

each owns:

1-4 QPs
```

---

# 6. Request processing example: WRITE

Suppose client wants:

```
Write 4KB block
```

---

## Step 1: Application prepares data

Client:

```
Memory buffer:

0x40000000


lkey:

1111
```

---

## Step 2: Client posts RDMA WRITE

Work Request:

```
Opcode:

RDMA_WRITE


Local:

Address:
0x40000000

lkey:
1111


Remote:

Address:
0x90000000

rkey:
9000
```

---

# 7. What happens in the RNIC?

Client RNIC:

```
Check:

lkey valid?

YES


DMA READ:

local memory
       |
       v
RNIC
```

Then creates:

```
RoCE packet:

BTH:

Opcode = WRITE
QP = 500
PSN = 1001


RETH:

Address:
0x90000000

rkey:
9000


DATA:

4KB
```

---

# 8. Storage server receives packet

Remote RNIC:

```
Packet arrives

       |
       |
Find QP 500

       |
       |
Check rkey

       |
       |
Check permission

       |
       |
DMA WRITE

       |
       |
Memory updated
```

CPU is not involved.

---

# 9. Completion handling

Client:

```
Completion Queue

CQE:

WR ID:
555

Status:
SUCCESS

Opcode:
RDMA_WRITE
```

The application knows:

```
write completed
```

---

# 10. Why use RDMA WRITE for storage?

Because the remote CPU does not need to copy data.

Compare:

## TCP storage

```
NIC

 |
 v

Kernel buffer

 |
 v

Storage application

 |
 v

Disk cache
```

Several copies.

---

## RDMA WRITE

```
NIC

 |
 v

Registered memory

 |
 v

Storage processing
```

Near zero-copy.

---

# 11. Where Memory Windows fit

Now imagine multiple clients.

Storage server has:

```
64GB cache
```

But each client should only access its own area.

Instead of:

```
Give all clients MR rkey
```

(which is dangerous)

Use MW:

```
MR

64GB cache


+----------------+
| Client A MW    |
| rkey=1001      |
+----------------+


+----------------+
| Client B MW    |
| rkey=1002      |
+----------------+
```

Now:

Client A:

```
Can access only its window
```

Client B:

```
Can access only its window
```

---

# 12. Performance optimization example

Suppose workload:

```
Millions of 4KB IO requests/sec
```

Bad design:

```
For every IO:

Create WR
Ring doorbell
Wait CQ
```

---

Optimized design:

## Batch requests

```
Create:

WR1
WR2
WR3
WR4
WR5

Ring doorbell once
```

---

## Poll CQ

Instead of:

```
Interrupt

Interrupt

Interrupt
```

Use:

```
while(true)
{
    poll CQ
}
```

---

## Inline small metadata

Example:

IO request:

```
Block number
Length
Flags
```

Only 32 bytes.

Use:

```
Inline SEND
```

No DMA required.

---

# 13. NUMA-aware design

Bad:

```
Thread

CPU socket 1

      |
      |
Memory socket 1

      |
      |
RNIC socket 0
```

Good:

```
Thread

CPU socket 0

      |
      |
Memory socket 0

      |
      |
RNIC socket 0
```

Production systems often explicitly bind:

```
Thread
+
Memory
+
QP
+
NIC
```

to the same NUMA node.

---

# 14. Failure handling

Production RDMA systems must handle:

## Link failure

Example:

```
Switch failure

      |
      |
QP detects error
```

Application receives:

```
CQE:

WR_FLUSH_ERR
```

---

## Remote failure

Example:

```
Server crashes
```

Client sees:

```
Timeout

QP enters ERROR state
```

Application must:

```
Destroy QP

Reconnect

Exchange keys again
```

---

# 15. Monitoring production RoCE

Engineers watch:

## NIC counters

Examples:

```
Packets transmitted

Packets received

Retries

Dropped packets
```

---

## RDMA counters

Important:

```
Retry count

RNR retry

Completion errors

QP errors
```

---

## Network counters

Important:

```
PFC pause frames

ECN marks

Queue drops
```

---

# 16. Complete production data path

Now the whole picture:

```
                 Application

                     |
                     |
              IO Request

                     |
                     v

              RDMA Work Request

                     |
                     v

                  Queue Pair

                     |
                     |
                  Doorbell

                     |
                     v

                    RNIC

                     |
                     |
                  PCIe DMA

                     |
                     v

                RoCE Packet

                     |
                     v

               Ethernet Fabric

                     |
                     v

              Remote RNIC

                     |
                     |
             rkey/QP validation

                     |
                     v

                Remote DMA

                     |
                     v

              Registered Memory

                     |
                     v

                Completion Queue
```

---

# The key production lessons

If you design a real RoCE application, the priorities usually are:

### 1. Memory management

* Register memory once
* Reuse buffers
* Avoid MR churn

### 2. CPU architecture

* NUMA-aware placement
* Dedicated polling cores if latency matters

### 3. Queue design

* Multiple QPs
* Batch WQEs
* Avoid excessive doorbells

### 4. Network design

* Jumbo MTU
* ECN/PFC tuning
* Monitor congestion

### 5. Completion strategy

* Polling for latency
* Moderation for throughput

---

The next natural deep dive is **how Linux actually implements this stack**:

```
Application
   |
libibverbs
   |
rdma-core
   |
Kernel RDMA subsystem
   |
mlx5 driver
   |
NIC firmware
```

That is where RDMA programming meets the Linux kernel and actual NVIDIA/Mellanox ConnectX hardware.
