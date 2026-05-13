# Iterators in Rust

Iterators are one of the most important “real-world Rust” concepts because they show how **traits + generics + ownership** come together.

---

# 1. What is an Iterator?

An iterator is something that lets you:

```text 
produce values one at a time
```

Instead of working with all data at once, you process it step-by-step.

---

# 2. Simple Mental Model

```text 
Iterator = "a machine that yields values one by one"
```

Like:

* a conveyor belt
* a stream of data
* a cursor over a collection

---

# 3. The Core Trait: `Iterator`

In Rust, iterators are defined using a trait:

```rust 
trait Iterator {
    type Item;

    fn next(&mut self) -> Option<Self::Item>;
}
```

Key ideas:

* `Item` = what it produces
* `next()` = gives the next value or ends

---

# 4. Example: Manual Iterator Behavior

Conceptually:

```text 
next() → Some(value)
next() → Some(value)
next() → None
```

---

# 5. First Real Example

```rust 
let v = vec![1, 2, 3];
```

We can iterate:

```rust 
for x in v {
    println!("{}", x);
}
```

---

# 6. What is happening under the hood?

The `for` loop actually uses iterators.

This:

```rust 
for x in v
```

is transformed into something like:

```rust 
let mut iter = v.into_iter();

while let Some(x) = iter.next() {
    println!("{}", x);
}
```

---

# 7. Iterator Methods Come from Traits

When you call:

```rust 
v.iter()
v.into_iter()
v.iter_mut()
```

you are using methods defined by traits.

---

# 8. Three Ways to Iterate

## 1. `iter()`

```rust id="1m7v8q"
for x in v.iter()
```

* borrows values
* does NOT consume vector

---

## 2. `into_iter()`

```rust id="8v1m5q"
for x in v.into_iter()
```

* takes ownership
* consumes the vector

---

## 3. `iter_mut()`

```rust id="3v9m2q"
for x in v.iter_mut()
```

* gives mutable references
* allows modification

---

# 9. Ownership Perspective (Very Important)

| Method        | Ownership                 |
| ------------- | ------------------------- |
| `iter()`      | borrows (`&T`)            |
| `iter_mut()`  | mutable borrow (`&mut T`) |
| `into_iter()` | takes ownership (`T`)     |

---

# 10. Iterator Adapter Chain (Power Feature)

Rust allows chaining operations:

```rust id="6v8m2q"
let v = vec![1, 2, 3, 4];

let result: Vec<i32> = v
    .iter()
    .map(|x| x * 2)
    .filter(|x| x > &5)
    .collect();
```

---

# 11. Mental Model

```text id="5m9v1q"
Iterator pipeline = data transformation flow
```

Like:

* Unix pipes (`|`)
* functional programming streams

---

# 12. What is `map()`?

```rust id="7v3m8q"
.map(|x| x * 2)
```

Means:

```text id="4v2m9q"
transform each element
```

---

# 13. What is `filter()`?

```rust id="8m1v7q"
.filter(|x| x > &5)
```

Means:

```text id="2v8m5q"
keep only elements that satisfy condition
```

---

# 14. What is `collect()`?

```rust id="9m7v1q"
.collect()
```

Means:

```text id="6v2m8q"
convert iterator back into a collection
```

Example:

```rust id="3m8v5q"
let v: Vec<_> = iterator.collect();
```

---

# 15. Lazy Evaluation (Very Important Concept)

Iterators are:

```text id="7v4m1q"
lazy
```

Meaning:

* nothing happens until needed

Example:

```rust id="1v9m2q"
let iter = v.iter().map(|x| x * 2);
```

Nothing runs yet.

Only when:

* `collect()`
* `for loop`
* `next()`

---

# 16. Why Rust Uses Lazy Iterators

Because it enables:

* performance optimization
* zero unnecessary allocations
* chaining transformations efficiently

---

# 17. Iterator vs Loop

| Feature     | Loop       | Iterator   |
| ----------- | ---------- | ---------- |
| style       | imperative | functional |
| flexibility | low        | high       |
| chaining    | no         | yes        |
| laziness    | no         | yes        |

---

# 18. Real Example Pipeline

```rust id="2m9v8q"
let nums = vec![1, 2, 3, 4, 5];

let result: Vec<i32> = nums
    .into_iter()
    .filter(|x| x % 2 == 0)
    .map(|x| x * 10)
    .collect();
```

Result:

```text id="8v7m1q"
[20, 40]
```

---

# 19. Custom Iterator (Advanced but Important)

You can build your own iterator.

---

## Example

```rust id="5m8v2q"
struct Counter {
    current: u32,
}
```

Implement iterator:

```rust id="7v1m9q"
impl Iterator for Counter {
    type Item = u32;

    fn next(&mut self) -> Option<Self::Item> {
        self.current += 1;

        if self.current <= 5 {
            Some(self.current)
        } else {
            None
        }
    }
}
```

---

## Usage

```rust id="3v8m5q"
let mut counter = Counter { current: 0 };

for num in counter {
    println!("{}", num);
}
```

---

# 20. Iterator Design Insight

Iterator is just:

```text id="6m4v1q"
a state machine producing values
```

---

# 21. Relationship with Traits

Iterators depend heavily on traits:

* `Iterator` trait
* `IntoIterator`
* `FromIterator`
* `Fn` traits (for closures)

---

# 22. Closures in Iterators

Example:

```rust id="9v3m1q"
.map(|x| x + 1)
```

Closures are anonymous functions used heavily in iterator pipelines.

---

# 23. Real-world Use Cases

Iterators are used for:

* processing data
* parsing files
* transformations
* filtering logs
* database-like operations in memory

---

# 24. Common Beginner Confusion

---

## ❌ “Iterator runs immediately”

Wrong.

---

## ✔ Correct

```text id="4v8m2q"
Iterator only runs when consumed
```

---

## ❌ “Iterator modifies data directly”

Wrong.

---

## ✔ Correct

```text id="7m1v8q"
Iterator produces transformed views of data
```

---

# 25. Big Picture

Iterators combine:

* traits
* generics
* closures
* ownership
* laziness

into one powerful abstraction.

---

# 26. Final Mental Model

```text id="5v9m2q"
Iterator = lazy pipeline that produces values one at a time
```

---

# Where we are now

You now understand:

* traits
* generics
* trait bounds
* lifetimes
* iterators

These are the core pillars of Rust.

---

Next topic:

```text 
Async / Await (and the Future trait)
```

This is where Rust moves from:

* synchronous iteration
  to
* concurrent asynchronous execution

Say **go ahead** when ready.
