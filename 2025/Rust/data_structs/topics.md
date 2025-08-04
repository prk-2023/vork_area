# Rust data structures:

- Integers
- Floats
- Boolean
- Character
- String
- Tuple
- Array
- Vector
- HashMap
- HashSet
- LinkedList
- Stack
- Queue
- BinaryHeap


To deeply understand *Rust data structures*, you’ll need to learn not only how to *use* them, but also how they behave in memory, their *ownership rules*, and *performance characteristics*. Here's a structured list of what to learn for each of the listed Rust data structures:

---

## *1. Integers*

### What to Learn:

* Signed vs unsigned: `i8`, `i16`, `i32`, `i64`, `i128`, `isize`, `u8`, etc.
* Overflow behavior: wrapping, panicking, saturating (`wrapping_add`, etc.)
* Type inference and casting (`as`)
* Bit manipulation (`<<`, `>>`, `&`, `|`, `^`, `!`)
* Literals (`0x`, `0b`, `1_000` syntax)

---

## *2. Floats*

### What to Learn:

* Types: `f32`, `f64`
* Precision and rounding issues
* Common methods: `.is_nan()`, `.abs()`, `.ceil()`, `.floor()`, `.powf()`
* Comparison quirks (`f32::EPSILON`, etc.)
* Casting and parsing (`parse::<f64>()`)

---

## *3. Boolean*

### What to Learn:

* `true`, `false`
* Logic operators: `&&`, `||`, `!`
* Usage in `if`, `match`, and control flow
* Short-circuiting behavior

---

## *4. Character (`char`)*

### What to Learn:

* Unicode scalar values
* `char` vs `u8` vs `str`
* Methods: `.is_alphabetic()`, `.is_numeric()`, `.to_ascii_uppercase()`, etc.
* Memory size: 4 bytes

---

## *5. String*

### What to Learn:

* `String` vs `&str`
* Ownership and borrowing rules
* UTF-8 encoding, indexing restrictions
* Common methods: `.push()`, `.push_str()`, `.split()`, `.replace()`, `.to_string()`
* Formatting: `format!`, `println!`
* Iterating over characters vs bytes
* Conversion: `from`, `into`, `as_str()`

---

## *6. Tuple*

### What to Learn:

* Declaration and destructuring
* Indexing: `tuple.0`, `tuple.1`
* Nesting and type inference
* Pattern matching
* Use cases in returning multiple values

---

## *7. Array*

### What to Learn:

* Fixed-size arrays: `[T; N]`
* Indexing and slicing
* Iteration and `for` loops
* `.len()`, `.iter()`, `.map()`
* Stack vs heap allocation

---

## *8. Vector*

### What to Learn:

* Declaration: `Vec<T>`, `vec![]`
* Mutability and dynamic resizing
* Common methods: `.push()`, `.pop()`, `.insert()`, `.remove()`, `.sort()`
* Iteration and `.iter()`, `.iter_mut()`, `.into_iter()`
* Borrowing rules: mutable vs immutable access
* Memory allocation

---

## *9. HashMap*

### What to Learn:

* Importing from `std::collections::HashMap`
* Creating and inserting (`insert`, `entry`)
* Accessing (`get`, `get_mut`)
* Ownership of keys/values
* Iterating with `.iter()`
* Hashing and custom types (`Hash`, `Eq`)
* Capacity and rehashing

---

## *10. HashSet*

### What to Learn:

* Importing and initialization
* Uniqueness of elements
* Set operations: `union`, `intersection`, `difference`, `is_subset`
* `contains`, `insert`, `remove`
* Hash and equality traits
* Iterating through elements

---

## *11. LinkedList*

### What to Learn:

* Importing from `std::collections::LinkedList`
* Doubly-linked list structure
* `.push_front()`, `.push_back()`, `.pop_front()`, `.pop_back()`
* Iteration
* Performance trade-offs vs `Vec`
* Use cases (rare in idiomatic Rust)

---

## *12. Stack*

### What to Learn:

* Not a built-in type — usually `Vec<T>` used as a stack
* `.push()`, `.pop()` for LIFO behavior
* Implementing custom stack if needed
* Ownership and borrowing rules

---

## *13. Queue*

### What to Learn:

