# Rust Functions & Methods 

In Rust, functions are declared using the "fn" keyword. 
Each function can take a set of input variables with their specified types, and may return data of a 
specified type. 
The body of a function is contained within curly braces {}. 

Unlike other languages, in Rust, you don't need to end the last statement in a block with a semicolon; 
omitting the last semicolon of a block in this way turns the last statement into an expression, and the 
result of this expression becomes the implicit return value of the block.


*Rust functions and methods*, for deep understanding and practical application.

---

## 1. *Basic Function Syntax*


Functions in Rust are defined using the `fn` keyword.

```rust
fn greet() {
    println!("Hello, world!");
}
```

### Notes:

* Function names use *snake_case* by convention.
* The body is enclosed in `{}`.
* Return type is optional if the function returns `()` (unit).
* Functions can be defined *anywhere* in a scope, including inside other functions (nested).

## 2. *Function Parameters and Return Values*

```rust
fn add(a: i32, b: i32) -> i32 {
    a + b // no semicolon = return value
}
```

### Notes:

* All parameters and return types must be explicitly typed.
* Rust does *not support function overloading* (you can’t define multiple functions with the same name but 
  different parameters).
* If you add a semicolon to the last line (`a + b;`), it will return `()` instead — a common mistake!

## 3. *Explicit vs. Implicit Return*

```rust
fn square(x: i32) -> i32 {
    return x * x; // explicit return
}

fn cube(x: i32) -> i32 {
    x * x * x // implicit return
}
```

> Use *no semicolon* to return the value of the last expression implicitly.

---

## 4. *Function with Multiple Return Values (Tuples)*

```rust
fn min_max(a: i32, b: i32) -> (i32, i32) {
    if a < b {
        (a, b)
    } else {
        (b, a)
    }
}
```

### Use:

```rust
let (min, max) = min_max(3, 7);
```

## 5. *Default Return Value: `()`*

If a function doesn’t explicitly return anything, its return type is `()` (unit).

```rust
fn do_nothing() {
    // returns ()
}
```

## 6. *Using Functions as Values*

Rust allows you to use function names as values.

```rust
fn say_hello() {
    println!("Hello!");
}

fn main() {
    let greeter: fn() = say_hello;
    greeter(); // calls say_hello
}
```

## 7. *Function Pointers vs Closures*

Functions:

```rust
fn add_one(x: i32) -> i32 {
    x + 1
}
```

Closures (anonymous functions):

```rust
let add_one = |x: i32| x + 1;
```

## 8. *Generic Functions*

Rust functions can be *generic over types*.

```rust
fn identity<T>(x: T) -> T {
    x
}
```

Use:

```rust
let a = identity(5); // T = i32
let b = identity("hello"); // T = &str
```

---

## 9. *Function Attributes*

Attributes like `#[inline]`, `#[test]`, or `#[allow(unused)]` can be used above functions.

```rust
#[inline]
fn fast_add(a: i32, b: i32) -> i32 {
    a + b
}
```

## 10. *Variadic Functions*

Only supported in `extern "C"` (FFI), not in pure Rust.

```rust
extern "C" {
    fn printf(format: *const u8, ...) -> i32;
}
```

## 11. *Methods (`impl` blocks)*

Methods are *functions associated with a struct, enum, or trait*.

```rust
struct Rectangle {
    width: u32,
    height: u32,
}

impl Rectangle {
    fn area(&self) -> u32 {
        self.width * self.height
    }

    fn is_square(&self) -> bool {
        self.width == self.height
    }

    fn new(w: u32, h: u32) -> Self {
        Self { width: w, height: h }
    }
}
```

Use:

```rust
let rect = Rectangle::new(10, 20);
println!("Area: {}", rect.area());
```

## 12. *Associated Functions (`Self::new()`)*

These are like static functions — they don't take `self` as a parameter.

```rust
impl Rectangle {
    fn new(w: u32, h: u32) -> Self {
        Self { width: w, height: h }
    }
}
```

## 13. *Chaining Methods*

```rust
impl Rectangle {
    fn double(&self) -> Self {
        Self {
            width: self.width * 2,
            height: self.height * 2,
        }
    }
}

let doubled = rect.double().area();
```

---

## 14. *Closures vs Functions*

Closures are inline, often capture environment, and are declared with `|params| {}`.

```rust
let x = 5;
let add_x = |y| y + x;
```

Closures can be passed to higher-order functions like `map()` or `filter()`.

---

## Summary Table

