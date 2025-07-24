# Rust Modules System: Projects with multiple files 


In Rust, splitting code across multiple files is done using the *module system* with the `mod` and `use` 
keywords. 

Here’s a step-by-step guide for your project (`traffic_control`) to make the `main.rs` aware of other files 
(`models.rs`, `traits.rs`, `logic.rs`).


## Step-by-Step: Split Rust Code into Multiple Files

---

### 🔧 1. Project Structure

You already have this:

```
traffic_control/
├── Cargo.toml
└── src/
    ├── main.rs
    ├── models.rs
    ├── traits.rs
    └── logic.rs
```

Each of `models.rs`, `traits.rs`, and `logic.rs` is considered a *module* in the crate.

---

### 2. In `main.rs`, declare modules

```rust
// src/main.rs

mod models;
mod traits;
mod logic;

use models::Intersection;
use logic::DefaultCycle;

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
```

---

### 3. Each file becomes its own module

#### `src/models.rs`

```rust
#[derive(Debug, Clone, Copy)]
pub enum TrafficLight {
    Red,
    Green,
    Yellow,
}

#[derive(Debug)]
pub struct Intersection {
    pub id: u32,
    pub light: TrafficLight,
}
```

#### `src/traits.rs`

```rust
use crate::models::TrafficLight;

pub trait SignalCycle {
    fn next_light(current: TrafficLight) -> TrafficLight;
}
```

#### `src/logic.rs`

```rust
use crate::models::{Intersection, TrafficLight};
use crate::traits::SignalCycle;

pub struct DefaultCycle;

impl SignalCycle for DefaultCycle {
    fn next_light(current: TrafficLight) -> TrafficLight {
        match current {
            TrafficLight::Red => TrafficLight::Green,
            TrafficLight::Green => TrafficLight::Yellow,
            TrafficLight::Yellow => TrafficLight::Red,
        }
    }
}

impl Intersection {
    pub fn new(id: u32) -> Self {
        Self {
            id,
            light: TrafficLight::Red,
        }
    }

    pub fn cycle<T: SignalCycle>(&mut self, _logic: T) {
        self.light = T::next_light(self.light);
    }

    pub fn display(&self) {
        println!("Intersection {}: {:?}", self.id, self.light);
    }
}
```

---

## Key Concepts

| Concept          | Explanation                                                           |
| ---------------- | --------------------------------------------------------------------- |
| `mod xyz;`       | Declares a module (e.g., `xyz.rs` in the same dir)                    |
| `pub`            | Needed to make structs, enums, and functions visible to other modules |
| `use crate::...` | Access code from other modules using the crate path                   |

---

## Tips

* If you have a *subdirectory with many files*, use `mod xyz;` in `main.rs` and create a `xyz/mod.rs`.
* You can *nest modules* if needed, like:

i.e:

  ```
  src/
  ├── traffic/
  │   ├── mod.rs
  │   ├── lights.rs
  │   └── state.rs
  ```

  ```main.rs 

  mod traffic;
  use traffic::lights::TrafficLight;
  use traffic::state::Intersection;
  ```