* Not built-in — can use `VecDeque` from `std::collections`
* `.push_back()`, `.pop_front()` for FIFO
* Comparison with `Vec` and `LinkedList`
* Efficient amortized complexity

---

## *14. BinaryHeap*

### What to Learn:

* Min-heap vs max-heap (Rust’s default is max-heap)
* `.push()`, `.pop()`, `.peek()`
* Custom comparators via `Reverse` wrapper
* Heap sort and priority queues
* Efficiency and use cases

---

## Additional Concepts to Master:

* *Ownership, borrowing, and lifetimes*
* *Traits*: `Clone`, `Copy`, `Debug`, `Eq`, `Hash`, `PartialOrd`, etc.
* *Iterators and closures* for working with collections
* *Pattern matching* and destructuring

-----------------------------------------------------------------------

Learning Rust data structures involves not just understanding what they are, but also how Rust's unique concepts like *Ownership*, *Borrowing*, and *Lifetimes* interact with them, and how they are used in practical scenarios.

Here's a breakdown of what to learn for each topic:

---

## Rust Data Structures: Learning Roadmap

### Fundamental Concepts (Applies to all data types)

Before diving deep into individual data structures, ensure a solid grasp of these Rust fundamentals, as they heavily influence how you interact with data:

* *Ownership:*
    * What it is (single owner per value).
    * How ownership is transferred (moving).
    * How values are "dropped" when their owner goes out of scope.
    * The difference between stack and heap memory, and how ownership relates to memory management.
* *Borrowing (References):*
    * What references are (`&` and `&mut`).
    * Rules of references:
        * At any given time, you can have *either* one mutable reference *or* any number of immutable references.
        * References must always be valid.
    * How to use immutable references (`&T`) for read-only access.
    * How to use mutable references (`&mut T`) for read-write access.
    * The concept of "aliasing XOR mutability."
* *Lifetimes:*
    * What they are (compiler-checked guarantees about how long references are valid).
    * How the compiler infers simple lifetimes.
    * When explicit lifetime annotations are required (e.g., in function signatures or structs).
    * The `'static` lifetime.
* *Mutability (`mut` keyword):*
    * Understanding why data is immutable by default.
    * How `mut` allows modification.
* *Type Inference and Type Annotations:*
    * How Rust usually infers types.
    * When and why to use explicit type annotations.

---

### Primitive Data Types

These are the building blocks. Understand their characteristics, ranges, and basic operations.

#### Integers

* *Types:*
    * Signed (`i8`, `i16`, `i32`, `i64`, `i128`).
    * Unsigned (`u8`, `u16`, `u32`, `u64`, `u128`).
    * Architecture-dependent (`isize`, `usize` - important for indexing collections).
* *Ranges:* Understand the min and max values for each type.
* *Literals:* How to write integer literals (decimal, hexadecimal, octal, binary, byte).
* *Operations:*
    * Arithmetic (+, -, \*, /, %).
    * Integer overflow behavior (panics in debug, wraps in release).
    * Bitwise operations (&, |, ^, <<, >>).
* *Casting:* How to cast between integer types (`as` keyword), and the potential for data loss.

#### Floats

* *Types:* `f32` (single-precision), `f64` (double-precision).
* *Precision and Memory:* Trade-offs between `f32` and `f64`.
* *Literals:* How to write float literals.
* *Operations:*
    * Arithmetic (+, -, \*, /).
    * Floating-point precision issues (IEEE 754 standard).
    * `NaN` (Not a Number), `Infinity`, `-Infinity`.
    * Methods for checking these special values (`is_nan()`, `is_infinite()`).

#### Boolean

* *Type:* `bool`.
* *Values:* `true`, `false`.
* *Logical Operations:* `&&` (AND), `||` (OR), `!` (NOT).
* *Conditional Flow:* Usage in `if`, `else if`, `else`, and `match` expressions.
* *`Copy` trait:* `bool` implements `Copy`, meaning it's copied on assignment/function calls, not moved.

#### Character

* *Type:* `char`.
* *Nature:* Represents a single Unicode Scalar Value (4 bytes).
* *Literals:* Single quotes (`'a'`).
* *Unicode:* Understanding that Rust `char` is Unicode-aware, unlike some other languages where `char` is just a byte.
* *Methods:* Common `char` methods (e.g., `is_alphabetic()`, `to_uppercase()`).