| Feature              | Syntax Example                    | Notes                     |         |                  |
| -------------------- | --------------------------------- | ------------------------- | ------- | ---------------- |
| Basic Function       | `fn name() {}`                    | Entry point or logic unit |         |                  |
| Parameters & Return  | `fn add(a: i32) -> i32 { a + 1 }` | Must define types         |         |                  |
| Implicit Return      | `a + b` (no semicolon)            | Makes block return value  |         |                  |
| Multiple Returns     | `(i32, i32)`                      | Use tuples                |         |                  |
| Methods              | `fn area(&self)`                  | Defined in `impl` block   |         |                  |
| Associated Functions | `fn new() -> Self`                | Called like `Type::new()` |         |                  |
| Closures             | \`                                | x                         | x + 1\` | Inline functions |
| Generics             | `fn id<T>(x: T) -> T`             | Works with any type       |         |                  |
| Function as Value    | `let f: fn() = my_fn;`            | Can pass/assign functions |         |                  |

---

## 🧪 Practice Exercise Ideas

1. Write a function to compute factorial recursively.
2. Write a method on a `Point` struct to compute distance.
3. Implement a generic function that reverses any `Vec<T>`.
4. Try using closures to filter a list of numbers.

---

#  Trait Methods in Rust

Trait methods are functions *declared in a trait* and *implemented by types*. 
They're used to define shared behavior across multiple types.


##  1. *Defining and Implementing Trait Methods*

```rust
trait Greet {
    fn greet(&self); // trait method
}

struct Person;
struct Dog;

impl Greet for Person {
    fn greet(&self) {
        println!("Hello, I'm a person.");
    }
}

impl Greet for Dog {
    fn greet(&self) {
        println!("Woof! 🐶");
    }
}
```

### Use:

```rust
fn main() {
    let p = Person;
    let d = Dog;

    p.greet();
    d.greet();
}
```

##  2. *Default Method Implementation*

Traits can provide *default method bodies*:

```rust
trait Animal {
    fn speak(&self) {
        println!("Some generic animal sound.");
    }
}

struct Cat;

impl Animal for Cat {
    // Optional: override speak()
}
```

## 3. *Static vs Instance Trait Methods*

```rust
trait Factory {
    fn create() -> Self; // static method (no &self)
}

struct Product;

impl Factory for Product {
    fn create() -> Self {
        Product
    }
}
```

## 4. *Trait Objects (Dynamic Dispatch)*

```rust
fn call_greet(greeter: &dyn Greet) {
    greeter.greet();
}
```

> `dyn Trait` enables runtime polymorphism (like virtual functions in C++).


# How Trait Methods Differ from Regular Methods

| Feature             | Trait Method                    | Regular Method (in `impl`)  |
| ------------------- | ------------------------------- | --------------------------- |
| Requires Trait      | Yes                             | No                          |
| Shared Across Types | Yes                             | No (only for that one type) |
| Dispatch            | Static or Dynamic (`dyn Trait`) | Always static               |
| Override Required?  | Optional (if default provided)  | N/A                         |
| Use Case            | Polymorphism, interfaces        | Struct-specific behavior    |

---

# Advanced Function Concepts (Short Overview)

##  1. *Higher-Order Functions (HOFs)*

HOFs are functions that *take functions as arguments* or *return functions*.

###  Example: `map`, `filter`

```rust
fn apply_twice(f: fn(i32) -> i32, x: i32) -> i32 {
    f(x) + f(x)
}

fn square(n: i32) -> i32 {
    n * n
}

fn main() {
    println!("{}", apply_twice(square, 3)); // 18
}
```

You can also use closures:

```rust
let nums = vec![1, 2, 3];
let doubled: Vec<_> = nums.iter().map(|x| x * 2).collect();
```

## 2. *Async Functions*

Used for non-blocking operations, like I/O.

```rust
async fn fetch_data() -> u32 {
    42
}

#[tokio::main] // Or use `async-std`
async fn main() {
    let result = fetch_data().await;
    println!("Result: {}", result);
}
```

> Async functions *return a `Future`*, which must be `.await`ed inside an `async` context.

---

## 3. *Closures Returning Closures*

```rust
fn make_multiplier(x: i32) -> impl Fn(i32) -> i32 {
    move |y| x * y
}

fn main() {
    let double = make_multiplier(2);
    println!("{}", double(10)); // 20
}
```

## 🧪 Summary Table

| Feature       | Description                              | Example Syntax              |   |         |
| ------------- | ---------------------------------------- | --------------------------- | - | ------- |
| Trait Methods | Declared in traits, implemented on types | `fn greet(&self)`           |   |         |
| HOFs          | Take or return functions                 | `fn apply(f: fn(i32)->i32)` |   |         |
| Closures      | Anonymous inline functions               | \`                          | x | x + 1\` |
| Async         | Used for non-blocking futures            | `async fn`, `.await`        |   |         |

---

# 1️⃣ Trait Object vs Generic Traits Example


### Trait Object (Dynamic Dispatch)

Trait objects use `dyn Trait` to enable runtime polymorphism. 
This means the concrete type isn’t known at compile time, and calls are resolved at runtime.

```rust
trait Animal {
    fn speak(&self);
}

