# Smart Pointers:

**smart pointers** in C++ — what they are, why they're important, and the different types available.

---

## 🧠 What Are Smart Pointers?

**Smart pointers** are objects that **manage memory automatically**. 

They're wrappers around raw pointers that ensure dynamically allocated memory is correctly released when 
it's no longer needed. This helps avoid:

- **Memory leaks** (forgetting to `delete`)
- **Dangling pointers** (using memory after it’s freed)
- **Double deletes**
- **Manual memory management errors**

Smart pointers live in the `<memory>` header.

---

## 🌟 Types of Smart Pointers in C++

### 1. `std::unique_ptr<T>`

- **Exclusive ownership**: Only one `unique_ptr` can own a resource.
- Automatically deletes the object when it goes out of scope.
- Cannot be copied, only **moved**.

#### Example:
```cpp
std::unique_ptr<int> up = std::make_unique<int>(10);
// std::unique_ptr<int> up2 = up; // ❌ Error! Cannot copy.
std::unique_ptr<int> up2 = std::move(up); // ✅ OK
```

#### Use Case:
- When you want one owner and clear ownership semantics (no sharing).

---

### 2. `std::shared_ptr<T>`

- **Shared ownership** via **reference counting**.
- Object is deleted when the last `shared_ptr` is destroyed.

#### Example:
```cpp
std::shared_ptr<int> sp1 = std::make_shared<int>(20);
std::shared_ptr<int> sp2 = sp1; // reference count = 2
```

#### Use Case:
- When multiple parts of your program need access to the same resource.

---

### 3. `std::weak_ptr<T>`

- **Non-owning** reference to a `shared_ptr` object.
- Used to **observe** or **temporarily access** a shared object without affecting its lifetime.
- Prevents **circular references**.

#### Example:
```cpp
std::weak_ptr<int> wp = sp1;
if (auto sp3 = wp.lock()) {
    // Safe access
}
```

#### Use Case:
- Used with `shared_ptr` to avoid memory leaks from circular dependencies.

---

## 🔁 Comparison Table

| Feature          | `unique_ptr` | `shared_ptr` | `weak_ptr`    |
|------------------|--------------|--------------|---------------|
| Ownership        | Exclusive    | Shared       | None          |
| Reference Count  | No           | Yes          | Yes (non-owning) |
| Copyable         | ❌           | ✅           | ✅            |
| Moveable         | ✅           | ✅           | ✅            |
| Use Case         | One owner    | Many owners  | Observing, breaking cycles |

---

## 💡 Why Use Smart Pointers?

- **RAII (Resource Acquisition Is Initialization)**: Ensures resources are cleaned up automatically.
- **Cleaner code**: No need to `delete` manually.
- **Exception safety**: Memory is automatically released even when exceptions are thrown.

---

## Bonus: Custom Deleters

Smart pointers can use custom functions to delete objects.

```cpp
std::shared_ptr<FILE> file(fopen("test.txt", "r"), fclose);
```

This ensures `fclose` is called when `file` goes out of scope.

---

Let me know if you want examples using smart pointers in classes or real-world applications (like managing game objects, GUI elements, etc.).


---


`std::shared_ptr` is a smart pointer in C++ that manages the lifetime of a dynamically allocated 
object using **reference counting**. 

[ Reference counting is a mem management technique where each obj is keeps a count of 
  how many references (pointers) point to it. 
  - when a new reference is make the count increments
  - when a reference is destroyed or reset the count decreses.
  - when the count reaches zero the object gets automatically deleted. 
  In CPP "std::shared_ptr" ensures the object is only destroyed when no "shared_ptr" are pointing to it anymore.
  
  Example:
  #include <iostream>
  #include <memory>
  
  class MyClass {
  public:
    MyClass() { std::cout << "Constructor\n"; }
    ~MyClass() { std::cout << "Destructor\n"; }
  };
  
  int main() {
    std::shared_ptr<MyClass> ptr1 = std::make_shared<MyClass>();
    std::cout << "Use count after ptr1: " << ptr1.use_count() << "\n"; // 1

    {
        std::shared_ptr<MyClass> ptr2 = ptr1;
        std::cout << "Use count after ptr2: " << ptr1.use_count() << "\n"; // 2
    } // ptr2 goes out of scope

    std::cout << "Use count after ptr2 is out of scope: " << ptr1.use_count() << "\n"; // 1

    return 0;
  } // ptr1 goes out of scope, object is destroyed

  The above example shows how to query the reference count.
  ]

It is part of the C++11 standard and is defined in the `<memory>` header.

### Key Features

* Automatically deletes the managed object when the last `shared_ptr` that owns it is destroyed or reset.
* Can be copied and assigned — multiple `shared_ptr`s can share ownership of the same object.
* Keeps track of how many `shared_ptr`s share the ownership using an internal reference count.

### Basic Syntax

```cpp
#include <iostream>
#include <memory>

class MyClass {
public:
    MyClass() { std::cout << "Constructor\n"; }
    ~MyClass() { std::cout << "Destructor\n"; }
};

int main() {
    std::shared_ptr<MyClass> ptr1 = std::make_shared<MyClass>(); // ref count = 1
    {
        std::shared_ptr<MyClass> ptr2 = ptr1; // ref count = 2
    } // ptr2 goes out of scope, ref count = 1
    // ptr1 goes out of scope here, ref count = 0, object destroyed
}
```

### Functions and Use Cases

* `std::make_shared<T>(args...)`: Safely creates an object and its `shared_ptr`.
* `use_count()`: Returns the number of `shared_ptr` instances managing the object.
* `get()`: Returns the raw pointer.
* `reset()`: Releases the ownership (decrements count).
* `unique()`: Returns true if use count is 1.

### Pros

* Manages memory automatically — no manual `delete`.
* Good for shared ownership scenarios, e.g., graph structures, caches.

### Cons

* Slightly more overhead than `unique_ptr` due to reference counting.
* Can lead to **cyclic references** (memory leaks) if `shared_ptr`s refer to each other. Use `std::weak_ptr` to break cycles.

Would you like a visual diagram of how reference counting works with `shared_ptr`?
https://www.geeksforgeeks.org/shared_ptr-in-cpp/
