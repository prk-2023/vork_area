# Rust Pattern Matching and Destructuring:
---

Let’s dive deep into *Rust Pattern Matching and Destructuring* with clear explanations and practical
examples.


##  What is Pattern Matching?

Pattern matching in Rust allows you to destructure data types like tuples, enums, structs, and references 
and execute code based on the shape or value of the data.

Rust offers:

* `match`: full pattern matching with multiple arms.
* `if let`: shorthand for matching one specific pattern.
* `while let`: loop that continues as long as a pattern matches.
* `let` with destructuring: assigning and unpacking data.
* Function parameters and `for` loops also support destructuring.

---

## `match` – Full Pattern Matching

```rust
fn main() {
    let number = 7;

    match number {
        1 => println!("One!"),
        2 | 3 | 5 | 7 | 11 => println!("This is a prime number!"),
        13..=19 => println!("A teen prime?"),
        _ => println!("Not a number I care about."),
    }
}
```

* `|` for OR patterns
* `13..=19` is a range
* `_` is a catch-all wildcard

---

## 🎯 Destructuring with `match`

### Tuple:

```rust
fn main() {
    let pair = (0, -2);

    match pair {
        (0, y) => println!("First is 0, y = {}", y),
        (x, 0) => println!("y is 0, x = {}", x),
        _ => println!("No zeros"),
    }
}
```

### Struct:

```rust
struct Point { x: i32, y: i32 }

fn main() {
    let p = Point { x: 0, y: 7 };

    match p {
        Point { x: 0, y } => println!("On Y axis at {}", y),
        Point { x, y: 0 } => println!("On X axis at {}", x),
        Point { x, y } => println!("Point at ({}, {})", x, y),
    }
}
```

### Enum:

```rust
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
}

fn main() {
    let msg = Message::Move { x: 10, y: 20 };

    match msg {
        Message::Quit => println!("Quit"),
        Message::Move { x, y } => println!("Move to ({}, {})", x, y),
        Message::Write(s) => println!("Text: {}", s),
    }
}
```

---

## 👌 `if let` – Syntactic Sugar

Good for matching **one case** out of many:

```rust
let some_value = Some(5);

if let Some(x) = some_value {
    println!("Got: {}", x);
} else {
    println!("None");
}
```

Equivalent to:

```rust
match some_value {
    Some(x) => println!("Got: {}", x),
    _ => println!("None"),
}
```

---

## 🔁 `while let` – Pattern Matching in Loops

```rust
let mut stack = vec![1, 2, 3];

while let Some(top) = stack.pop() {
    println!("Popped: {}", top);
}
```

---

## 💡 Destructuring with `let`

You can destructure directly in `let` bindings:

```rust
let (a, b) = (1, 2);
println!("a = {}, b = {}", a, b);
```

Nested example:

```rust
let ((x1, y1), (x2, y2)) = ((0, 1), (2, 3));
println!("({}, {}) to ({}, {})", x1, y1, x2, y2);
```

---

## 🧪 Match Guards

Add an extra condition:

    Some(n) => println!("Big number: {}", n),
    None => (),
```rust
let x = Some(4);

match x {
    Some(n) if n < 5 => println!("Small number"),
    Some(n) => println!("Big number: {}", n),
    None => (),
}
```

---

## 🔂 Matching by Reference

```rust
let name = String::from("Rust");

match &name {
    r if r == "Rust" => println!("Found Rust"),
    _ => println!("Something else"),
}

println!("Still owns: {}", name);
```

---

## 🎯 Advanced Patterns

### Ignoring values:

```rust
let (x, _) = (5, 10); // Ignore second value
```

### Nested Enums:

```rust
enum Color {
    Rgb(u8, u8, u8),
    Cmyk { c: u8, m: u8, y: u8, k: u8 },
}

let color = Color::Cmyk { c: 0, m: 128, y: 255, k: 0 };

match color {
    Color::Rgb(r, g, b) => println!("rgb({}, {}, {})", r, g, b),
    Color::Cmyk { c, .. } => println!("C component: {}", c),
}
```

---

## 🧠 Summary

| Feature           | Use Case                             |
| ----------------- | ------------------------------------ |
| `match`           | Full matching with multiple branches |
| `if let`          | Match one case cleanly               |
| `while let`       | Loop while pattern matches           |
| `let` destructure | Unpack tuples, structs, etc.         |
| Guards (`if`)     | Add conditions to patterns           |
| Nested patterns   | Match complex data structures        |

