#let articleTitle = "Rust Ownership with examples"

#align(right)[
  #heading(articleTitle)
  #line(length: 50%, stroke:(paint: black))
]
#show outline.entry: it => link(
  it.element.location(),
  it.indented(it.prefix(), it.body()),
)
#set heading(numbering: "1.")
#outline()
#pagebreak()

= Rust Ownership:

What we cover here :

- Ownership rules
- Move semantics
- Borrowing (immutable and mutable)
- References and the borrow checker
- Slices and ownership
- Lifetimes (introductory)

#line(length: 100%, stroke:(paint: black))

== Ownership:
Rust's Ownership system is a set of rules that govern how memory is managed safely and efficiently without
using Garbage collector( which is commonly used in many languages ).

Rust's Ownership and borrowing system is designed to manage *heap-allocated* values safely without a garbage
collector.
In other words, Ownership and Borrowing are critical when dealing with heap allocated or large data types
and are less relevant for simple scalars.

Ownership helps prevent bugs like dangling pointers, data races, and memory leaks.

No garbage collector == faster execution and smaller binary foot print.

#table(columns: 2,
table.header[*Rule*][*Mostly Applies To* ],
[ Ownership (move, drop, clone)        ],[ Heap data types (`String`, `Vec`, etc.)     ],
[ Borrowing (immut. / mut. references) ],[ Heap values or large structs                ],
[ Stack types (`Copy`)                 ],[ Trivially copied; no ownership rules needed ])

Here’s an overview of *ownership* and how it works in Rust:

=== Key concepts:

=== Ownership Rules:

1. *Each value in Rust has a single owner* (a variable that owns the data).
2. When the owner goes out of scope, the value is automatically dropped (memory freed).
3. Ownership can be *transferred (moved)* but not copied unless the type implements `Copy`.
4. *Borrowing*: You can *borrow* data via references (`&` for immutable, `&mut` for mutable), but references
   must obey strict rules to prevent data races.
5. *Lifetime rules*: This is used to ensure that the references are always valid while they are in use.

=== Ownership Model

* *One owner per value:* Only one variable owns the data at a time.
* *Move semantics:* Ownership moves when assigned or passed.
* *Borrowing:* Temporary references that don’t take ownership.
* *Lifetime rules:* References must always be valid (no dangling references).

This model enforces *memory safety* and *thread safety* at compile time.

=== Ex 1: Basic Ownership

```rust
fn main() {
    let s1 = String::from("Hello, world!"); // s1 owns the string
    let s2 = s1; // ownership of s1 is moved to s2
    
    // println!("{}", s1); // This would cause an error because s1 no longer owns the string
    println!("{}", s2); // This is fine, since s2 owns the string now
}
```

*Explanation*: In this example, the string `s1` owns the data `"Hello, world!"`. 
When ownership is moved to `s2` (by assigning `s1` to `s2`), `s1` is no longer valid. 
Trying to use `s1` after it has been moved will result in a compile-time error.


=== Borrowing ( References ) (Memory View):

What happens *in memory* when you borrow in Rust.

When you *borrow* data in Rust, you create a *reference* to the original data without transferring 
ownership. 

This means:

- The *original data stays in the same memory location*.
- The *borrowed reference points directly to that memory location*.
- No new copy of the data is made in memory.
- The ownership remains with the original owner (the variable that owns the data).

Visualizing it by example:

```rust
let s = String::from("hello");  // s owns the string data in heap memory
let r = &s;                     // r borrows s (immutable reference)
```

- `s` owns a string stored on the *heap*.
- `s` is like a pointer to that heap memory.
- `r` is a *reference*, basically a pointer to the same heap memory where the string is stored.
- Both `s` and `r` refer to the *same memory*.
- The *ownership of the heap data remains with `s`*.
- `r` cannot modify the data because it’s an immutable borrow.
- The Rust compiler ensures `r` cannot outlive `s` (the data owner) so no dangling pointer happens.

==== Key points on memory with borrowing:

- *No new allocation or copy* occurs for the borrowed data.
- Borrowing is like creating a *pointer* to existing memory.
- The (at compilation)borrow checker ensures references are valid and respect aliasing/mutability rules.
- Once the borrow ends, the reference goes out of scope and is invalidated, but the original data remains
  intact.

=== Mutable Borrowing (Memory View)

