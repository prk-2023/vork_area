# Rust Linux @ kernel History

Ref: https://lwn.net/Kernel/Index/#Development_tools-Rust

- [Supporting Linux kernel development in Rust](https://lwn.net/Articles/829858/)
    - A large fraction of kernel security bugs come from memory safety issues in C.
    - Rust was seen as a way to reduce this class of bugs via:
        Ownership model/Borrow checker/No manual mem management errors (use-after-free, buffer overflows, etc.)
    - So the motivation was mainly:
        Improve kernel safety without sacrificing performance.

    - Early proposal included:
        - Allowing Rust code to be linked into the kernel
        - Starting with new modules / drivers, not core kernel rewriting
        - Experimenting with a “Rust layer” on top of existing C kernel infrastructure
    - This was explicitly framed as:
        - incremental adoption
        - not a big-bang replacement

    - technical challenges:
        - Interfacing with C kernel APIs: This was the biggest issue. 
          The kernel API is:
            'huge' / 'macro-heavy' / 'often inline-only' 
        - Rust tools like `bindgen` can help, but:
            - many APIs don’t translate cleanly
            - idiomatic Rust wrappers would require significant manual effort

    - Designing Rust abstractions: 
        - Two styles were debated:
    - key tension:
        - “raw bindings” → easier but unsafe/ugly
        - “safe Rust abstractions” → better safety but huge engineering effort
            - kernel is traditionally written in C.
            - C gives low-level control but also makes it easier to introduce memory safety bugs ( use-after-free,
      buffer overflow, etc )
            - Rust offers memory safety guarantees without garbage collector using owenership/borrowing system. 
    - Earlier developer were exploring how to allow rust code inside kernel .
        - Rust layer that could interact with existing C kernel code or for a gradual introduction 
