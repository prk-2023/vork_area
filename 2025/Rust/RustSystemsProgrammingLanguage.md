# Rust Systems programming Language:



### Introduction:

Rust was developed at Mozilla Research and aims at being reliable memory safe, fast and data race free.

Provides high-level abstractions while allowing for tight control over resources as i.e: memory management
for systems programming.

The below are the most important features that most important features of Rust which are necessary to
understand the subsequent sections.

Rust is a statically types Language offering type inference ( i.e compiler can infer the type in most of the
situations by the surrounding expressions and statements, this take off the burden to some extent on the
programmer.)

Ownership and Borrowing model was introduced allowing static safety guarantees and compile-time memory
management, eliminating the need for garbage collection ( Read 2015 The Rust developers 2016b).
The system was inspired by cyclones region-based memory management ( The Rust developers 2016b).
Rust calls regions _life times_ and they are used by the compiler to track an object and issue its
de-location statically (Read 2015).


