# Why Rust

- Rust and its features:
    - Not an Object-oriented nor functional programming language.
    - Does not feature classes and does not directly support Object-oriented patters.
    - Can operate with functions as first-class values, but this ability is limited compared to full blown
      functional language(like Haskell or OCaml )

- Writing Code with Functions, values and Types:

Programs in Rust are:
    - Rust program is a collections of functions combined in modules.
    - Functions in programs manipulate values.
    - Values are statically typed, i.e every value or expression should have an assigned type at compile time. 
    - Rust provides both primitive and compound types (arrays and structs).
    - Standard library also provides many additional types for collections of values.
    - Supports generic types, which makes it possible to avoid mentioning specific types and provide more
      general definitions. 
    - Provides traits as collections of methods (i.e. functions) that can be implemented for specific
      types. Traits allow Rust to achieve the same levels of SW abstraction as object-oriented languages 
      that support inheritance and polymorphism.

- Memory Management:

Rust’s approach to memory management is based on the following principle: 
    - The Rust compiler must know the precise locations in the code where memory is allocated, where and how
      it's accessed, and where it’s no longer needed. This knowledge allows for controlling memory access
      and freeing allocated memory automatically by inserting the corresponding instructions directly into 
      the generated code, thus avoiding many common pitfalls other languages might be susceptible to. 
 
      This approach differs from automatic memory management (as in JavaScript, Python, Java, or C#), where 
      memory fragments that are no longer needed are detected at runtime and garbage is collected. 
 
      As a result, Rust saves the time required to execute the corresponding algorithms at runtime and 
      achieves both memory safety and performance.
 
    - To be able to infer knowledge about memory access, Rust sets limits on what can be done with memory
      and defines strict rules that ensure correctness:
 
      1. Every memory fragment must be owned by a single variable – Rust’s ownership model is based on this.
      2. Mutating a memory fragment requires exclusive access (as opposed to just reading the memory).
      3. Rust allows creating mutable and immutable references to memory fragments (borrowing them) but uses
         a borrow checker to enforce correctness (for example, prohibiting more than one mutable reference).
      4. The Rust compiler computes and checks lifetimes for every variable in a program from the place it's
         created to the place it’s dropped (where it becomes no longer accessible).

Compiler:
    The compiler’s requirements can be too strict. 
    A common frustration, especially when learning the language: 
    - The Rust compiler may fail to accept a logically correct code fragment.

To make these concepts a little easier to catch, let’s discuss Rust’s equivalent of the following 
Python program:

```python 
def print_list(numbers):
   for number in numbers:
       print(str(number) + " ", end="")
   print()


def add_one(numbers):
   numbers.append(1)


def main():
   numbers = [1, 1, 1]
   print_list(numbers)
   add_one(numbers)
   print_list(numbers)


if __name__ == '__main__':
   main()
```

So, we have a memory fragment (Python’s list) with three elements. 
We print it, add one more element, and print it again. 
We never mention any type here. 
Python doesn’t need any sign of memory management in the program, although the memory must be allocated 
and freed at some point.

Moreover, we pass around the numbers list easily without thinking about memory access control.

The same code in Rust is different, not only in syntax but in the whole approach to types and memory management:

```rust 
// Here we take a vector by reference (&).
// We are not allowed to mutate elements.
// We don't take ownership; we just borrow.
fn print_vec(numbers: &Vec<i32>) {
   for number in numbers {
       print!("{} ", number);
   }
   println!()
}
// Here we take a vector by mutable reference (&mut).
// We are now allowed to mutate elements and the vector itself.
// We still don't take ownership; we just borrow.
fn add_one(numbers: &mut Vec<i32>) {
   numbers.push(1)
}


fn main() {
   let mut numbers = vec![1,1,1];
   // We pass a reference
   print_vec(&numbers);
   // We pass a mutable reference
   add_one(&mut numbers);
   // We pass a reference again
   print_vec(&numbers);
}
```

We can now explore these two code fragments and find similarities and differences between them by yourself. 
Even without understanding Rust, you might get a general feeling for it just by looking at this code.

Despite passing references around, the numbers variable still owns the allocated memory. 
Rust defaults to read-only memory access, requiring explicit specification for write access. 
Rust also ensures the memory is freed after the last usage in the second call to print_vec.


Here’s a variation of the add_one function that takes over ownership of a vector and renders the whole 
program incorrect:

```rust 
    fn add_one_incorrectly(mut numbers: Vec<i32>) {
        numbers.push(1);
    }
```
Issue here: After calling the add_one_incorrect function, the numbers variable no longer owns the memory; 
its lifetime has ended, so we can’t print anything.

IDE LSP (using rust-analyzer) will show error : Value used after being moved [E0382]

Before introducing the incorrect version, Rust's borrow checker could ensure that passing references didn't
bring any problem. After introducing an error, it's no longer feasible. 

The language behaviour here exemplifies how memory access is under strict control.

- Concurrency:
It's the ability of a system to execute multiple tasks or processes simultaneously or in overlapping periods
to improve efficiency and performance. 
This can involve parallel execution on multiple processors or interleaved execution on a single processor, 
allowing a system to handle multiple operations simultaneously and manage multiple tasks more effectively.

Rustaceans often describe Rust’s concurrency as fearless. Several factors contribute to this perception 
    1. The ownership model adds more control over sharing data between concurrent threads.
    2. Embracing immutable data structures simplifies the implementation of concurrent algorithms and
       contributes to thread safety.
    3. Message passing via channels adopted in Rust dramatically reduces the complexities of shared-state
       concurrency.
    4. Rust’s approach to lifetimes and memory management generally makes code that works with concurrency 
       primitives such as locks, semaphores, or barriers more elegant and safe.
    5. In many cases, Rust’s approach to asynchronous programming makes it possible to avoid using complex
       concurrency patterns and enables you to write concise and clear code.

Although concurrency is not the first thing beginners learn when approaching Rust, it is still easier to 
grasp than in many other programming languages. 

More importantly, Rust helps you write less error-prone concurrent code.


- How to get started with Rust:

Two things that need to be installed on your computer to get started with Rust:

1. Rust toolchain – a collection of tools that includes the Rust compiler and other utilities.
   A code editor or IDE (integrated development environment). 
   Install via rustup.rs the official way  to install depend on OS.
2. This requires making a choices. 
    IDE code editor configured to provide Rust support (for example, VSCode supports Rust but requires some
    setup) or using a dedicated Rust IDE (such as RustRover, a JetBrains IDE, which is free for anyone 
    learning Rust, or use neovim with rust nvim plugins)

Rust projects rely on Cargo, package manager. 
In Rust, packages are called crates. <== 
The dependencies are specified in the Cargo.toml file, for example:
```toml 
    [package]
    name = "hello"
    version = "0.1.0"
    edition = "2021"

    [dependencies]
    chrono = "0.4.38"
```

After adding the chrono crate to dependencies, we can use the functionality it provides in our code, 
for example:

```rust 
use chrono::{DateTime, Local};

fn main() {
   println!("Hello, world!");
   let local: DateTime<Local> = Local::now();
   println!("Today is {}", local.format("%A"));
}
```

- Common challenges and how to overcome them:

1. Understand the ownership model. 
    Rust’s ownership model, which includes concepts like ownership, borrowing, and lifetimes, is often the 
    most challenging aspect for beginners. 
    Start with small examples and practice frequently. 
    Focus on understanding why Rust enforces these rules rather than how to get around compiler errors. 

2. Borrow Checker: 
    The borrow checker can be frustrating, as it’s strict and may lead to confusing compiler errors. 
    When you encounter borrow checker issues, take a step back and analyze what Rust is trying to prevent. 
    Experiment with approaches like referencing or cloning data (but try not to clone everything!). 
    It’s really useful to understand what precisely a borrow checker is. 
    See, for example, this great explanation by Nell Shamrell-Harrington.[https://www.youtube.com/watch?v=HG1fppexRMA]

3. Documentation:
    Rust is a relatively new language, so some things might not be as straightforward as in more established
    languages. Use the Rust documentation, which is known for being comprehensive and well-written. 
    The Rust community also contributes to great resources like the Rust by Example guide.

4. Start with simple projects. 
    Rust’s complexity can make even simple projects feel overwhelming at first. Start by implementing basic 
    programs and gradually move to more complex ones. 
    Examples of simple projects include building a command-line tool with clap, writing simple file parsers, 
    or creating a basic web server using a framework like Rocket.

5. IDE 
    Writing Rust code manually can be error-prone. Tools can help you with code completion, linting, and 
    formatting.
    Interact with the Rust community and resources.

6. Learn from mistakes. Rust’s compiler is strict, and it can feel like you’re constantly fighting with it. 
   View each compiler error as a learning opportunity. 
   Rust’s error messages are often very descriptive and guide you toward the correct solution.
   Over time, you’ll find that these errors help you write better, safer code.

Rust’s features, like its memory safety guarantees and performance, make it a powerful language for systems 
programming, web development, and more. 
Stick with it; you’ll find that Rust can be fun and rewarding.

Integrating Rust with other programming languages:
    The PyO3 project enables developers to implement native Python modules in Rust and to access Python in 
    Rust binaries. 
    By leveraging PyO3, you can provide an extremely efficient Rust implementation of a Python library for 
    Python developers. 
    Rust and JavaScript can be connected similarly via WebAssembly and wasm-bindgen. 

- Systems and embedded programming in Rust:
    Rust shines in systems programming. Speakers from Google and Microsoft confirm that introducing Rust 
    into their codebases lessens the number of security vulnerabilities, increases performance, and also 
    keeps or sometimes improves the productivity of software developer teams. 
 
    Amazon not only supports Rust development on AWS but also uses it directly to implement their own 
    infrastructure. 
 
    Cloudflare, a company that builds content delivery networks and other networking infrastructure, relies 
    on Rust in a lot of low-level projects and contributes their frameworks to the Rust ecosystem.  
 
    Ferrous Systems, a company that backs the development of rust-analyzer, also develops Ferrocene, a 
    certified Rust toolchain for mission-critical applications. 
    Together with other developments, this enables Rust to be used in the automotive and aerospace industries. 
    For example, there are reports about Volvo and Renault using Rust for their in-vehicle software.

- roadmap.rs/rust 

Gives a clean and clear pathways to reach the desired area with rust.