struct Dog;
struct Cat;

impl Animal for Dog {
    fn speak(&self) {
        println!("Woof!");
    }
}

impl Animal for Cat {
    fn speak(&self) {
        println!("Meow!");
    }
}

fn animal_speak(animal: &dyn Animal) {
    animal.speak();
}

fn main() {
    let dog = Dog;
    let cat = Cat;

    animal_speak(&dog);
    animal_speak(&cat);
}
```

* *Uses dynamic dispatch* (`&dyn Animal`).
* Allows heterogeneous collections like `Vec<Box<dyn Animal>>`.
* Slight runtime cost due to vtable lookup.

### Generic Traits (Static Dispatch)

Generics are resolved at compile-time, leading to zero-cost abstractions.

```rust
trait Animal {
    fn speak(&self);
}

struct Dog;
struct Cat;

impl Animal for Dog {
    fn speak(&self) {
        println!("Woof!");
    }
}

impl Animal for Cat {
    fn speak(&self) {
        println!("Meow!");
    }
}

fn animal_speak<T: Animal>(animal: &T) {
    animal.speak();
}

fn main() {
    let dog = Dog;
    let cat = Cat;

    animal_speak(&dog);
    animal_speak(&cat);
}
```

* *Uses static dispatch*.
* Generates monomorphized versions per concrete type.
* No runtime cost.
* Does **not** allow heterogeneous collections easily.

---

### Summary Comparison

| Aspect       | Trait Object (`dyn Trait`)       | Generic Trait (`T: Trait`)      |
| ------------ | -------------------------------- | ------------------------------- |
| Dispatch     | Dynamic (runtime)                | Static (compile-time)           |
| Runtime Cost | Slight (vtable calls)            | None                            |
| Code Size    | Smaller (one implementation)     | Larger (monomorphized per type) |
| Flexibility  | Allows heterogeneous collections | Homogeneous types only          |
| Syntax       | `&dyn Trait`                     | `T: Trait`                      |

# 2️⃣ Mini Project: Async + Traits + Closures

## Project: Async Task Runner with Logging Trait and Closure Tasks

### Goal

* Define a *trait* for logging.
* Create an *async task runner* that accepts closures representing async tasks.
* Log task start/end using the trait.

### Step 1: Define the Logger Trait

```rust
#[async_trait::async_trait] // For async trait methods
trait Logger {
    async fn log(&self, message: &str);
}
```

### Step 2: Implement Logger

```rust
struct ConsoleLogger;

#[async_trait::async_trait]
impl Logger for ConsoleLogger {
    async fn log(&self, message: &str) {
        println!("[LOG] {}", message);
    }
}
```

### Step 3: Async Task Runner

```rust
use std::future::Future;

struct TaskRunner<L: Logger> {
    logger: L,
}

impl<L: Logger> TaskRunner<L> {
    async fn run_task<F, Fut>(&self, name: &str, task: F)
    where
        F: Fn() -> Fut,
        Fut: Future<Output = ()>,
    {
        self.logger.log(&format!("Starting task '{}'", name)).await;
        task().await;
        self.logger.log(&format!("Finished task '{}'", name)).await;
    }
}
```

### Step 4: Use It

```rust
#[tokio::main]
async fn main() {
    let logger = ConsoleLogger;
    let runner = TaskRunner { logger };

    runner.run_task("SayHello", || async {
        println!("Hello from task!");
    }).await;

    runner.run_task("Wait", || async {
        tokio::time::sleep(std::time::Duration::from_secs(1)).await;
        println!("Waited 1 second");
    }).await;
}
```

## Explanation:

* `Logger` trait has an *async method* for logging.
* `TaskRunner` is generic over `Logger`.
* `run_task` accepts a closure returning a future (async closure).
* Logs before and after task execution.
* Uses the popular Tokio async runtime.

---

## Dependencies (add to `Cargo.toml`):

```toml
[dependencies]
tokio = { version = "1", features = ["full"] }
async-trait = "0.1"
```

---

# What You Learned:

* How to write *async traits* (via `async-trait` crate).
* How to accept *async closures* as function parameters.
* Combining traits, async functions, and closures to build modular, reusable components.

If you want, I can help you build this project step-by-step or provide a runnable GitHub gist!

---

todo:

* How to create your own async trait without `async-trait` crate?
* How to handle errors in async tasks with traits?
* How to use trait objects for the logger instead of generics?
