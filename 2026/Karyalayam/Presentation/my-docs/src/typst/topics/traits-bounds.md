# Trait Bounds in Rust

---

# 1. Why Trait Bounds Exist

Generics alone say:

```text 
"T can be ANY type"
```

Example:

```rust 
fn identity<T>(x: T) -> T {
    x
}
```

This works because the function does nothing special with `T`.

---

But now consider:

```rust 
fn print_value<T>(x: T) {
    println!("{}", x);
}
```

Rust rejects this.

Why?

Because:

```text 
Not every type can be printed with {}
```

Rust needs proof that `T` supports printing.

That proof is called a:

```text 
Trait Bound
```

---

# 2. What Is a Trait Bound?

A trait bound restricts a generic type.

It says:

```text 
"T must implement this trait"
```

---

# 3. Basic Syntax

```rust 
fn function<T: TraitName>(x: T) {
}
```

Read as:

```text 
"T implements TraitName"
```

---

# 4. First Real Example

```rust 
use std::fmt::Display;

fn print_value<T: Display>(x: T) {
    println!("{}", x);
}
```

Now Rust knows:

* `T` supports formatting with `{}`

---

# 5. Mental Model

```text 
Generics define flexibility.
Trait bounds define required abilities.
```

---

# 6. Another Example — Addition

This fails:

```rust 
fn add<T>(a: T, b: T) -> T {
    a + b
}
```

Error:

```text 
cannot add T to T
```

Because:

* Rust does not assume `T` supports `+`

---

# Solution

```rust 
use std::ops::Add;

fn add<T: Add<Output = T>>(a: T, b: T) -> T {
    a + b
}
```

Now Rust knows:

* `T` implements `Add`
* result type is also `T`

---

# 7. Common Trait Bounds

| Trait       | Capability            |
| ----------- | --------------------- |
| `Debug`     | printable with `{:?}` |
| `Display`   | printable with `{}`   |
| `Clone`     | clonable              |
| `Copy`      | copyable              |
| `PartialEq` | comparable with `==`  |
| `Ord`       | sortable              |
| `Iterator`  | iterable              |

---

# 8. Multiple Trait Bounds

You can require several traits.

---

## Syntax

```rust 
fn f<T: Debug + Clone>(x: T)
```

Meaning:

```text 
T must implement BOTH Debug and Clone
```

---

# Example

```rust 
use std::fmt::Debug;

fn duplicate_and_print<T: Debug + Clone>(x: T) {
    let y = x.clone();

    println!("{:?}", y);
}
```

---

# 9. `where` Clauses

Complex bounds become ugly inline.

---

## Hard to read

```rust 
fn process<T: Clone + Debug + PartialEq>(x: T)
```

---

## Cleaner

```rust 
fn process<T>(x: T)
where
    T: Clone + Debug + PartialEq,
{
}
```

This is heavily used in real Rust code.

---

# 10. Trait Bounds on Structs

Structs can require traits too.

---

## Example

```rust 
use std::fmt::Debug;

struct Container<T: Debug> {
    value: T,
}
```

Now:

* `T` must implement `Debug`

---

# 11. Trait Bounds in `impl`

Example:

```rust 
struct Point<T> {
    x: T,
    y: T,
}
```

---

## Restrict methods

```rust 
impl<T: Display> Point<T> {
    fn print(&self) {
        println!("({}, {})", self.x, self.y);
    }
}
```

Only types implementing `Display` get this method.

---

# 12. `impl Trait`

Rust provides shorthand syntax.

---

## Traditional

```rust 
fn print<T: Display>(x: T)
```

---

## Modern shorthand

```rust 
fn print(x: impl Display)
```

Meaning is almost the same.

---

# 13. Why `impl Trait` Is Nice

Cleaner and easier for simple APIs.

Very common in modern Rust.

---

# 14. Trait Bounds and Polymorphism

Trait bounds enable:

```text 
compile-time polymorphism
```

Meaning:

* one function
* many types
* statically checked

---

# 15. Static Dispatch (Important)

Rust generics usually use:

```text 
Static Dispatch
```

The compiler generates specialized code.

Example:

```rust 
fn print<T: Display>(x: T)
```

becomes internally:

```rust 
print_i32(...)
print_string(...)
```

This is:

* fast
* optimized
* zero-cost

---

# 16. Dynamic Dispatch and `dyn Trait`

Sometimes you want:

```text 
different concrete types handled uniformly at runtime
```

Example:

```rust 
trait Animal {
    fn speak(&self);
}
```

---

## Dynamic trait object

```rust 
fn make_speak(animal: &dyn Animal) {
    animal.speak();
}
```

Now:

* exact type is decided at runtime

---

# 17. Static vs Dynamic Dispatch

| Feature                            | Static Dispatch | Dynamic Dispatch |
| ---------------------------------- | --------------- | ---------------- |
| Uses Generics                      | Yes             | No               |
| Uses `dyn Trait`                   | No              | Yes              |
| Runtime overhead                   | None            | Small            |
| Compile-time specialization        | Yes             | No               |
| Flexible heterogeneous collections | Harder          | Easier           |

---

# 18. Trait Objects

Example:

```rust 
let animals: Vec<Box<dyn Animal>>;
```

This allows:

* `Dog`
* `Cat`
* `Bird`

inside ONE vector.

Without trait objects:

* impossible directly

because vectors need one concrete type.

---

# 19. Object Safety

Not all traits can become `dyn Trait`.

Traits with:

* generic methods
* returning `Self`
* some associated types

may not be object-safe.

This is an advanced topic but important later.

---

# 20. Trait Bounds + Marker Traits

Remember:

```text 
Traits are not only about methods
```

You can bound using marker traits too.

Example:

```rust 
fn send_to_thread<T: Send>(x: T)
```

Meaning:

```text 
T must be safe to move across threads
```

---

# 21. Real-world Examples

---

## Sorting

```rust 
fn sort<T: Ord>(values: &mut Vec<T>)
```

Requires:

* comparability

---

## Cloning

```rust 
fn duplicate<T: Clone>(x: T) -> (T, T)
```

---

## Threading

```rust 
thread::spawn(move || {})
```

requires:

* `Send`

---

# 22. Important Beginner Insight

Trait bounds are where:

* traits
* generics
* type system

all connect together.

This is one of Rust’s most central ideas.

---

# 23. Big Mental Model

```text 
Generics = flexibility
Traits = capabilities
Trait Bounds = required capabilities
```

---

# 24. Common Beginner Confusion

---

## “Why doesn’t Rust assume `+` exists?”

Because Rust prefers:

* explicit guarantees
* compile-time correctness

Not all types support:

* addition
* cloning
* printing
* comparison

Rust forces you to state requirements clearly.

---

# 25. Final Memory Shortcut

```text 
Trait bounds say:

"This generic type must support these abilities."
```

Examples:

```rust 
T: Clone
T: Debug
T: Send
T: Iterator
```

---

Next topic:

```text
Lifetimes
```

This is where Rust’s ownership model becomes fully powerful.

It explains:

* why references are safe
* borrowing duration
* dangling pointer prevention
* `'a`
* lifetime elision
* borrow checker reasoning
* why Rust has no garbage collector yet stays memory-safe
