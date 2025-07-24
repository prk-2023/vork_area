# Constructs ( enums, trait, structs and implementation blocks)

Rust constructs  `enums`, `traits`, `structs`, and `impl` blocks are designed to help you *build an 
intuitive foundation* and understand *how these pieces work together* in idiomatic Rust.

---

## Why These Constructs Matter

Rust is a systems programming language that emphasizes *type safety, zero-cost abstractions, and memory 
safety without a garbage collector*. 
NOTE:
    Zero cost abstraction mean that using the abstraction imposes no additional runtime overhead. 
    High-level constructs (classes, wrapper functions, iterators, type templates, etc) will not incur any 
    runtime overhead as compared to its low-level implementation.
    
    Understanding Zero-Cost Abstraction: 
    It's a principle in Rust that encourages developers to write code that is both high-level and efficient.
    It means that abstractions should not impose any additional runtime costs, enabling developers to 
    express complex ideas without sacrificing performance. 
    Rust achieves this through a combination of compile-time guarantees and careful design choices.

    Reference: 
    https://ranveersequeira.medium.com/learning-rust-understanding-zero-cost-abstraction-with-filter-and-map-e967d09fff79

The constructs listed are central to modeling data and behavior in idiomatic Rust:

| Construct | Purpose                                                          |
| --------- | ---------------------------------------------------------------- |
| `struct`  | Define custom *data types* with named fields                     |
| `enum`    | Represent *one of several possible types/variants*               |
| `impl`    | Attach *methods* and associated functions to structs/enums       |
| `trait`   | Define *shared behavior* across multiple types (like interfaces) |

---

## 1. `struct` – Structured Data

`struct` defines a custom data structure with *named fields*. It's similar to a `class` without methods.

```rust
struct Point {
    x: f64,
    y: f64,
}
```

You can instantiate and access fields:

```rust
let p = Point { x: 1.0, y: 2.0 };
println!("({}, {})", p.x, p.y);
```

*Use `struct` when you need to bundle named data together.*

## 2. `enum` – Variants and Algebraic Data Types

`enum` defines a type that could be *one of many variants*, often with associated data.

```rust
enum Shape {
    Circle(f64),         // radius
    Rectangle(f64, f64), // width, height
}
```

Pattern matching makes enums powerful:

```rust
fn area(shape: Shape) -> f64 {
    match shape {
        Shape::Circle(r) => std::f64::consts::PI * r * r,
        Shape::Rectangle(w, h) => w * h,
        _ => println!("Undefined shape!!!"),
    }
}
```

- Use `enum` when you want *type-safe alternatives* (like unions or tagged unions).
---

## 3. `impl` – Methods and Associated Functions

The `impl` block allows you to attach *methods and constructors* to structs/enums:

```rust
impl Point {
    fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }

    fn magnitude(&self) -> f64 {
        (self.x.powi(2) + self.y.powi(2)).sqrt()
    }
}
```

```rust
let p = Point::new(3.0, 4.0);
println!("Magnitude: {}", p.magnitude());
```

-> *Use `impl` to encapsulate behavior related to your data types.*

## 4. `trait` – Abstract Behavior

Traits define *shared behavior* (like interfaces). Types implement traits to provide specific behavior.

```rust
trait Area {
    fn area(&self) -> f64;
}
```

You can implement it for your types:

```rust
impl Area for Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle(r) => std::f64::consts::PI * r * r,
            Shape::Rectangle(w, h) => w * h,
        }
    }
}
```

You can use traits as bounds:

```rust
fn print_area<T: Area>(shape: &T) {
    println!("Area: {}", shape.area());
}
```

- Use traits to define and enforce shared behavior across unrelated types.


## How They Fit Together

| Goal                                | Rust Construct |
| ----------------------------------- | -------------- |
| Group related fields together       | `struct`       |
| Represent multiple choices/variants | `enum`         |
| Add methods to types                | `impl`         |
| Define shared interfaces/behaviors  | `trait`        |

Together, they allow for **rich, type-safe modeling** of real-world entities and behaviors.

---

## What You Should Learn (Suggested Order)

| Topic                                                 | Why It's Important                       |
| ----------------------------------------------------- | ---------------------------------------- |
| ✅ `struct` basics                                     | Core to building data types              |
| ✅ `enum` and pattern matching                         | Enables expressive logic                 |
| ✅ `impl` blocks                                       | Add methods/constructors to types        |
| ✅ `trait` declaration and implementation              | Essential for abstraction and code reuse |
| ✅ Trait bounds & generics                             | Generic programming with constraints     |
| ✅ Common traits (`Debug`, `Clone`, `PartialEq`, etc.) | Built-in traits for utility              |
| ✅ Trait objects & dynamic dispatch                    | When you want polymorphism               |
| ✅ `match`, `if let`, `while let`                      | Deep dive into destructuring             |

---

## Bonus Concepts to Explore

* *Associated Types* in traits
* *Default implementations* in traits
* *Derive macros* (`#[derive(Debug, Clone)]`)
* *Enums with named fields*
* *Method chaining* via `impl`

---

## Next Steps

To get hands-on:

