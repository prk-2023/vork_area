

Traits are the core ideas of Rust’s type system:

```text
Traits are Rust's universal capability system.
```

A type can:

* store data (`struct`)
* and gain capabilities through traits

Examples:

| Trait      | Meaning                         |
| ---------- | ------------------------------- |
| `Debug`    | printable                       |
| `Clone`    | clonable                        |
| `Iterator` | iterable                        |
| `Send`     | movable across threads safely   |
| `Sync`     | shareable across threads safely |

This design is what gives Rust:

* strong compile-time guarantees
* zero-cost abstractions
* flexible generic programming
* safe concurrency

The next concepts that usually become much easier after understanding traits are:

* generics
* trait bounds
* lifetimes
* iterators
* async/await (`Future` is also a trait)

