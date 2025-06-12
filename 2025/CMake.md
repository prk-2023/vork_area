# CMake Crash course:

Reference: https://www.youtube.com/watch?v=7YcbaupsY8I

1. How to install CMake
2. why use CMake?
3. QuickStart: How to use CMake to build a simple project.
4. How to use CMake Variables.
5. How to build Executables & libraries with CMake.
6. Internal Libraries: How to link libraries that are the part of the project.
7. How to use CMake with sub-directories in a project
8. How to include external libraries 


-------

### The below commands and Variables are used:


- CMake Commands Covered:
    - cmake_minimum_required
    - project
    - add_executable
    - add_library
    - add_subdirectory
    - target_include_directories
    - target_link_libraries
    - find_package
    - set 

- CMake Variables Covered:
    - PROJECT_NAME
    - CMAKE_CXX_STANDARD
    - CMAKE_CXX_STANDARD_REQUIRED
    - CMAKE_CXX_EXTENSION
    - STATIC ( used to build static libraries )
    - SHARED ( used to build shared libraries )
    - CMAKE_CURRENT_SOURCE_DIR 
    - PRIVATE / PUBLIC / INTERFACE ( to be used inside target_include_directories() )

### Installation:

- apt install cmake / dnf install cmake 

- cmake --version ( show cmake version thats installed )

### Introduction:

CMake is a build system generator-not a compiler itself, but its a tool to generate build files.
Build files such as Makefile, ninja files, Visual Studio project files for differentplatforms.

CMake helps us with:
    - Organize large C/C++ projects
    - Make the code more portable (microsoft/linux/macOS)
    - Generate dependencies
    - Generate native build files.


CMake WorkFlow:
    1. Write a "cmakeList.txt" file in your project directory.
    2. run "cmake" to configure your project and generate native build files.
    3. Run the native build tool  make or ninja  to compile the project.

Basic Example:

Build a simple "Hello, World!" in C++ with CMake:
---
project structure:

hello_cmake/
├── CMakeLists.txt
└── main.cpp

main.cpp:
#include <iostream>
---
int main() {
    std::cout << "Hello, CMake!" << std::endl;
    return 0;
}
---


====-=-=-=-=-=---------------------------------------------------

Sure! Let's get started with **CMake**, a powerful cross-platform tool used to manage the build process of software using **simple configuration files** called `CMakeLists.txt`.

---

### 🔹 What is CMake?

CMake generates native build files (like Makefiles or Visual Studio projects) from a simple project description. You write CMake config files once, and it can generate build systems for different environments.

---

## 🛠️ CMake Basics

### 1. 📁 Project Structure Example

```
my_project/
├── CMakeLists.txt
└── main.cpp
```

### 2. 📝 Simple `CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.10)
project(MyProject)

# Specify the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Add the executable
add_executable(my_app main.cpp)
```

### 3. 🧪 Simple `main.cpp`

```cpp
#include <iostream>

int main() {
    std::cout << "Hello from CMake!" << std::endl;
    return 0;
}
```

---

## 🚀 Build the Project

### Step-by-step:

```bash
mkdir build
cd build
cmake ..
make
./my_app
```

---

## 💡 Key CMake Concepts

| Concept                   | Description                                                |
| ------------------------- | ---------------------------------------------------------- |
| `project()`               | Sets the project name and optionally the version           |
| `add_executable()`        | Adds an executable target                                  |
| `add_library()`           | Adds a library target                                      |
| `target_link_libraries()` | Links libraries to your targets                            |
| `include_directories()`   | Adds include paths                                         |
| `find_package()`          | Looks for system-installed libraries (e.g., Boost, OpenGL) |

---

## 📦 Example: Add a Library

Project structure:

```
my_project/
├── CMakeLists.txt
├── main.cpp
└── math/
    ├── add.cpp
    ├── add.h
    └── CMakeLists.txt
```

Top-level `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.10)
project(MyProject)

add_subdirectory(math)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE mathlib)
```

`math/CMakeLists.txt`:

```cmake
add_library(mathlib add.cpp)
target_include_directories(mathlib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
```

---

## 🔄 Next Steps

Let me know what you'd like to explore next:

* Linking external libraries?
* CMake for multiple executables?
* Unit testing with CMake?
* Exporting CMake packages?
* CMake for Python/C++ projects?

Or I can give you exercises to try.