* Build a *command-line calculator* using `enum` for operations.
* Create a *geometry library* with `struct`, `enum`, `trait Area`.
* Model **state transitions** (e.g., TrafficLight, FSM) using enums + traits.

Would you like me to generate a *learning project* or *codebase template* based on these topics?

*complete Rust learning project* that guides you through using *structs, enums, impl blocks, and traits*, 
with a clear goal and layered learning experience.

---

#  Project: **Traffic Control System Simulator**

##  Goal

Build a command-line simulator for a **traffic control system** using Rust, where:

* Traffic signals (`TrafficLight`) change state (`Red`, `Green`, `Yellow`).
* Different intersections may have their own behavior rules.
* All logic is modeled with `enum`, `struct`, `impl`, and `trait`.

---

## 📁 Folder Structure

```
traffic_control/
├── Cargo.toml
└── src/
    ├── main.rs          # Entry point
    ├── models.rs        # Structs and Enums
    ├── traits.rs        # Traits (behaviors)
    └── logic.rs         # Implementations
```

---

## 🔧 Step-by-Step

---

### 1. `Cargo.toml`

```toml
[package]
name = "traffic_control"
version = "0.1.0"
edition = "2021"

[dependencies]
```

---

### 2. `src/models.rs`

```rust
// below is a built in trait useful to 
//    Debug(to print), Clone( to duplicate), Copy(make inexpensive to duplicate)
// enum holds 3 possible states
#[derive(Debug, Clone, Copy)]
pub enum TrafficLight {
    Red,
    Green,
    Yellow,
}
// Struct hold id, and current light state
#[derive(Debug)]
pub struct Intersection {
    pub id: u32,
    pub light: TrafficLight,
}
```

---

### 3. `src/traits.rs`

```rust
use crate::models::TrafficLight;

pub trait SignalCycle {
    fn next_light(current: TrafficLight) -> TrafficLight;
}
// This trait defines a single function, next_light. 
// Any type that implements this trait must provide a next_light function that takes a TrafficLight and 
// returns the next one in the sequence. 
// A powerful feature in Rust as it lets you define a common interface that different types can use.
```

---

### 4. `src/logic.rs`

```rust
use crate::models::{Intersection, TrafficLight};
use crate::traits::SignalCycle;

pub struct DefaultCycle;
//simple empty struct that is solely to implement the SignalCycle trait.

impl SignalCycle for DefaultCycle {
    fn next_light(current: TrafficLight) -> TrafficLight {
        match current {
            TrafficLight::Red => TrafficLight::Green,
            TrafficLight::Green => TrafficLight::Yellow,
            TrafficLight::Yellow => TrafficLight::Red,
        }
    }
}
//Intersection implementation: add methods to Intersection struct
impl Intersection {
    //A constructor, creates a new Intersection and gives it an id and inital state as Red.
    pub fn new(id: u32) -> Self {
        Self {
            id,
            light: TrafficLight::Red,
        }
    }

    // method using traits, it takes any type T that implements the SignalCycle trait and used next_light
    // function to update the intersection light.
    pub fn cycle<T: SignalCycle>(&mut self, _logic: T) {
        self.light = T::next_light(self.light);
    }

    //method to print id and and its state
    pub fn display(&self) {
        println!("Intersection {}: {:?}", self.id, self.light);
    }
}
```

---

### 5. `src/main.rs`

```rust
mod models;
mod traits;
mod logic;

use models::Intersection;
use logic::{DefaultCycle};
use std::thread::sleep;
use std::time::Duration;

fn main() {
    let mut inter = Intersection::new(1);

    for _ in 0..6 {
        inter.display();
        inter.cycle(DefaultCycle);
        sleep(Duration::from_secs(1));
    }
}
// creates a new Intersection 
// runs loop 6 times
// In each loop, it first displays the current state of the intersection, then calls the cycle method to 
// change the light's state using the DefaultCycle logic, and finally pauses for one second 
// using std::thread::sleep.
```

---

## What You Learn in This Project

| Concept        | Used In                                  |
| -------------- | ---------------------------------------- |
| `enum`         | TrafficLight                             |
| `struct`       | Intersection                             |
| `impl`         | Intersection methods                     |
| `trait`        | SignalCycle to define light progression  |
| `trait bounds` | `T: SignalCycle` in generic `cycle()`    |
| `match`        | Pattern match for light state transition |
| `mod` system   | Code split into files                    |

Code is organized into 4 files: 
main.rs   : main entry point that sets up a simulation loop.

models.rs : Defines data structs used in the prog. ( enum TrafficLight and struct Intersection )

traits.rs : Defines a trait "SignalCycle" which tells the behavior for a traffic light cycling.

logic.rs  : Implements SignalCycle trait for a specific type , 
            DefaultCycle and extends the Intersection struct with methods and behavior.



---

##  Suggested Exercises

###  Level 1 – Core

* Add `#[derive(PartialEq)]` to `TrafficLight` and check for equality.
* Add a second intersection.

###  Level 2 – Traits & Abstraction

* Add a new trait `EmergencyOverride` to allow forcing light to green.
* Implement `SignalCycle` differently for special junctions (e.g., longer red).