```rust
let mut s = String::from("hello");  // s owns the data
let r = &mut s;                     // r mutably borrows s
```

- `s` owns the string data on the heap.
- `r` is a *mutable reference*, so it points to the same heap memory.
- Because `r` is mutable, you can modify the data through `r`.
- Rust's borrow checker enforces that *only one mutable reference exists at a time*.
  (no other borrows allowed).
- This prevents data races or simultaneous modification from multiple places.

*Memory-wise:*

- `r` is a pointer to the same heap location as `s`.
- No copy is made; both `s` and `r` point to the same memory.
- `s` cannot be used while `r` is active because ownership is temporarily "loaned out" mutably.

==== Example 2: Borrowing (References)

Rust allows *borrowing*, where you can create references to data without taking ownership.

- *Immutable Borrowing*: Multiple immutable references (`&`) can exist at the same time, but you cannot
  modify the data through them.
- *Mutable Borrowing*: Only one mutable reference (`&mut`) is allowed at a time, ensuring exclusive access
  to the data.

```rust
fn main() {
    let s = String::from("Hello, world!");
    
    let r1 = &s; // immutable borrow
    let r2 = &s; // another immutable borrow
    
    println!("{}", r1);
    println!("{}", r2);
    
    // let r3 = &mut s; // This would cause an error because we already have immutable references
}
```

*Explanation*: `r1` and `r2` are immutable references to `s`. 
You can have multiple immutable references at the same time, but if you tried to borrow `s` mutably (`r3`), 
it would cause a compile-time error because you cannot have mutable references alongside immutable ones.

=== Example 3: Mutable Borrowing

```rust
fn main() {
    let mut s = String::from("Hello");

    let r1 = &mut s; // mutable borrow
    r1.push_str(", world!");
    println!("{}", r1); // r1 can modify s

    // let r2 = &mut s; // This would cause an error because mutable references are exclusive
}
```

*Explanation*: You can only have one mutable reference at a time to a value. In this case, `r1` has
exclusive access to `s` and can modify it. 
If you tried to create a second mutable reference (`r2`), it would cause a compile-time error.

=== Example 4: Ownership and Functions

When you pass a variable to a func, ownership of the value is transferred unless you explicitly borrow it.

```rust
fn main() {

    let s = String::from("Hello");

    take_ownership(s); // Ownership is moved to the function

    // println!("{}", s); // This would cause an error because ownership of s was moved
}

fn take_ownership(some_string: String) {
    println!("{}", some_string);
}
```

*Explanation*: The ownership of `s` is moved into the `take_ownership` function. After the function call, 
`s` is no longer valid, so trying to use `s` after the ownership has been transferred will result in an error.

=== Example 5: Returning Ownership

A function can return ownership, allowing the caller to take back the ownership of the value.

```rust
fn main() {
    let s1 = String::from("Hello");
    let s2 = give_ownership(s1); // Ownership is moved back to s2

    println!("{}", s2); // s2 now owns the string again
}

fn give_ownership(some_string: String) -> String {
    some_string // Ownership is returned
}
```

*Explanation*: The `give_ownership` function takes ownership of the value and then returns it, transferring 
the ownership back to the caller (`s2`).

=== Example 6: Borrowing and Returning References

You can also borrow references to a value and return them, but Rust ensures that the reference is valid by
tracking lifetimes.

```rust
fn main() {

    let s1 = String::from("Hello");
    let r = borrow_string(&s1); // Borrowing a reference
    println!("{}", r); // Using the borrowed reference
}

fn borrow_string(s: &String) -> &String {
    s // Return the reference to the original string
}
```

*Explanation*: `borrow_string` borrows a reference to the string, and it can return that reference because 
it doesn’t take ownership. The reference is still valid in `main` because `s1` exists as long as the scope 
of the main function.

Summary:

- *Ownership* ensures that Rust automatically handles memory safety without a garbage collector.
- Ownership can be *moved* or *borrowed*.
  - When ownership is moved, the original variable is no longer valid.
  - When borrowing, references to the value can be used without transferring ownership.
- *Lifetimes* ensure that references are valid for as long as the data they refer to is valid.

-----------------------------------------------------------------------------------------------------------

== Mastering Ownership:

Mastering *ownership* in Rust is essential because it's the foundation of Rust's memory safety guarantees. 

Below is a set of *progressive exercises* and *Rust programs* to help you fully understand how ownership, 
borrowing, and lifetimes work.