---

# Learning module :

Here’s a complete **hands-on learning module** on Pattern Matching and Destructuring in Rust.

---

#📁 Folder Structure

```
pattern_matching_rust/
├── 01_match_basic.rs
├── 02_match_tuples.rs
├── 03_match_structs.rs
├── 04_match_enums.rs
├── 05_if_let.rs
├── 06_while_let.rs
├── 07_let_destructuring.rs
├── 08_match_guards.rs
├── 09_match_refs.rs
├── 10_nested_patterns.rs
└── README.md
```

---

## 📝 `README.md` Overview

````md
# Rust Pattern Matching and Destructuring

This module contains guided examples to help you master Rust's pattern matching system using `match`, `if let`, `while let`, and destructuring techniques with tuples, structs, enums, and more.

Each file demonstrates one specific feature with clear output and suggestions for experimentation.

To run:
```bash
rustc <filename.rs> && ./<filename>
````

Happy coding! 🦀

````

---

### ✅ `01_match_basic.rs`

```rust
fn main() {
    let num = 3;

    match num {
        1 => println!("One"),
        2 | 3 | 5 => println!("Prime"),
        4..=10 => println!("Between 4 and 10"),
        _ => println!("Something else"),
    }
}
````

---

### 🔢 `02_match_tuples.rs`

```rust
fn main() {
    let pair = (0, -2);

    match pair {
        (0, y) => println!("First is zero, y = {}", y),
        (x, 0) => println!("Second is zero, x = {}", x),
        _ => println!("No zeroes"),
    }
}
```

---

### 📦 `03_match_structs.rs`

```rust
struct Point {
    x: i32,
    y: i32,
}

fn main() {
    let p = Point { x: 5, y: 0 };

    match p {
        Point { x: 0, y } => println!("On Y axis at {}", y),
        Point { x, y: 0 } => println!("On X axis at {}", x),
        Point { x, y } => println!("Point at ({}, {})", x, y),
    }
}
```

---

### 🎭 `04_match_enums.rs`

```rust
enum Message {
    Quit,
    Write(String),
    Move { x: i32, y: i32 },
}

fn main() {
    let msg = Message::Move { x: 10, y: 20 };

    match msg {
        Message::Quit => println!("Quit!"),
        Message::Write(text) => println!("Text: {}", text),
        Message::Move { x, y } => println!("Move to ({}, {})", x, y),
    }
}
```

---

### 🔀 `05_if_let.rs`

```rust
fn main() {
    let name = Some("Rust");

    if let Some("Rust") = name {
        println!("Hello Rustacean!");
    } else {
        println!("Not Rust.");
    }
}
```

---

### 🔄 `06_while_let.rs`

```rust
fn main() {
    let mut stack = vec![1, 2, 3];

    while let Some(top) = stack.pop() {
        println!("Top: {}", top);
    }
}
```

---

### 📦 `07_let_destructuring.rs`

```rust
fn main() {
    let (a, b) = (100, 200);
    println!("a = {}, b = {}", a, b);

    let ((x1, y1), (x2, y2)) = ((1, 2), (3, 4));
    println!("({}, {}) to ({}, {})", x1, y1, x2, y2);
}
```

---

### 🛡️ `08_match_guards.rs`

```rust
fn main() {
    let num = Some(4);

    match num {
        Some(n) if n < 5 => println!("Small number"),
        Some(n) => println!("Number: {}", n),
        None => println!("Nothing"),
    }
}
```

---

### 🔗 `09_match_refs.rs`

```rust
fn main() {
    let val = String::from("Rust");

    match &val {
        s if *s == "Rust" => println!("Matched Rust!"),
        _ => println!("No match."),
    }

    println!("Ownership retained: {}", val);
}
```

---

### 🧩 `10_nested_patterns.rs`

```rust
enum Color {
    Rgb(u8, u8, u8),
    Cmyk { c: u8, m: u8, y: u8, k: u8 },
}

fn main() {
    let color = Color::Cmyk { c: 0, m: 128, y: 255, k: 0 };

    match color {
        Color::Rgb(0, g, b) => println!("Green-Blue tint: g={}, b={}", g, b),
        Color::Cmyk { c: 0, .. } => println!("No cyan!"),
        _ => println!("Some color"),
    }
}
```

---