###  Level 3 – Enum Variants & State Machine

* Use **enums with data** (e.g., `Flashing(u8)` for flashing yellow).
* Represent each **intersection as a state machine** with history logging.

-----------------------------------------------------------------------------------------------


# Fit Constructs with Pattern match and destructuring


Rust Pattern Matching & Destructuring, and how this fits into the broader picture of 
*Rust constructs like enums, structs, traits, and impl blocks*.

---


#  *Pattern Matching & Destructuring in Rust – A Foundational Guide*

##  **Why Pattern Matching Matters in Rust**

Pattern matching is **one of the most powerful idioms in Rust**. It allows you to concisely:

* Unpack complex data structures (like structs, enums, and tuples)
* Express control flow based on the *structure* and *content* of values
* Avoid verbose if-else chains with expressive `match` blocks
* Handle ownership and borrowing safely

Pattern matching is tightly integrated with Rust’s core type system and memory safety model, making it both 
*expressive* and *safe*.

---

##  *Key Constructs You Need to Know First*

###  1. *Tuples & Arrays* – Basic grouping

```rust
let (x, y) = (1, 2); // tuple destructuring
let [a, b, c] = [10, 20, 30]; // array destructuring (fixed size only)
```

Useful for returning multiple values from functions, or when working with positional data.

---

###  2. *Structs* – Named, strongly typed aggregates

```rust
struct Point {
    x: i32,
    y: i32,
}

let p = Point { x: 3, y: 7 };

match p {
    Point { x: 0, y } => println!("Y axis: {}", y),
    Point { x, y } => println!("Point: ({}, {})", x, y),
}
```

Destructuring structs works with field names and supports shorthand if variable names match.

---

### 3. **Enums** – Algebraic Data Types (Variants)

```rust
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
    ChangeColor(i32, i32, i32),
}

let msg = Message::Move { x: 10, y: 20 };

match msg {
    Message::Quit => println!("Quit!"),
    Message::Move { x, y } => println!("Move to ({}, {})", x, y),
    Message::Write(text) => println!("Text: {}", text),
    Message::ChangeColor(r, g, b) => println!("Color: {},{},{}", r, g, b),
}
```

Enums + pattern matching let you model *state machines*, *protocols*, *commands*, *variants*, and more.

### 4. **impl blocks** – Defining behavior for types

```rust
impl Point {
    fn new(x: i32, y: i32) -> Self {
        Point { x, y }
    }
}
```

While pattern matching is about deconstructing values, `impl` blocks are about constructing *methods* and 
*associated functions* that produce or transform those values. They work together:

```rust
fn describe(p: Point) {
    match p {
        Point { x: 0, y } => println!("Vertical at y = {}", y),
        Point { x, y } => println!("General point at ({}, {})", x, y),
    }
}
```

---

### 5. *Traits* – Behavior abstraction across types

Traits let you generalize behavior and can also leverage pattern matching:

```rust
trait Drawable {
    fn draw(&self);
}

impl Drawable for Message {
    fn draw(&self) {
        match self {
            Message::Quit => println!("Nothing to draw."),
            Message::Move { x, y } => println!("Draw at {}, {}", x, y),
            Message::Write(text) => println!("Draw text: {}", text),
            Message::ChangeColor(r, g, b) => println!("Color: {}, {}, {}", r, g, b),
        }
    }
}
```

Pattern matching inside trait methods gives polymorphic behavior tailored to data variants.

---

## *What You Should Learn in Order*

Here’s a practical learning path:

| Stage | Concept             | What to Learn / Practice                                        |
| ----- | ------------------- | --------------------------------------------------------------- |
| 1️⃣   | Tuples & Structs    | Destructuring assignments, match patterns, field access         |
| 2️⃣   | Enums               | Match on enum variants, destructure variant contents            |
| 3️⃣   | Pattern Matching    | `match`, `if let`, `while let`, `_`, ranges, guards             |
| 4️⃣   | `impl` blocks       | Write methods returning or consuming structured data            |
| 5️⃣   | Traits              | Define behavior for enums/structs, use match inside trait impls |
| 6️⃣   | Nested Patterns     | Deep pattern matching: enums-in-structs, tuples-of-enums        |
| 7️⃣   | Match Guards        | Add extra conditions inside match arms                          |
| 8️⃣   | Borrow/Ref Matching | Match with `ref`, `ref mut`, and `&` patterns                   |

---

##  How it All Comes Together

Let’s combine *structs*, *enums*, *impl*, and *traits* in one pattern-rich example:

```rust
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
}

struct Drawing {
    shape: Shape,
    color: String,
}

trait Area {
    fn area(&self) -> f64;
}

impl Area for Drawing {
    fn area(&self) -> f64 {
        match self.shape {
            Shape::Circle { radius } => std::f64::consts::PI * radius * radius,
            Shape::Rectangle { width, height } => width * height,
        }
    }
}

fn main() {
    let draw = Drawing {
        shape: Shape::Circle { radius: 2.0 },
        color: String::from("Red"),
    };

    println!("Area = {}", draw.area());
}
```

---

