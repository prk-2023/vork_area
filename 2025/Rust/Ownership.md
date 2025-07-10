# Ownership:


Rust’s ownership model is one of the most unique and powerful features of the language. 
It allows Rust to manage mem safety and prevent issues like data races without needing a garbage collector. 

Here’s an overview of *ownership* and how it works in Rust:

### Key Concepts of Ownership:

1. *Ownership*: Every value in Rust has a single "owner" (a variable), and this owner is responsible for
   cleaning up the value when it is no longer needed.

2. *Borrowing*: You can create references to a value without taking ownership of it.

3. *Lifetimes*: These are used to ensure that references are always valid while they're in use.

### Ownership Rules:

1. *Each value in Rust has a variable that is its owner.*
2. *There can only be one owner at a time.*
3. *When the owner goes out of scope, the value is dropped.*

### Example 1: Basic Ownership

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

### Example 2: Borrowing (References)

Rust allows *borrowing*, where you can create references to data without taking ownership.

* *Immutable Borrowing*: Multiple immutable references (`&`) can exist at the same time, but you cannot
  modify the data through them.
* *Mutable Borrowing*: Only one mutable reference (`&mut`) is allowed at a time, ensuring exclusive access
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

### Example 3: Mutable Borrowing

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

### Example 4: Ownership and Functions

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

### Example 5: Returning Ownership

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

### Example 6: Borrowing and Returning References

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

---

### Summary:

* **Ownership** ensures that Rust automatically handles memory safety without a garbage collector.

* Ownership can be **moved** or **borrowed**.

  * When ownership is moved, the original variable is no longer valid.
  * When borrowing, references to the value can be used without transferring ownership.

* **Lifetimes** ensure that references are valid for as long as the data they refer to is valid.

-----------------------------------------------------------------------------------------------------------
# Mastering Ownership:


Mastering **ownership** in Rust is essential because it's the foundation of Rust's memory safety guarantees. 

Below is a set of *progressive exercises* and *Rust programs* to help you fully understand how ownership, 
borrowing, and lifetimes work.

---

## 🧠 What You’ll Learn

* Ownership rules
* Move semantics
* Borrowing (immutable and mutable)
* References and the borrow checker
* Slices and ownership
* Lifetimes (introductory)

---

## 🛠️ Getting Started

Install Rust and set the PATH

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

To compile:

```bash
rustc your_file.rs && ./your_file
```
---

## 🧪 Basic Ownership Exercises

### 🔹 1. Move Semantics

*Exercise:* What happens when you try to use a value after it's been moved?

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1;

    println!("{}", s1); // Fix this line
}
```

*Goal:* Understand that `s1` is moved into `s2`, so `s1` is no longer valid.

✅ *Fix: Clone the string.*

---

### 🔹 2. Function Ownership

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

✅ *Fix: Return ownership or use references.*

---

## 🔄 Intermediate Borrowing Exercises

### 🔹 3. Borrowing

**Exercise:** Use references instead of moving ownership.

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

**Challenge:** Make `calculate_length` take a reference.

---

### 🔹 4. Mutable Borrowing

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

**Challenge:** Why do you need `mut` in both `let mut s` and `&mut s`?

---

## 🔥 Advanced Exercises

### 🔹 5. Borrow Checker Conflict

```rust
fn main() {
    let mut s = String::from("hello");

    let r1 = &s;
    let r2 = &mut s;

    println!("{}, {}", r1, r2); // Fix this
}
```

**Goal:** Understand you can't have mutable and immutable references at the same time.

---

### 🔹 6. Dangling Reference Prevention

```rust
fn dangle() -> &String {
    let s = String::from("hello");
    &s // This won't compile — why?
}

fn main() {
    let r = dangle();
}
```

✅ *Fix: Return `String`, not a reference.*

---

### 🔹 7. Ownership with Structs

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
}
```

✅ *Fix: Use references or clone.*

---

### 🔹 8. Lifetimes (Intro)

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

✅ *Try removing lifetimes and observe compiler errors.*

---

## 🧱 Bonus Challenges

### 🔹 9. Build a Mini Text Editor

* Accept user input line by line
* Store in a `Vec<String>`
* Print contents at the end
* Practice borrowing and cloning strings

---

### 🔹 10. Implement a Safe Stack

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

✅ *Emphasize ownership in `push`/`pop`, borrowing in `peek`*

---

## ✅ Tips

* Use `cargo check` frequently
* Experiment with the compiler — it gives great hints!
* Clone only when necessary
* Think in terms of *who owns what and when*

---

Would you like this as a downloadable `.zip` or Rust Playground links for interactive use?