---

### Collection Data Structures (Standard Library)

These are more complex and typically heap-allocated, meaning Ownership and Borrowing are paramount.

#### String (`String` and `&str`)

This is crucial and often a point of confusion for newcomers.

* *`String` (owned, growable, heap-allocated):*
    * Creation: `String::new()`, `String::from()`.
    * Mutability: `push_str()`, `push()`, `insert()`, `remove()`.
    * Ownership transfer.
    * Memory management (heap allocation, deallocation when dropped).
* *`&str` (string slice, borrowed, immutable):*
    * What it is (a view into a `String` or a string literal).
    * How it's created from `String` (`&my_string`).
    * String literals as `&'static str`.
    * Immutability.
    * Common methods for slicing, searching, and manipulating (`.len()`, `.chars()`, `.bytes()`, `.split()`).
* *UTF-8 Encoding:* Understanding that Rust strings are guaranteed to be valid UTF-8.
* *String vs. String Slice:* When to use which.
* *Converting between `String` and `&str`:* `as_str()`, `to_string()`, `to_owned()`.

#### Tuple

* *Nature:* Fixed-size collection of values of potentially *different* types.
* *Declaration:* `let my_tuple = (1, "hello", true);`
* *Accessing Elements:*
    * Dot notation by index: `my_tuple.0`, `my_tuple.1`.
    * Destructuring: `let (x, y, z) = my_tuple;`
* *Unit Type `()`:* The empty tuple, used for functions that don't return a meaningful value.
* *When to use:* Returning multiple values from a function, grouping related data without creating a `struct`.
* *`Copy` trait:* Tuples implement `Copy` *if all their elements implement `Copy`*.

#### Array

* *Nature:* Fixed-size collection of elements of the *same* type.
* *Declaration:* `let a = [1, 2, 3];`, `let b: [i32; 5] = [1, 2, 3, 4, 5];`, `let c = [0; 5];` (five zeros).
* *Accessing Elements:*
    * Indexing: `a[0]`.
    * Bounds checking (panics on out-of-bounds access).
    * `get()` method for safe, `Option`-returning access.
* *Immutability/Mutability:* `let mut a = [1, 2, 3]; a[0] = 5;`
* *Slice `&[T]` and `&mut [T]`:* How to get a slice (a view) of an array.
* *When to use:* When you know the exact size of the collection at compile time.
* *`Copy` trait:* Arrays implement `Copy` *if their element type implements `Copy`*.

#### Vector (`Vec<T>`)

* *Nature:* Growable, heap-allocated list of elements of the *same* type. Rust's most common dynamic array.
* *Creation:* `Vec::new()`, `vec![]` macro.
* *Common Operations:*
    * Adding elements: `push()`, `insert()`.
    * Removing elements: `pop()`, `remove()`.
    * Accessing elements: Indexing (`vec[index]`), `get()`.
    * Iterating: `iter()`, `iter_mut()`, `into_iter()`.
    * Length and capacity: `len()`, `capacity()`.
    * Resizing.
* *Ownership and Borrowing with `Vec`:* How elements are stored, and how mutable/immutable borrows of the `Vec` affect access to its elements.
* *When to use:* When you need a dynamic, ordered collection of a single type.

#### HashMap (`HashMap<K, V>`)

* *Nature:* Key-value store (hash map/dictionary). Unordered.
* *Creation:* `HashMap::new()`.
* *Core Operations:*
    * Insertion: `insert(key, value)`.
    * Retrieval: `get(&key)` (returns `Option<&V>`).
    * Checking existence: `contains_key()`.
    * Removal: `remove()`.
    * Iterating over key-value pairs (`.iter()`, `.keys()`, `.values()`).
* *Hashing and `Eq` Traits:* Keys must implement `Hash` and `Eq` (or `PartialEq`).
* *Entry API (`.entry()`):* For more complex insert-or-update logic (e.g., counting occurrences).
* *Collisions:* Basic understanding of how hash collisions are handled.
* *When to use:* When you need fast lookups by a key.

#### HashSet (`HashSet<T>`)

