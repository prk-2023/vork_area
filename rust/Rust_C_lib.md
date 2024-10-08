# Rust and C Libs Concept:

- Rust libraries may never exist. 

    - This is the reason why when we build anything in Rust using cargo, it would download many number of
      crates in cargo and which can spends a long time in compilation of the project.

- Every major system in the world is written in the C language, Like the Linux kernel, many other OS's and
  foundational software's. While C is extremely fast, the C language comes with many ways for the
  programmers to shoot in there own foot or the design forces the programmers to write compromised or unsafe
  code from security stand point. ( this is often countered in the programmers community as skill issue )
  The common way we often see to handle this is by adding tons of new security features to the existing 
  C language and the C standard library on the daily bases.

  Statistically its found that 70% of security vulnerabilities originate from from memory issues from C, and
  at the same time Rust is not the straight forward language to learn with, it has a wired and messy syntax
  and often the Rust compiler gets mad at the programmers by throwing tons of errors, adding to this the
  compilation time takes for ever for a sizable project. 

- The reason for the long compilation time and large binaries sizes are:

    - Most of the requirements for a c programs come from its inbuilt C library and other libraries that are
      installed in the system, which get linked with the program on build. This allows C binary to have
      small sizes, on the other hand in Rust this libraries do not exist and actually they will never exist.

    - So what cargo does while compilation with all the crates (are they libraries?) that we download ....
      Cargo is a package manager and its job is to manage libraries but these libraries are not the same as
      libraries in C language. 

      More on this below: 

---

- Every C prog depends on the "GNU C library" or "libc", which consists of all the functions that we use in
  writing the C program like open(), close(), read()..... These functions can be looked up using one of the
  below commands:
  
  1. nm -g --defined-only --demangle /usr/lib/libc.so.6 | grep -v '^__'
  2. objdump -T /usr/lib/libc.so.6 | grep 'FUNC'
  3. readelf -s /usr/lib/libc.so.6 | grep 'FUNC'
  4. ldd /usr/bin/ls | grep libc | xargs nm -g --defined-only --demangle | grep -v '^__'

This information is in the libc Dynamic Symbol Table: 

A data structure that contains information about the symbols ( functions and variable ) defined in the
shared library or executable file.

This Table gets used by the dynamic linker/loader to resolve symbol references at runtime.

Dynamic Symbol Table: (A data structure consists of)
1. Symbol name
2. Symbol type (function, variable ...)
3. Symbol address (memory location)
4. Symbol size 
5. Symbol binding (local or global)
6. Symbol visibility (hidden or visible)

The Dynamic Symbol Table is used to:
1. Resolve symbol references between shared library and executables.
2. Resolve symbol references within a shared library.
3. Provided information to debugger about the symbols in a program.

To show the Dynamic Symbol Table:
1. objdump -T /usr/lib/libc.so.6   (display Dynamic Symbol Table)
2. objdump -T --demangle /usr/lib/libc.so.6   (display Dynamic Symbol Table with details)
3. objdump -T --demangle --dynamic-syms /usr/lib/libc.so.6 (show symbol table + symbol bindings)
4. objdump -T --demangle --dynamic-syms --visibility=hidden /usr/lib/libc.so.6 (visibility)
5. objdump -T --demangle --dynamic-syms --size-sorted /usr/lib/libc.so.6 ( symbol size )
6. objdump -T --demangle --dynamic-syms --type-sorted /usr/lib/libc.so.6 ( symbol type )

NOTE: /usr/lib/libc.so.6 file version number may vary on different linux systems.

---
 
- All this functions that get used in the C program are pre-written and readily available in the compiled
  format to use.

- libc exists as a shared object which lives on the file system as a file that the loader can reach into for
  functions/variables that it needs to run the program at runtime.

- The reason C language is able load to these functions/variables from the 'libc' and specifically in
  Linux is because of the definition of "ELF Application Binary Interface" or ELF's ABI, which is
  defined for the ELF file format that adheres to function calls in a way that are compatible with C. 
  This ABI is the one that exposes an interface for your program an ELF to reach into an other ELF and
  find any function that it needs. The ELF ABI specifies a table of functions or what we call as the
  symbol table that a program can parse specifically to find a function that is exported by that program
  and this is exactly how 'libc' exactly exposes function calls.

- This ELF ABI also guarantees that the data defined in one program is in the same order and in same
  location as another. 

  So struc x with elements a,b,c will always be in that same order, allowing interoperability not just
  among functions but data in libraries as well.

- Rust as of now does not have a stable ABI like the C language ELF ABI Interface to share information
  across multiple binaries, So this is the reason Cargo packages exist but Rust libraries don't. All the
  cargo packaging nothing but a blob of source that we locally compile and it combines all of that code
  into one big blob of code inside of a singular ELF. 

- This means any time we compile a Rust program we are forced to compile every cargo package together
  required for that project and stacking or packing them into a single binary. 

- This is the reason Rust has high compilation time and larger binary file size. 

- How to fix this?

    - Organizing an ABI for a language and spec like C language ELF is simple, as C is just a high level
      abstraction around around Assembly So there isn't too much information to hide, just basic types and
      function calls.

    - Coming to Rust which is a totally a different beast, 'structs' and Rust really aren't guaranteed to be
      in any particular in any particular order across program boundaries as long as 'a' and 'b' are in the
      structure its fine. And "Generics" introduce a whole other world of problems as they are statically 
      dispatched and get built at compilation time and there are many other complex issues with types in 
      the Rust language,  and the Rust power from compilation time static analyzers which perform checks
      like the "Borrow-Checker"  which is not possible if there's a compiled binary, (if you pass a mutable
      reference into a compiled how is it possible for the borrow checker to make sure that the reference is
      used in a way that is safe....)

---
    The above are some reason why Rust dose not have a C ABI, But the language allows us to create types and
    functions that are exposed using the ELF ABI using the "rep C syntax". 
    The "rep C decorator" basically tells the Rust compiler to do what C does order the structure the way C
    language would do, create symbols the way C language or ELF would, and create a foreign function
    interface to call through.

    ex:
        ```Rust
            #[repr(rust)]
            struct Vertex {
                x: f32,
                y: f32,
                b: Box<f32>
            }
            #[repr(rust)]
            struct Vertex2 {
                x: f32,
                y: f32,
                b: Box<f32>
            }
            fn main() {
                let v = Vertex{x: 42.0, y:0.0, b: Box::(42.0)};
                let v2 = Vertex2{x: 42.0, y:0.0, b: Box::(42.0)};
            }

        ```
    This actually will not solve our problem in Rust as using "repr c" does not actually allow any of the
    Rust features to cross the application boundary as with the 'ELF ABI' interface allows for a C library,
    we can not expose a function with unique types using the exotic typing that Rust has also any function
    call crosses 'repr c' foreign function interface which is unsafe and disable the "borrow checker". 

    So 'repr c' ( '#[repr(rust)]' ) is great for converting a Rust code into a C library but not creating
    Rust-to-Rust binary objects. 

- There are many open merge requests into the Rust line Master to produce their own ABI, this would be
  feature complete and make the most sense for future progress. 

  ex: https://github.com/rust-lang/rust/pull/105586

  [experimental feature gate proposal proposes developing a new ABI, extern "crabi", and a new in-memory
  representation, repr(crabi), for interoperability across high-level programming languages that have safe
  data types.]



