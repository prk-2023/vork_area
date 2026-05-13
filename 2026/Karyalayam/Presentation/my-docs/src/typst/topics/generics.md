# Part 1 — Generics in Rust

---

# 1. What Are Generics?

Generics let you write code that works with **many types** instead of one specific type.

Without generics:

```rust
fn add_i32(a: i32, b: i32) -> i32 {
    a + b
}
```

This only works for `i32`.

You’d need another version for:

* `f64`
* `u64`
* `String`
* etc.

That becomes repetitive.

---

# 2. Generics Solve Repetition

Instead:

```rust 
fn identity<T>(x: T) -> T {
    x
}
```

This works for ANY type.

Example:

```rust 
identity(5);
identity("hello");
identity(true);
```

---

# 3. Mental Model

```text 
Generics = placeholders for types
```

`T` means:

```text 
"Some type chosen later"
```

---

# 4. Why Rust Uses Generics Everywhere

Rust heavily relies on generics because they provide:

* code reuse
* type safety
* zero runtime overhead

---

# 5. Generic Function Syntax

Basic syntax:

```rust 
fn function_name<T>(value: T) {
}
```

---

## Example

```rust 
fn print_value<T>(x: T) {
}
```

Here:

* `T` is a generic type parameter

---

# 6. Generic Structs

Structs can also be generic.

---

## Without Generics

```rust 
struct IntPoint {
    x: i32,
    y: i32,
}
```

Only works with integers.

---

## With Generics

```rust 
struct Point<T> {
    x: T,
    y: T,
}
```

Usage:

```rust 
let p1 = Point { x: 1, y: 2 };

let p2 = Point {
    x: 1.5,
    y: 3.7,
};
```

---

# 7. Multiple Generic Types

```rust 
struct Pair<T, U> {
    first: T,
    second: U,
}
```

Usage:

```rust 
let p = Pair {
    first: 5,
    second: "hello",
};
```

---

# 8. Generic Enums

Rust’s standard library uses generics extensively.

---

## `Option<T>`

```rust 
enum Option<T> {
    Some(T),
    None,
}
```

Examples:

```rust 
Option<i32>
Option<String>
Option<bool>
```

---

## `Result<T, E>`

```rust 
enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

This is one of Rust’s most important generic types.

---

# 9. Generic Methods

You can implement methods on generic structs.

```rust 
struct Point<T> {
    x: T,
    y: T,
}
```

```rust 
impl<T> Point<T> {
    fn x(&self) -> &T {
        &self.x
    }
}
```

---

# 10. Important Limitation

This does NOT work:

```rust 
fn add<T>(a: T, b: T) -> T {
    a + b
}
```

Why?

Rust says:

```text 
"I don't know whether T supports +"
```

This introduces the next topic:

* trait bounds

---

# 11. Generics + Traits

Generics alone only say:

```text 
"T can be any type"
```

But sometimes you need:

```text 
"T must support certain abilities"
```

Example:

* printing
* cloning
* adding
* comparison

That’s where trait bounds come in.

---

# 12. Monomorphization (VERY Important)

Rust generics have:

```text 
ZERO runtime cost
```

Rust does NOT use slow runtime polymorphism by default.

Instead, the compiler creates specialized versions.

---

## Example

```rust 
fn identity<T>(x: T) -> T {
    x
}
```

Rust internally generates something like:

```rust 
fn identity_i32(x: i32) -> i32
fn identity_str(x: &str) -> &str
```

This process is called:

```text 
Monomorphization
```

---

# 13. Why Generics Are Fast in Rust

Because the compiler generates real concrete code.

Benefits:

* no boxing
* no virtual dispatch
* no runtime type checks

You get:

* abstraction
* performance

simultaneously.

---

# 14. Generic Type Naming Conventions

Common names:

| Name | Meaning      |
| ---- | ------------ |
| `T`  | Type         |
| `E`  | Error        |
| `K`  | Key          |
| `V`  | Value        |
| `U`  | Another type |

---

# 15. Real-world Examples

Rust standard library uses generics everywhere.

---

## Vector

```rust 
Vec<T>
```

Examples:

```rust 
Vec<i32>
Vec<String>
```

---

## Option

```rust 
Option<T>
```

---

## Result

```rust 
Result<T, E>
```

---

# 16. Beginner Mental Model

Imagine:

```text 
Generics = templates for types
```

Like a reusable blueprint.

---

# 17. Common Beginner Confusion

---

## Generic ≠ Dynamic Typing

This:

```rust 
fn f<T>(x: T)
```

does NOT mean:

* weak typing
* runtime typing

Rust still knows exact types at compile time.

---

# 18. Big Picture

Generics are one of Rust’s foundational systems.

Traits + Generics together create:

* reusable APIs
* flexible libraries
* high-performance abstractions

Almost every advanced Rust feature builds on them.

---

# Final Memory Shortcut

```text 
Generics = write code once,
use it with many types safely and efficiently.
```

If you're ready, next topic is:

```text
Trait Bounds
```

which explains:

* how generics and traits connect
* why `T + T` fails without constraints
* `impl Trait`
* `where` clauses
* static vs dynamic dispatch
* `dyn Trait`
* trait objects
* polymorphism in Rust