* *Nature:* Unordered collection of *unique* elements.
* *Creation:* `HashSet::new()`.
* *Core Operations:*
    * Insertion: `insert(value)`.
    * Checking membership: `contains(&value)`.
    * Removal: `remove()`.
    * Set operations: `union()`, `intersection()`, `difference()`, `symmetric_difference()`.
* *Hashing and `Eq` Traits:* Elements must implement `Hash` and `Eq` (or `PartialEq`).
* *When to use:* When you need to store unique items and perform set operations.

#### LinkedList (`LinkedList<T>`)

* *Nature:* Doubly-linked list.
* *Creation:* `LinkedList::new()`.
* *Core Operations:*
    * Adding elements: `push_front()`, `push_back()`.
    * Removing elements: `pop_front()`, `pop_back()`.
    * Iterating.
* *Performance Characteristics:*
    * O(1) insertion/removal at ends.
    * O(n) random access (not efficient for indexing).
    * Higher memory overhead compared to `Vec`.
* *Why it's less common in Rust:* Due to Rust's ownership rules, implementing a "safe" linked list is surprisingly complex (often requiring `Rc` and `RefCell` for shared mutable ownership), and `Vec` often performs better for most common use cases. Focus on understanding *why* it's hard in Rust.
* *When to use:* Rare in idiomatic Rust, mainly when you absolutely need constant-time insertion/deletion anywhere in the middle *and* don't need random access.

#### Stack (LIFO) and Queue (FIFO)

Rust's standard library doesn't have explicit `Stack` or `Queue` types. Instead, you learn how to implement these *behaviors* using existing collections.

* *Implementing a Stack (LIFO - Last In, First Out):*
    * Using `Vec<T>`: `push()` (add to top), `pop()` (remove from top).
    * Understanding the LIFO principle.
* *Implementing a Queue (FIFO - First In, First Out):*
    * Using `Vec<T>`: `push()` (add to back), `remove(0)` (remove from front - *inefficient, O(n)*).
    * Using `std::collections::VecDeque<T>` (Double-ended Queue): This is the preferred way in Rust for an efficient queue, as it offers O(1) `push_back()` and `pop_front()`.
    * Understanding the FIFO principle.

#### BinaryHeap (`BinaryHeap<T>`)

* *Nature:* A max-heap by default (priority queue). Elements are ordered such that the largest element is always at the root.
* *Creation:* `BinaryHeap::new()`.
* *Core Operations:*
    * Insertion: `push(value)` (adds to heap, maintains heap property).
    * Retrieval of max element: `peek()` (returns `Option<&T>`).
    * Removal of max element: `pop()` (removes root, re-heapifies).
* *Min-Heap:* How to create a min-heap using `std::cmp::Reverse` wrapper.
* *`Ord` Trait:* Elements stored in a `BinaryHeap` must implement the `Ord` trait (for total ordering).
* *When to use:* Priority queues, finding max/min elements quickly, graph algorithms (e.g., Dijkstra's).

---

### General Learning Approach for all Data Structures:

1.  *Understand the Abstract Data Type (ADT):* What problem does this structure solve? What are its fundamental operations? (e.g., for a stack: push, pop, peek).
2.  *Rust's Implementation:* How does Rust's standard library implement this ADT (or provide tools to implement it)?
3.  *Core Methods:* Learn the most commonly used methods for creation, insertion, deletion, access, and iteration.
4.  *Performance Characteristics (Big O Notation):* Understand the time complexity of common operations (e.g., O(1) for `Vec::push`, O(N) for `Vec::insert` at index 0).
5.  *Memory Layout:* Basic understanding of whether it's stack-allocated or heap-allocated, and its implications (Ownership, Borrowing).
6.  *Ownership and Borrowing Interactions:* How do Rust's core concepts apply when using this data structure? What are the common pitfalls or "borrow checker" errors you might encounter?
7.  *When to Use:* Identify the scenarios where each data structure is the most appropriate choice.
8.  *Practical Examples:* Write small programs that demonstrate the usage of each data structure.
9.  *Error Handling:* How do methods on these data structures return `Option` or `Result` for potential failures (e.g., `Vec::pop` returns `Option<T>`, `HashMap::get` returns `Option<&V>`).

By following this comprehensive approach, you'll not only understand what each Rust data structure is but also how to effectively and safely use them within the Rust ecosystem.
