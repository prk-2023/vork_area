# Intro to Network programs using Rust.


1.0 General Networking Introduction:
    Basics, layers, IP addressing, TCP,UDP .. DNS ...
2.0 General Rust Intro and Using Rust to program TCP,UDP... 


---

## General Networking Introduction:

- RFC ( Request for comment , a document that described how a proposed system should work ). RFC are first
  steps towards standardizing a protocol of a system. The term Internet was first used in RFC 675 which
  proposed a standard for TCP.

- Problem solving in computer science is focused on subdividing a problem into smaller, hopefully
  independent components that can be solved in isolation. Once this is done all that is required is a set of
  rules on how those components should communicate to have solution to the larger problem. These set of
  rules with pre-agreed data format is called protocol. A network is composed of a number of layers, each of
  which has a fixed protocols. In 1977 OSI model was first attempt to standardizing protocols, this model
  consists of the following layers:

  1. Physical Layer: defines how data is transmitted in physical medium in terms of its electrical/physical
     characteristics. ( includes wire, optical, wireless, ..)

  2. Data Link Layer: defines how data is transmitted between two nodes connected by a physical medium,
     layer deals with prioritization between multiple partied trying to access the wire simultaneously. 
     Redundancy in the transmitted bits to minimize errors during transmission. This is referred to as
     coding.

  3. Network Layer: How pkts ( made of multiple units of data ) are transmitted between networks. Thus this
     layer needs to define how to identify hosts and network uniquely.

  4. Transport layer: Mechanism to reliably deliver variable length message to hosts ( same of different
     network ). This layer defined a stream of pkts that the receiver can then listen to.

  5. Session layer: Define how apps running on a hist should communicate. This layer needs to differentiate
     between applications running on the same host and deliver pkts to them.

  6. Presentation layer: Common formats for data representation so that different applications can interlink
     seamlessly. ( this layer also takes care of security ).

  7. App layer: How use-centric apps should send and receive data. ( ex: browser a user app using HTTP (app
     layer protocol) to talk to a web server. )

The above layers can also be grouped into two :
    - Media layer : [ Physical : Bits ( media, signal and binary transmission ) ]
                    [ Data Link: Frames ( Physical addressing (MAC and LLC ))   ]
                    [ Network  : Packets ( Path determination and Logical Addressing (IP))]
 
    - Host layer  : [ Transport: Segments ( end-to-end connections and reliability ) ]
                    [ Session : Data ( Interhost communication )  ]
                    [ Presentation: Data ( Data representation and encryption ) ]
                    [ Application: Data ( Network process to application ) ]

The above OSI was a step for standardizing this model, DARPA came up with a full implementation of the much
simpler TCP/IP model ( also called IP : Internet protocol ). This model has the following layers, from
closesto the physical medium to the farthest:

- Hardware interface layer: This is a combination of layers one and two of the OSI model. 
  This layer is responsible for managing Media Access control, handle transmission and reception of bits,
  retransmission, and coding ( some texts on networking differentiate between the hardware interface layer
  and the link layer.) This results in a 5 layer model instead of 4. 

- IP Layer: This layer corresponds to  layer 3 of OSI, and responsible for two tasks:
    - Addressing Hosts and Networks so that they can be uniquely identified and given a source and a
      destination address, and computing the path between those given a bunch of constrains ( routing ).

- Transport Layer: This layer corresponds to layer 4 of the OSI stack. 
  This layer converts raw packets to a stream of packets with some guarantees: In order delivery (for TCP)
  and randomly ordered delivery ( for UDP ).

- Application Layer: This layer combines layers 5 to 7 of the OSI stack and is responsible for identifying
  the process, data formatting and interfacing with all user level applications.

The hardware interface layer handles collection of bits and bytes transmitted by hosts, the IP layer handles 
packets (the collection of a number of bytes sent by a host in a specific format), 
the transport layer bunches together packets from a given process on a host to another process on another 
host to form a segment (for TCP) or datagram (for UDP), and the application layer constructs application 
specific representations from the underlying stream. For each of these layers, the representation of data 
that they deal with is called a Protocol Data Unit (PDU) for that layer. As a consequence of this layering, 
when a process running on a host wants to send data to another host, the data must be broken into individual
chunks. 
As the chunk travels from one layer to another, each layer adds a header (sometimes a trailer) to the chunk,
forming the PDU for that layer. 
This process is called encapsulation. Thus, each layer provides a set of services to layers above it, 
specified in the form of a protocol. 



