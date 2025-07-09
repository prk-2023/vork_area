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

