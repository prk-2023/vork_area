# LLVM ( Low level virtual machine )


To understand what a **LLVM** (Low Level Virtual Machine) package consists of, you have to stop thinking of 
it as a single "program" and start thinking of it as a **massive toolbox** for building compilers.

The LLVM project is a collection of modular, reusable compiler and toolchain technologies. 

Here is the breakdown of what is inside the "package."

---

## 1. The Core: LLVM Intermediate Representation (IR)
The heart of LLVM is the **IR**. It is a low-level, RISC-like programming language that is "universal." 
    * **The Trick:** Front-ends (like Clang for C or the OCaml compiler) turn code into IR. Then, LLVM
      optimizes that IR. Finally, back-ends turn that IR into machine code (x86, ARM, etc.).
    * This "Common Language" is what allows one optimization tool to work for dozens of different
      programming languages. 


---

## 2. The Major Components

When you install the LLVM package, you are getting several heavy-hitting tools:

### **Clang**

The "Front-end." It is the part that actually reads C, C++, and Objective-C code. It checks for syntax
errors and converts your code into LLVM IR. 

It is designed to be much faster and provide better error messages than the older GCC.

### **LLD (The Linker)**

A high-performance replacement for system linkers (like `ld`). It takes all the separate pieces of your 
compiled program and stitches them together into a single executable file.

### **LLDB (The Debugger)**

A next-generation debugger built on top of LLVM libraries. It is the default debugger for Xcode on macOS 
and is a major alternative to GDB.

### **MLIR (Multi-Level IR)**

A newer addition used heavily in **Machine Learning**. It helps compilers handle complex operations like 
those found in `TensorFlow` or `PyTorch` by creating specialized intermediate languages.

---

## 3. The Utility Tools (The "LLVM Binaries")

If you look into the `/bin` folder of an LLVM installation, you’ll find these essential utilities:

* **`opt`**: The Optimizer. It reads LLVM IR, runs thousands of "passes" to make the code faster (like
  removing dead code), and spits out optimized IR.

* **`llc`**: The Static Compiler. It takes the IR and converts it into assembly code for a specific
  processor (e.g., your Intel i9 or Apple M3 chip).

* **`llvm-as`**: The Assembler. It turns human-readable IR (`.ll` files) into computer-readable bitcode 
  (`bc` files)

* **`llvm-dis`**: The Disassembler. It turns the computer-readable bitcode back into human-readable text.

---

## 4. The "Package" Summary Table

| Component | Role | Analogous to (in GCC world) |
| :--- | :--- | :--- |
| **Clang** | Language Parser | `gcc` / `g++` |
| **LLVM IR** | Universal Language | GIMPLE |
| **LLD** | Linker | `ld` |
| **LLDB** | Debugger | `gdb` |
| **Libc++** | Standard Library | `libstdc++` |

---

## Why is this better than old compilers?

Before LLVM, if you wanted to invent a new language (like **Mojo** or **Rust**), you had to write a compiler 
from scratch for every single CPU on earth (Intel, AMD, ARM, PowerPC). 

With the LLVM package, you only have to write a "Front-end" that translates your language into **LLVM IR**. 
Once you do that, LLVM’s existing "Back-ends" handle the rest of the work to make it run on every device.


## Crazy Idea: Build custom eBPF own language:

Building a custom language for eBPF: i.e: A DSL ( Domain Specific Language ) for `eBPF` that targets the
"Compile Once - Run Everywhere" (CO-RE) ecosystem. 

This allows to focusing on the bytecode generation and leaving the "loader" ( the user-space part) to
exisiting libraries like `libbpf` (C), `aya` (Rust), or `cilium/ebpf` (Go) you avoid reinventing the wheel
while solving the harder part: **write safe kernel code**.

To make this work with CO-RE, the proposed language doesn't just need to output eBPF bytecode; it needs to 
output a very specific type of **ELF object File**.

### 3 components the Language needs for CO-RE:

To ensure the proposed language output is compatible with loaders in other languages, your compiler must
generate three things inside it ELF output. 

#### 

### 3 components the Language needs for CO-RE:

To ensure the proposed language output is compatible with loaders in other languages, your compiler must
generate three things inside it ELF output. 

#### 1. eBPF Instruction Set ( The Code ): 

The compiler must translate the proposed high-level syntax into eBPF-specific assembly. This is where LLVM
helps to act as a front-end generate **LLVM IR**, and then let the **LLVM eBPF Backend** handle the actual
bytecode generation. 

#### 2. BTF (BPF Type Format) 

This is the magic sauce of CO-RE.

- A compact metadata format embedded in the ELF file that describes the data structures your program uses. 

- If the proposed language accesses a kernel struct ( like `task_struct`), it won't know the exact memory
  offset ( which changes between kernel versions ). This new compiler must record: " I am looking for the
  `pid` field in `task_struct`.

#### 3. Relocation Records ( `.BTF.ext` ):

CO-RE works by "relocating" offsets at load-time. The proposed compiler needs to create a section in the ELF
file called `.BTF.ext`.

- When a loader (like a Python or Go script) opens your file, it sees these records.
- The loader looks at the current kernel's types, finds the actual offset of `pid`, and "patches" the
  bytecode before pushing it into the kernel.

### Proposed Workflow: 

A possible build flow can look as below:
1. Write: `program.newlang` 

2. COmpile: `new-compiler program.newland -o program.o`

    - your compiler embeds the instructions + BTF + Relocations. 

3. Load: Use any language to load `.o` file. 
    - Go: `ebpf.LoadCollectionSpec("program.o")`
    - Python: `b = BPF(src_file="program.o")`
    - Rust: `Bpf::load_file("program.o)`


### Advantage of this approach:

- No LLVM dependency at Runtime: Unlike BCC which required the entire LLVM/Clang toolchain to be installed
  on the target server, this approach allows to compile on a dev machine and ship a tiny binary.

- Type Safety: The proposed language can be made to strict typed (like OCaml or Rust) to prevent common 
  eBPF verifier errors before the user even tries to load the code. 

A Possible Potential Challenge: `vmlinux.h`
One of the biggest pain points in eBPF is needing the massive `vmlinux.h` file (which contains all kernel 
types). If the proposed language can "auto-import" these types or provide a cleaner way to reference kernel 
structures, it would be a huge productivity win for developers.



