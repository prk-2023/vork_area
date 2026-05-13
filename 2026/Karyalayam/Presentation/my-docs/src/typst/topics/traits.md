# Rust Traits — Beginner Learning Notes

---

# 1. What is a Trait?

A **trait** defines shared behavior.

It says:

```text
"If a type implements this trait,
it must provide these methods/abilities."
```

Traits are similar to:

* Interfaces in Java
* Protocols in Swift
* Interfaces in Go/TypeScript

=> 
NOTE: 
    - Rust traits are more general then just "collection of methods" they can represent:
        * behavior (methods)
        * capabilities 
        * guarantees
        * properties 
        * compile-time metadata 
    - More on this additional info below [ MoreOnTraits ](#MoreOnTraits)

---

# 2. Core Mental Model

| Concept  | Meaning          |
| -------- | ---------------- |
| `struct` | stores data      |
| `trait`  | defines behavior |

---

## Example

```rust 
struct Dog;
```

This only defines a type.

Now define behavior:

```rust
trait Speak {
    fn speak(&self);
}
```

This means:

```text
Anything implementing Speak
must define speak()
```

---

# 3. Implementing a Trait

```rust
impl Speak for Dog {
    fn speak(&self) {
        println!("Woof!");
    }
}
```

Now `Dog` can speak.

---

# 4. Using Traits

```rust
fn make_it_speak(animal: &impl Speak) {
    animal.speak();
}
```

Usage:

```rust
let dog = Dog;

make_it_speak(&dog);
```

---

# 5. Built-in Types Already Have Traits

=> Rust primitive types already implement many traits <=

Example:

```rust
let x = 5;

println!("{}", x);
```

This works because:

```text
i32 implements Display
```

---

# Common Built-in Trait Implementations

| Type     | Traits                              |
| -------- | ----------------------------------- |
| `i32`    | `Copy`, `Clone`, `Debug`, `Display` |
| `String` | `Clone`, `Debug`                    |
| `Vec<T>` | `Clone`, `Debug`                    |

---

# 6. User-defined Structs Do NOT Automatically Get Traits

Example:

```rust 
struct User {
    name: String,
}
```

This fails:

```rust 
println!("{:?}", user);
```

because `User` does not implement `Debug`.

---

# 7. Deriving Traits

Rust can auto-generate common traits.

```rust 
#[derive(Debug)]
struct User {
    name: String,
}
```

Now:

```rust 
println!("{:?}", user);
```

works.

---

# Common Derivable Traits

| Trait       | Purpose              |
| ----------- | -------------------- |
| `Debug`     | printing with `{:?}` |
| `Clone`     | explicit copying     |
| `Copy`      | automatic copying    |
| `PartialEq` | comparison with `==` |
| `Hash`      | hashing support      |

---

# 8. Creating Your Own Trait

Example:

```rust 
trait Greet {
    fn greet(&self);
}
```

Implement it:

```rust 
struct Person {
    name: String,
}

impl Greet for Person {
    fn greet(&self) {
        println!("Hello {}", self.name);
    }
}
```

Usage:

```rust 
let p = Person {
    name: String::from("Alice"),
};

p.greet();
```

---

# 9. Traits Can Be Implemented for Primitive Types

You can implement YOUR trait on built-in types.

Example:

```rust 
trait Double {
    fn double(self) -> Self;
}
```

Implement for `i32`:

```rust 
impl Double for i32 {
    fn double(self) -> Self {
        self * 2
    }
}
```

Usage:

```rust 
println!("{}", 5.double());
```

Output:

```text 
10
```

---

# 10. Trait Rules (Orphan Rule)

Rust prevents conflicting implementations.

---

## Allowed

### Your trait + your type

```rust 
trait Fly {}

struct Bird;

impl Fly for Bird {}
```

✅ allowed

---

## Your trait + Rust type

```rust 
trait Double {}

impl Double for i32 {}
```

✅ allowed

---

## Rust trait + your type

```rust 
#[derive(Debug)]
struct User;
```

Equivalent to:

```rust 
impl Debug for User {}
```

✅ allowed

---

# Forbidden

## Rust trait + Rust type

```rust 
impl Clone for i32 {}
```

❌ NOT allowed

Reason:

* Rust already owns both
* avoids conflicts

---

# 11. Traits with Generics

Traits are heavily used with generics.

Example:

```rust 
fn print_value<T: std::fmt::Display>(x: T) {
    println!("{}", x);
}
```

Meaning:

```text 
T can be any type
that implements Display
```

---

# 12. Default Trait Methods

Traits can provide default implementations.

```rust 
trait Greet {
    fn name(&self) -> &str;

    fn greet(&self) {
        println!("Hello {}", self.name());
    }
}
```

Implement only required parts:

```rust 
struct User {
    name: String,
}

impl Greet for User {
    fn name(&self) -> &str {
        &self.name
    }
}
```

Now:

```rust 
user.greet();
```

works automatically.

---

# 13. Marker Traits

Some traits define guarantees instead of methods.

Example:

* `Send`
* `Sync`

These are thread-safety traits.

---

## `Send`

```text 
Safe to move ownership to another thread
```

---

## `Sync`

```text 
Safe to share references across threads
```

---

# 14. Important Concurrency Types

| Type         | Thread-safe? |
| ------------ | ------------ |
| `Rc<T>`      | ❌ No         |
| `Arc<T>`     | ✅ Yes        |
| `RefCell<T>` | ❌ No         |
| `Mutex<T>`   | ✅ Yes        |

---

# 15. Trait Syntax Summary

---

## Define a trait

```rust 
trait MyTrait {
    fn method(&self);
}
```

---

## Implement a trait

```rust 
impl MyTrait for MyType {
    fn method(&self) {
    }
}
```

---

## Generic trait bounds

```rust 
fn f<T: MyTrait>(x: T)
```

---

# 16. Real-world Analogy

Imagine:

```text 
Trait = Job Requirement
```

Example:

```text 
Trait: Drivable
Required method: drive()
```

Anything can satisfy it:

* Car
* Truck
* Bike

as long as it implements `drive()`.

---

# 17. The Big Picture

Traits are one of Rust’s MOST important concepts.

They power:

* generics
* polymorphism
* abstraction
* iterators
* async
* formatting
* conversions
* thread safety
* operator overloading

---

# Final Memory Shortcut

```text
Structs = data
Traits = abilities
Impl = attaching abilities to data
```

Rust programs are largely built from:

* structs
* enums
* traits
* implementations (`impl`)

-------------------------------------------
# Supported traits for a type:

In Rust, you usually discover what traits a type supports in a few common ways.

---

# 1. Rust Compiler Errors (Most Common)

The compiler tells you when a trait is missing.

Example:

```rust
struct User {
    name: String,
}

fn main() {
    let u = User {
        name: String::from("Alice"),
    };

    println!("{:?}", u);
}
```

Error:

```text 
User doesn't implement Debug
```

This is Rust teaching you:

* `println!("{:?}")` requires `Debug`
* your type lacks that trait

---

# 2. Rust Documentation

The official docs list implemented traits.

Example:

* `String`
* `Vec<T>`
* `Option<T>`

On a type’s page, look for:

```text 
Trait Implementations
```

and:

```text 
Auto Trait Implementations
```

---

## Example

For `String`, you'll see traits like:

* `Clone`
* `Debug`
* `Display`
* `PartialEq`
* `Eq`
* `Hash`

---

# 3. IDE / rust-analyzer (Best Developer Experience)

If you use:

* VSCode + rust-analyzer
* IntelliJ Rust
* Zed
* RustRover

you can hover over a type and inspect traits.

Example:

```rust 
let s = String::from("hello");
```

Hover `String`.

The IDE often shows:

* methods
* implemented traits
* docs

---

# 4. Use Methods as Clues

Traits usually provide methods.

Example:

```rust
let x = String::from("abc");

x.clone();
```

If `.clone()` works:

```text 
String implements Clone
```

---

Another:

```rust
println!("{}", x);
```

means:

* `Display` is implemented

---

# 5. Generic Trait Bounds Reveal Requirements

Example:

```rust 
fn print<T: std::fmt::Debug>(x: T) {
    println!("{:?}", x);
}
```

This function only accepts types implementing `Debug`.

If your type fails:

```text
the trait Debug is not implemented
```

you know what’s missing.

---

# 6. Derive Macros Show Common Traits

Example:

```rust
#[derive(Debug, Clone, PartialEq)]
struct User {
    name: String,
}
```

This means your type now supports:

* `Debug`
* `Clone`
* `PartialEq`

---

# 7. Auto Traits

Some traits are automatically determined.

Example:

* `Send`
* `Sync`

Rust infers these from fields.

---

## Example

```rust 
struct Data {
    value: i32,
}
```

Since `i32` is `Send + Sync`,
`Data` becomes `Send + Sync`.

---

# 8. How to See ALL Traits in Practice

There is no built-in Rust command like:

```text
show me every trait for this type
```

But practically, developers use:

| Method                 | Best For                |
| ---------------------- | ----------------------- |
| Compiler errors        | learning missing traits |
| Docs                   | official trait lists    |
| IDE hover/autocomplete | daily work              |
| Method availability    | quick hints             |
| derive attributes      | common trait support    |

---

# 9. Important Distinction

A type may:

* implement a trait
* but you may not notice until you use it

Example:

```rust 
let a = vec![1, 2, 3];
let b = a.clone();
```

You just used:

* `Clone` on `Vec<T>`

without explicitly thinking about traits.

Rust traits often feel invisible until needed.

---

# 10. Real-world Beginner Workflow

Usually beginners learn traits like this:

---

## Step 1

Try something:

```rust
println!("{:?}", user);
```

---

## Step 2

Compiler says:

```text
User doesn't implement Debug
```

---

## Step 3

Add:

```rust
#[derive(Debug)]
```

---

## Step 4

Program works.

This is the normal Rust learning path.

---

# 11. Useful Common Traits to Recognize

| Trait       | What it Enables      |
| ----------- | -------------------- |
| `Debug`     | `{:?}` printing      |
| `Display`   | `{}` printing        |
| `Clone`     | `.clone()`           |
| `Copy`      | automatic copying    |
| `PartialEq` | `==`                 |
| `Iterator`  | iteration            |
| `Default`   | default values       |
| `Send`      | move across threads  |
| `Sync`      | share across threads |

---

# Final Mental Model

```text 
Methods usually come from traits.
```

If a type can:

* clone
* print
* compare
* iterate
* convert

then somewhere,
a trait is providing that ability.

------------------------------------
# More on Traits 

## MoreOnTraits 

A Rust trait is more general than just “a collection of methods.”

Traits can represent:

* behavior (methods)
* capabilities
* guarantees
* properties
* compile-time metadata

---

# 1. Normal Traits (Behavior Traits)

These define methods.

Example:

```rust 
trait Speak {
    fn speak(&self);
}
```

This says:

```text 
Types implementing Speak
must provide speak()
```

---

# 2. Marker Traits

Marker traits define NO methods.

They only communicate a property/guarantee to the compiler.

Example:

```rust 
trait Send {}
```

Conceptually.

Real `Send` is built into Rust internally.

---

# Meaning of `Send`

```text 
"This type is safe to move to another thread."
```

No methods needed.

The trait itself is the guarantee.

---

# Another Marker Trait: `Sync`

```text 
"This type is safe to share between threads."
```

Again:

* no methods
* just a property

---

# Marker Traits Are Compile-time Labels

Think of them like tags.

Example:

```text 
Fragile
Serializable
ThreadSafe
Copyable
```

The compiler checks these tags during compilation.

---

# Example Comparison

---

## Behavior Trait

```rust 
trait Draw {
    fn draw(&self);
}
```

Purpose:

* defines functionality

---

## Marker Trait

```rust 
trait Send {}
```

Purpose:

* defines safety guarantee

---

# 3. Traits Can Also Define Associated Types

Traits are even more powerful.

Example:

```rust 
trait Iterator {
    type Item;

    fn next(&mut self) -> Option<Self::Item>;
}
```

Here the trait defines:

* behavior (`next`)
* associated type (`Item`)

---

# 4. Traits Can Define Constants

Example:

```rust 
trait Math {
    const PI: f64;
}
```

So traits are not limited to methods.

---

# 5. Traits as Constraints

Sometimes traits exist mainly for generic restrictions.

Example:

```rust 
fn print<T: Debug>(x: T)
```

`Debug` here acts like:

```text 
"a type capability requirement"
```

---

# 6. Big Mental Model

Traits in Rust are really:

```text 
compile-time capabilities/contracts
```

Methods are only ONE possible part.

A trait may define:

* methods
* guarantees
* associated types
* constants
* bounds/constraints
* metadata

---

# 7. Common Trait Categories

| Trait Type          | Purpose         | Example            |
| ------------------- | --------------- | ------------------ |
| Behavior trait      | methods         | `Iterator`         |
| Marker trait        | guarantees      | `Send`, `Sync`     |
| Operator trait      | operators       | `Add`, `Sub`       |
| Conversion trait    | type conversion | `From`, `Into`     |
| Formatting trait    | printing        | `Debug`, `Display` |
| Async/runtime trait | async behavior  | `Future`           |

---

# 8. Important Insight

Rust uses traits everywhere because traits are the language’s abstraction system.

Instead of:

* inheritance
* base classes
* virtual hierarchies

Rust uses:

* traits
* implementations
* composition

---

# Final Mental Model

```text 
Trait = "This type supports/guarantees something."
```

Sometimes that “something” is:

* a method
* a property
* a safety guarantee
* a compile-time capability

`Send` and `Sync` are perfect examples of non-method traits.





------------------------------------



# Rust Traits: A Comprehensive Guide

Rust traits are a very powerful feature of the language. 

- Enables Polymorphism,
- Code Reuse 
- Type System Flexibility.


## What are traits?

Rust Traits define *shared behaviour that types can implement*. 
These are similar to interfaces in C++,Java,TypeScript ( check below References )
Rust traits are more powerful then what Interfaces provide.

```rust 
/*  --- define s trait  -- 
    Any Type that implements this triat should define 'speak' method 
*/
trait Speak {
    fn speak(&self) -> String;

}

// Implement for a type
struct Dog {
    name: String,
}
impl Speak for Dog {
    fn speak(&self) -> String {
        format!("{} says wolf", self.name)
    }
}
 struct Cat;
 impl Speak for Cat {
    fn speak (&self) -> String {
        "Meow!".to_string()
    }
 }

```
## Trait related Topics to Cover:

### 1. Basics of Trait Implementation:
- Define traits with methods.
- Implementing traits for types.
- Associated functions in traits.

To declare a trait the syntax is as:

```rust 
trait Printable {
    fn print(&self);
}
```
This declares a trait with one method `print`

Traits can also provide **Default Implementation**

```rust 
trait Printable {

    fn print(&self) {
        println!("Default print");
    }
}
```

Implementing Traits:
```rust 

struct Person {
    name: String,
}

impl Printable for Person {
    fn print(&self) {
        println!("Person: {} ", self.name);
    }
}

==> You can implelemt *traits* for enums, and other types ( even primitive types with rules ).
```

Associated functions  in traits: ( like static methods )
```rust 
trait Math {
    fn zero() -> Self;
}
```
### 2. Trait Bounds:
- Generic function with trait bounds. 
- `where` clause for complex bounds.

Traits can be used as **constraints** (bounds) for generic types 

```rust 
fn display<T: Printable> (item: T) {
    item.print();
}
```
Equivalent shorthand is by using `where` clause:
```rust 
fn display<T> (item: T)
where 
    T: Printable,
{
    item.print();
}
```
Another example:
```rust 
fn make_sound<T: Speak>(animal: &T) {
    println!("{}"animal.speak());
}

//Equivalent with where clause
fn make_sound<T> (animal: &T) 
where 
    T: Speak,
    {
        println!("{}"animal.speak());
    }
```

Multiple trait bounds: 

```rust 
fn do_stuff<T: Clone + Printable(item: T) { .... }

```

### 3. Traits and Structs together:
Using traits to define behaviour:

```rust 
trait Area {
    fn area(&self) -> f64;
}

struct Circle {
    radius: f64,
}

impl Area for Circle {
    fn area(&self) -> f64 {
        3.14 * self.radius * self.radius
    }
}
```
==> You can implement similar traits for enums, and other types ( even primitive types with rules ).

### 4. Trait Objects and Dynamic Dispatch:
- Dynamic Dispatch with `dyn Trait`
- Object safety requirements.

Used when you want ** runtime Polymorphism **.

```rust 
trait Drawable {
    fn draw(&self);
}

struct Button;
impl Drawable for Button {
    fn draw(&self) {
        println!("Drawing a button");
    }
}

fn render(ui: &dyn Drawable) {
    ui.draw();
}
```
- `&dyn Trait` is a *trait object*
- Enables *dynamic dispatch* ( like vtables in C++ )
- Can only be used with *object-safe* traits.

=> Object Safety: 
Trait must be *object-safe* to use with `dyn`:
1. No generic methods 
2. Method must use `&self`, `&mut self` or `self`

Allowed: 

```rust 
trait Good {
    fn do_it(&self);
}
```
❌ Not allowed:

```rust
trait Bad {
    fn new<T>() -> T;
}
```


```rust 
// Trait object for hetrogeneous collections:
let animals: Vec<&dyn Speak> = vec![&dog, &cat];
for animal in animals {
    println!("{}", animal.speak());
}
```




### 5. Supertraits:

A **trait that depends on another trait**

```rust 
trait Write {
    fn write(&self);
}

trait Log: Write {
    fn log(&self) {
        self.write(); // can call write because it's a supertrait.
    }
}
```

### 6. Auto Traits:

Automatically Implemented traits by the compiler like:
- `Send`, `Sync`, `Unpin` ...

Note: Custom auto traits are unstable as of now.

### 7. Marker Traits:
- Traits with no methods.
- `Copy`, `Sized`, `Send`, `Sync`

### 8. Derivable Traits:

Rust provides built-in **derive Macro** for common traits:

- `#[derive]` attribute
- Common traits: `Debug`, `Clone`, `Copy`, `PartialEq`, etc.

```rust 
#[derive(Debug, Clone, PartialEq)]
struct Point {
    x: i32,
    y: i32,
}
```

```rust 
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct User {
    name: String,
    age: i32,
}
```

**Common derivable traits**: 

* `Debug`
* `Clone`, `Copy`
* `PartialEq`, `Eq`
* `Ord`, `PartialOrd`
* `Hash`
* `Default`

And there are  **Common Standard Library Traits**

| Trait               | Purpose                  |
| ------------------- | ------------------------ |
| `Debug`             | For printing with `{:?}` |
| `Clone` / `Copy`    | Duplicate values         |
| `Default`           | Create default values    |
| `PartialEq`, `Eq`   | Equality                 |
| `PartialOrd`, `Ord` | Ordering                 |
| `Iterator`          | Iteration                |
| `Into`, `From`      | Conversions              |
| `AsRef`, `Borrow`   | References and borrowing |
| `Deref`, `Drop`     | Smart pointers & cleanup |


### 9. Associated Traits:

Instead of generic parameters, traits can use **associated types**:

```rust
trait Iterator {
    type Item;

    fn next(&mut self) -> Option<Self::Item>;
}
```

Usage:

```rust
struct Counter;

impl Iterator for Counter {
    type Item = u32;

    fn next(&mut self) -> Option<Self::Item> {
        Some(42)
    }
}
```

### 10. Trait Objects Vs Generics 
- Static vs dynamic dispatch 
- Performance trade-offs


### 11. Advanced Trait Features: 
- **Higher-Rank Trait Bounds (HRTB)**
- **Trait Objects with multiple traits**
- **Trait aliases**  (nightly)
- **Specialization** (nightly)

Allows more specific trait impls to override more general ones.

```rust
default fn do_thing(&self) {
    println!("Default");
}
```

HRTB: Used when a trait must work for **all lifetimes**.

```rust
fn do_something<F>(f: F)
where
    F: for<'a> Fn(&'a str),
{
    f("hello");
}
```


Currently **unstable**, only available with nightly Rust.

### 12. Common Standard Library Traits:
- `From`/`Into` : for conversions 
- `Deref`/`DerefMut` for smart pointers 
- `Drop` for destructors 
- `Iterator` for collections 
- `Display`/`Debug` for formatting

### 13. Trait Coherence and Orphan Rules
- Where traits can be implemented
- Avoiding conflicting implementations

What is Orphan Rule?

Rust doesn’t allow you to implement **foreign traits on foreign types**.

```rust
// Not allowed:
impl Display for Vec<u8> {} // Both Display and Vec are foreign
```

Only allowed if:

* You own the trait
* Or you own the type

### 14. Trait Objects and Object Safety
- Requirements for trait objects
- `Sized` considerations


### 15. Blanket Implementations

Useful for applying traits to **all types meeting a condition**:

```rust
trait Printable {
    fn print(&self);
}

impl<T: Debug> Printable for T {
    fn print(&self) {
        println!("{:?}", self);
    }
}
```

This makes **all `T: Debug` types** also implement `Printable`.


### 16. Implementing Traits for External Types:

Wrap the external type in a **newtype**"

```rust 
struct MyVec(Vec<u8>); // this is tuple struct
impl Printable for MyVec {
    fn print(&self) {
        println!("{:?}",self.0 );
    }
}
```
full example:

```rust 

struct Manu {
    name: String,
}

// since rust prevents to define global string directly
struct Msg(String); // we put the string inside a tuple struct

trait Hariom {
    fn speak(&self);
}

impl Hariom for Manu {
    fn speak(&self) {
        println!("{}Hari Om Tat Sat", self.name);
    }
}
impl Hariom for Msg {
    fn speak(&self) {
        println!("Encoded message : {}", self.0); // self.0 is to reach the elements inside tuple
                                                  // struct
    }
}
fn main() {
    let manu = Manu {
        name: "manush".to_string(),
    };
    manu.speak();
    let x = Msg("Hello from Rust".to_string());
    x.speak();
}
```

### 17. Test Traits (Mocking, etc.)

You can use traits to write **mockable** and **testable** code by abstracting behavior.

```rust
trait Database {
    fn query(&self, sql: &str) -> String;
}
```

Then in tests:

```rust
struct MockDb;

impl Database for MockDb {
    fn query(&self, _: &str) -> String {
        "mock result".into()
    }
}
```

Summary Table

| Concept           | Description                                         |
| ----------------- | --------------------------------------------------- |
| Traits            | Define shared behavior                              |
| `impl Trait`      | Abstract parameters and return types                |
| Trait Bounds      | Restrict generic types                              |
| Trait Objects     | Runtime polymorphism                                |
| Default Methods   | Shared default implementations                      |
| Associated Types  | Define internal type placeholders                   |
| Supertraits       | Require one trait to implement another              |
| Blanket Impls     | Apply trait to all types matching condition         |
| Orphan Rule       | Prevents implementing foreign trait on foreign type |
| Auto Traits       | Built-in marker traits                              |
| Procedural Macros | Auto-implement traits with custom macros            |
...

## Complete Example: 

```rust 
use std::fmt::Display;

//Basic trait with default implementation 
trait Animal: Display { 
    fn name(&self) -> &str;

    fn make_sound(&self) -> String {
        "Some generic animal sound!!".to_string()
    }

    // Associated function 
    ////fn animal_type() -> String {
    ////    "Animal".to_string()
    ////}
    /* Comment this error as the above trait is not object safe 
        Object Safe requiers: 
        - All methods called on the trait object must have receiver (self, &self, or &mut self)
        - No generic methods 
        - No methods that return `Self` ( the concrete implementor type).
        - No associated functions (static methods) that you might try to call on the trait object.
       
    */
}

//Supertrait
trait Pet: Animal {
    fn owner(&self) -> &str;
}

struct Dog {
    name: String,
    owner: String,
}

impl Display for Dog {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "Dog: {} (owned by {})", self.name, self.owner)
    }
}

impl Animal for Dog {
    fn name(&self) -> &str {
        &self.name 
    }

    // fn make_sound(&self) -> String {
    //    "Woof!".to_string()
    //}
}

impl Pet for Dog {
    fn owner(&self) -> &str {
        &self.owner 
    }
}

//Generic Function with trait bounds:
fn introduce<T: Pet>(pet:&T) {
    println!("This is {}, owned by {}", pet.name(), pet.owner());
    println!("It says: {}", pet.make_sound());
}

// Trait objects for dynamic dispatch
fn process_animals(animals: &[&dyn Animal]) {
    for animal in animals {
        println!("{} - {}", animal, animal.make_sound());
    }
}

fn main() {
    let dog = Dog {
        name: "Buddy".to_string(),
        owner: "Alice".to_string(),
    };

    introduce(&dog);

    let animals: Vec<&dyn Animal> = vec![&dog];

    let animals: Vec<&dyn Animal> = vec![&dog];
    process_animals(&animals);
}
```


## Key Concepts to Remember

1. **Trait Bounds**: Compile-time polymorphism with monomorphization
2. **Trait Objects**: Runtime polymorphism with dynamic dispatch
3. **Object Safety**: Traits must not return `Self` or use generic methods to be object-safe
4. **Coherence Rules**: You can only implement traits for types you own
5. **Zero-Cost Abstractions**: Traits provide abstraction without runtime overhead

Traits are fundamental to Rust's type system and enable much of the language's safety, performance, and expressiveness.

## References:
---------------------------------------------------------------------------------- 
1. Interfaces: ( CPP )
Interfaces in C++
=================

In C++, an interface is a class that contains only pure virtual functions and no data members. 
It is used to define a contract that must be implemented by any class that inherits from it. 
Interfaces are useful for defining a common set of methods that must be implemented by a group of related 
classes.

**Example: Shape Interface**
---------------------------

    ```cpp
        // shape.h
        #ifndef SHAPE_H
        #define SHAPE_H

        class Shape {
        public:
            // Pure virtual function to calculate area
            virtual double area() = 0;

            // Pure virtual function to calculate perimeter
            virtual double perimeter() = 0;

            // Virtual destructor to ensure proper cleanup
            virtual ~Shape() {}
        };

        #endif  // SHAPE_H
    ```

In this example, the `Shape` class is an interface that defines two pure virtual functions: `area()` 
and `perimeter()`. 

These functions must be implemented by any class that inherits from `Shape`.

**Implementing the Interface: Circle and Rectangle**
---------------------------------------------------

    ```cpp
        // circle.h
        #ifndef CIRCLE_H
        #define CIRCLE_H

        #include "shape.h"

        class Circle : public Shape {
        private:
            double radius_;

        public:
            Circle(double radius) : radius_(radius) {}

            // Implement the area() function
            double area() override {
                return 3.14159 * radius_ * radius_;
            }

            // Implement the perimeter() function
            double perimeter() override {
                return 2 * 3.14159 * radius_;
            }
        };

        #endif  // CIRCLE_H
    ```

    ```cpp
        // rectangle.h
        #ifndef RECTANGLE_H
        #define RECTANGLE_H

        #include "shape.h"

        class Rectangle : public Shape {
        private:
            double width_;
            double height_;

        public:
            Rectangle(double width, double height) : width_(width), height_(height) {}

            // Implement the area() function
            double area() override {
                return width_ * height_;
            }

            // Implement the perimeter() function
            double perimeter() override {
                return 2 * (width_ + height_);
            }
        };

        #endif  // RECTANGLE_H
    ```

The `Circle` and `Rectangle` classes inherit from the `Shape` interface and implement the `area()` and 
`perimeter()` functions.

**Using the Interface**
-----------------------

    ```cpp
        // main.cpp
        #include "circle.h"
        #include "rectangle.h"

        int main() {
            Circle circle(5.0);
            Rectangle rectangle(3.0, 4.0);

            Shape* shapes[] = {&circle, &rectangle};

            for (Shape* shape : shapes) {
                std::cout << "Area: " << shape->area() << std::endl;
                std::cout << "Perimeter: " << shape->perimeter() << std::endl;
                std::cout << std::endl;
            }

            return 0;
        }
    ```

we create an array of `Shape` pointers and store the addresses of `Circle` and `Rectangle` objects. 
iterate over the array and call the `area()` and `perimeter()` functions on each object, without knowing 
the actual type of the object.

This demonstrates the power of interfaces in C++, which allow us to write generic code that can work with  
a variety of classes that implement a common interface.
---------------------------------------------------------------------------------- 
