# Functional Programming: And Rust

Introduction to **functional programming (FP)** 

---

## Introduction to Functional Programming (FP)

### What is Functional Programming?

Functional programming is a programming style where you build your programs by composing **pure functions**, avoiding **mutable state** and **side effects**. It treats computation as the evaluation of mathematical functions.

---

### Why Learn Functional Programming?

* **Easier to reason about:** Functions behave predictably.
* **Fewer bugs:** Avoids side effects like changing global state.
* **Modular and reusable code:** Functions can be combined easily.
* **Better suited for parallelism:** No mutable shared state.

---

### Core Concepts of Functional Programming

#### 1. **Pure Functions**

* A function is **pure** if it always produces the same output for the same input and causes no side effects (no modifying global variables, no I/O).
* Example in C-style pseudocode:

```c
int add(int x, int y) {
    return x + y;
}
```

* This is pure because it doesn’t change anything outside the function and always returns the same result for the same inputs.

---

#### 2. **Immutability**

* Data, once created, **cannot be changed**.
* Instead of modifying variables, you create new data.
* This prevents accidental changes and bugs.

---

#### 3. **First-Class and Higher-Order Functions**

* Functions are treated as values.
* You can assign functions to variables, pass them as arguments, and return them from other functions.
* A **higher-order function** takes functions as arguments or returns functions.

Example pseudocode:

```c
// A function that takes another function as argument
int apply(int (*func)(int), int x) {
    return func(x);
}

int square(int x) {
    return x * x;
}

// Usage
int result = apply(square, 5);  // result = 25
```

---

#### 4. **Recursion Instead of Loops**

* FP often uses **recursion** (functions calling themselves) instead of traditional loops.
* This fits with the immutability concept (no changing loop counters).

Example pseudocode for factorial:

```c
int factorial(int n) {
    if (n == 0) return 1;
    else return n * factorial(n - 1);
}
```

---

#### 5. **Expression-Based Programming**

* Everything is an expression that evaluates to a value.
* No statements that do not produce a value.

---

#### 6. **Pattern Matching**

* Instead of using complex `if-else` or `switch`, pattern matching allows you to check a value against a pattern and de-structure data easily.

Example in pseudocode:

```c
switch (state) {
    case IDLE:
        // handle idle
        break;
    case RUNNING:
        // handle running
        break;
    default:
        // handle other
}
```

---

#### 7. **Algebraic Data Types**

* Combine multiple types into a single type with variants.
* Example: A variable that can be either a success or an error with extra info.

---

### Functional Programming vs Imperative (C-style) Programming

| Concept       | Imperative (C)                     | Functional Programming               |
| ------------- | ---------------------------------- | ------------------------------------ |
| State changes | Mutable variables and global state | Immutability, no state changes       |
| Side effects  | Common (I/O, changing variables)   | Avoided in pure functions            |
| Control flow  | Loops, conditionals                | Recursion, pattern matching          |
| Functions     | Subroutines, function pointers     | First-class, higher-order functions  |
| Data          | Mutable structs, arrays            | Immutable data, algebraic data types |

---

### Summary

* FP focuses on **what to compute**, not how to compute it.
* It emphasizes **pure functions**, **immutability**, and **function composition**.
* It can make programs more **robust**, **testable**, and easier to **parallelize**.
* It’s a different way of thinking compared to traditional C-style programming, but learning it expands your problem-solving toolbox.

---

# Rust and FP:

Rust supports FP features, but it's not a pure functional language.

Think of Rust as a multi-paradigm language: It blends imperative Object-Oriented, and functional styles. 

It gives you powerful functional tools without forcing you into the FP mindset all the time.

## Rust Supported Functional Programming:

1. Immutability by default. ( A core FP concept )

    `let x = 5; // immutable`

2. First-Classes and Higher order Functions:

```rust 
fn apply(f: fn(i32) -> i32, x: i32) -> i32 {
    f(x)
}

fn square(x: i32) -> i32 {
    x * x
}

let result = apply(square, 4); // 16

```
2.1 Closures ( anonymous functions )

```rust 
let add_one = |x: i32| x + 1;
println!("{}", add_one(5)); // 6
```

3. Iterator Adapters and Lazy Evaluation:

Rust encourages chaining transformation on data, like in functional language:

```rust  
let nums = vec![1,2,3];
let doubled: Vec<_> = nums.iter().map(|x| x * 2).collect();
```

This is similar to FP patterns like `map`, `filter`, `fold`.


4. Pattern Matching: 
Pattern matching is expressive and functional in spirit.
```rust 
match some_value {
    Some(x) => println!("Got {}", x),
    None => println!("Nothing"),
}
```
5. Option and Result Type ( from std ):

Rust avoids nulls and exception. Instead it uses algebraic data types (Option, Result)
a staple in FP language.

```rust 
fn divide(x: i32, y: i32) -> Option<i32> {
    if y == 0 { None } else { Some(x / y) }
}
```

And combinators like .map(), .and_then(), etc., let you write functional-style chains:
```rust
let res = divide(10, 2).map(|n| n * 2); // Some(10)
```

6. No Global Mutable state by default: 
Global mutable state ( common in C ) is discouraged and controlled in Rust, encouraging more 
FP-linke structure:


## What Rust Can not do (That Pure FP Languages Do)

No enforced purity: Functions can still have side effects.

No lazy evaluation by default: Unlike Haskell.

Mutability is allowed: It’s just opt-in with mut.

No tail call optimization: So deep recursion can still be a problem.

You can write Rust in an FP style where it makes sense, and combine it with imperative or 
systems-level code when you need control over performance or hardware.




