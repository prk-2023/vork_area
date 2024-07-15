# Cargo:

- Cargo is rust build system, package manager and more, it handles many tasks such as building code,
compiling, downloading the libs our code depends on and building libraries which are called depedencies.

- Cargo comes installed with rust and the version can be checked using --version cmd arg.

    $ cargo --version
    cargo 1.78.0 (54d8815d0 2024-03-26)

- Creating project: cargo is also used to create a project. 

```
    $ cargo new HelloWorld
    Creating binary (application) `HelloWorld` package
    warning: the name `HelloWorld` is not snake_case or kebab-case which is recommended for package names, consider `helloworld`
    note: see more `Cargo.toml` keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

    $ cd HelloWorld; tree
    .
    ├── Cargo.toml
    └── src
        └── main.rs

    2 directories, 2 files
```