What You’ll Learn

- Ownership rules
- Move semantics
- Borrowing (immutable and mutable)
- References and the borrow checker
- Slices and ownership
- Lifetimes (introductory)


== Basic Ownership Exercises

=== 1. Move Semantics

*Exercise:* What happens when you try to use a value after it's been moved?

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1;

    println!("{}", s1); // Fix this line
}
```

*Goal:* Understand that `s1` is moved into `s2`, so `s1` is no longer valid.

 *Fix: Clone the string.*

=== 2. Function Ownership

*Exercise:* Pass a `String` to a function and try to use it afterward.

```rust
fn take_ownership(s: String) {
    println!("Got: {}", s);
}

fn main() {
    let s = String::from("hello");
    take_ownership(s);

    println!("{}", s); // Fix this line
}
```

*Fix: Return ownership or use references.*


== Intermediate Borrowing Exercises

=== 3. Borrowing

*Exercise:* Use references instead of moving ownership.

```rust
fn calculate_length(s: &String) -> usize {
    s.len()
}

fn main() {
    let s = String::from("hello");
    let len = calculate_length(&s);

    println!("Length: {}", len);
    println!("String: {}", s); // Should still work
}
```

*Challenge:* Make `calculate_length` take a reference.


=== 4. Mutable Borrowing

```rust
fn change(some_string: &mut String) {
    some_string.push_str(", world");
}

fn main() {
    let mut s = String::from("hello");
    change(&mut s);

    println!("{}", s);
}
```

*Challenge:* Why do you need `mut` in both `let mut s` and `&mut s`?


== Advanced Exercises

=== 5. Borrow Checker Conflict

```rust
fn main() {
    let mut s = String::from("hello");

    let r1 = &s;
    let r2 = &mut s; // cannot borrow as mut as its already borrowed as immutable. 

    println!("{}, {}", r1, r2); // Fix this
}
```

*Goal:* Understand you can't have mutable and immutable references at the same time.


=== 6. Dangling Reference Prevention

```rust
fn dangle() -> &String {
    let s = String::from("hello");
    &s // This won't compile — why?
       //because s does not exist after its scope in dangle() {}
}

fn main() {
    let r = dangle();
}
```

*Fix: Return `String`, not a reference.*

==== 7. Ownership with Structs

```rust
struct Person {
    name: String,
}

