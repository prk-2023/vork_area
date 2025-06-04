# Rust as a Systems programming Langauge

## -> Fast, No Segfaults & Guaranteed Thread Safety <-

### 1. Introduction: 

Rust is a systems programming language developed by Mozilla Research, designed to offer reliability, memory
safety, high performance(fast), and freedom from data races. 

Rust combines high-level abstractions with fine grained control over system resources, such as memory
management, making its well-suited for systems programming. 

Rust is a statically typed language offering type inference. This feature allows the compiler to deduce the
type of variable in most contexts based on surrounding expressions and statements. Consequently, it reduces
the manual effort typically associated with static typing, thereby alleviating some of the burden placed on
the programmer.

Rust also introduces a novel _*Ownership*_ and _*Borrowing*_ model, which enabled static safety guarantees
and compile-time memory management. This approach eliminates the need for a garbage collector. The system
draws inspiration from Cyclone's region-based memory management. In Rust these regions are referred to as
_*lifetimes*_, which the compiler uses to track the scope of objects and determine their deallocation
statically.

Several features of Rust draw inspiration from research conducted on Sing# (sing sharp), a programming
language developed as part of the Singularity research project. This project involved the construction of an
OS that isolated SW processes exclusively through its type system, effectively relying on the compiler for
isolation. Elements of these concepts are evident in Rust's communication channels and its stringent type
system. 
Singularity OS depended on compiler-enforced isolation for resource management and other security-related
functions. 
Sing# employed a runtime system and garbage collection to uphold certain safety guarantees, Rust achieves
similar assurances solely through static code analysis performed by the compiler.

Rust provides zero-cost abstractions through the use of _*traits*_.
Traits are conceptually similar to _interfaces in Java_, enabling type-generic implementations that 
re-converted into type-specific code during compilation.
This approach allows abstract specifications to be inlined and hence obtain good performance. 

Further Rust offers dynamic dispatch to allow for polymorphism, giving the programmer the choice when to
trade off performance against flexibility.
Rust allows for polymorphism-writing code that can work with different type-through two main strategies.
- Static dispatch (mono morphization) using _*generics*_.
- Dynamic Dispatch using _*trait objects*_ ( eg: *&dyn Trait or Box<dyn Trait>* )
- 