fn main() {
    let p1 = Person {
        name: String::from("Alice"),
    };

    let p2 = p1;

    println!("{}", p1.name); // Fix this 
    // ownership already transferred 
    // replace println with p2.name
}
```

*Fix: Use references or clone.*

//---------------------------------------------------

== String Slices and Ownership: 

*Slices and Ownership* in Rust — a concept that connects ownership, borrowing, and safe memory access.


=== What is a Slice?

A *slice* is a *reference to a part of a collection*, like a portion of a `String` or an array.
Slices *do not own* the data — they *borrow* it.

There are two main types:

- `&[T]` — a slice of an array or vector
- `&str` — a string slice, a view into a `String`

=== How Slices Relate to Ownership

- A slice is *a reference*, not an owner — so it follows *borrowing rules*.
- You cannot have a mutable reference (or mutable slice) and other references at the same time.
- When you create a slice, you’re *borrowing* part of the data, *not copying* or *moving* it.

=== Memory View of a Slice

A slice is essentially a *pointer and a length*:

```text
[ptr, len] -> points to part of memory owned by something else
```

====  Example 1: String Slice

```rust
fn main() {
    let s = String::from("hello world");
    let hello = &s[0..5];   // slice of first part
    let world = &s[6..];    // slice of second part

    println!("{} {}", hello, world);
}
```

Here:

- `s` owns the full string.
- `hello` and `world` are `&str` slices — they *borrow* parts of `s`.
- No ownership is transferred.
- Slices are lightweight and fast because they just point to the existing memory.

==== Example 2: Array Slice

```rust
fn main() {
    let arr = [1, 2, 3, 4, 5];
    let part = &arr[1..4];  // slice of the middle

    println!("{:?}", part); // [2, 3, 4]
}
```

Here:

- `arr` owns the data.
- `part` is a `&[i32]` slice — again, it borrows, doesn’t own.
- Still follows borrowing rules — you can’t mutably borrow `arr` while `part` is active.


=== Ownership Rules Still Apply

```rust
fn main() {
    let mut s = String::from("hello");
    let slice = &s[0..2];  // Immutable borrow

    // s.push('!');        // ❌ Error: cannot mutate `s` while it's borrowed
    println!("{}", slice);
}
```

- Since `slice` is an immutable borrow of `s`, you can’t mutate `s` (like `push`) until the borrow ends.
- This avoids *use-after-free* or *invalid references* from mutation.

---

=== Mutable Slice

```rust
fn main() {
    let mut arr = [10, 20, 30];
    let slice = &mut arr[0..2];  // mutable slice

    slice[0] = 99;               // modify through the slice
    println!("{:?}", arr);       // [99, 20, 30]
}
```

- A *mutable slice* lets you safely modify part of a collection.
- Only one mutable reference is allowed at a time — the compiler enforces this.

#table(columns:3,
table.header[ *_Concept_* ][ *_Slice_* ][ *_Ownership_* ], 
[ What is it? ],[ A reference to part of data  ],[ Borrowed                               ],
[ Memory      ],[ Pointer + length             ],[ Shared or exclusive access only        ],
[ Ownership   ],[ Doesn’t own, just views data ],[ Ownership stays with original variable ],
[ Types       ],[ `&str`, `&[T]`, `&mut [T]`   ],[ Follows borrowing rules                ])

//---------------------------------------------------
=== Lifetimes (Memory Safety Over Time)

Rust uses *lifetimes* to ensure references never outlive the data they point to.

Example:

```rust
let r;
{
    let s = String::from("hello");
    r = &s;  // r borrows s here
}           // s goes out of scope and is dropped here
println!("{}", r);  // ERROR! r points to dropped memory
```

- Here `s` owns the data in a smaller scope.
- `r` borrows `s`, but then `s` goes out of scope and the memory is freed.
- The compiler uses lifetimes to detect this error and prevent compilation.
- *_Lifetimes_* are like labels for how long references are valid, checked at compile time.
- This prevents dangling pointers and use-after-free bugs.

#table(columns: 2,
table.header[ *Concept* ][ *Memory Effect* ],
[ Immutable borrow ],[ Reference points to same memory, no copy, no mutation allowed                             ], 
[ Mutable borrow   ],[ Reference points to same memory, exclusive access, mutation allowed                       ], 
[ Lifetimes        ],[ Compile-time check that reference's scope ≤ owner's scope, preventing dangling references ]) 

===  8. Lifetimes (Intro)

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

fn main() {
    let s1 = String::from("long string");
    let s2 = "short";

    let result = longest(&s1, &s2);
    println!("Longest: {}", result);
}
```

*Try removing lifetimes and observe compiler errors.*

== Bonus Challenges

=== 9. Build a Mini Text Editor

- Accept user input line by line
- Store in a `Vec<String>`
- Print contents at the end
- Practice borrowing and cloning strings

=== 10. Implement a Safe Stack

```rust
struct Stack<T> {
    items: Vec<T>,
}

impl<T> Stack<T> {
    fn new() -> Self { ... }
    fn push(&mut self, item: T) { ... }
    fn pop(&mut self) -> Option<T> { ... }
    fn peek(&self) -> Option<&T> { ... }
}
```

*Emphasize ownership in `push`/`pop`, borrowing in `peek`*

== Tips

- Use `cargo check` frequently
- Experiment with the compiler — it gives great hints!
- Clone only when necessary
- Think in terms of *who owns what and when*



```rust
use std::io::{self, Write};

fn main() {
    let mut lines: Vec<String> = Vec::new();

    println!("Mini Text Editor");
    println!("Type your text line by line. Type 'EXIT' to finish.\n");

    loop {
        print!("> ");
        // Flush stdout so the prompt appears immediately
        io::stdout().flush().unwrap();

        let mut input = String::new();
        // Borrow input line as mutable reference to be filled
        io::stdin()
            .read_line(&mut input)
            .expect("Failed to read line");

        // Remove trailing newline and carriage return
        let input = input.trim_end();

        if input == "EXIT" {
            break;
        }

        // Clone the string to store in Vec (ownership transferred)
        lines.push(input.to_string());
    }

    println!("\n--- Contents ---");
    for (i, line) in lines.iter().enumerate() {
        println!("{}: {}", i + 1, line);
    }
}

```
