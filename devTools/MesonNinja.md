# Meson  (ninja) Build system
---

- Meson is a open source build system which is designed to be both extreamly fast, and very user friendly.

- Supported langauges : Meson build system supports the following languages:
    C, C++, D, Fortran, Java, Rust.

- Meson Build definitions are very readable and user friendly and non turining complete DSL.

- Meson also supports Cross compilation of many operating systems as well as bare-metal.

- Meson is Optimized to be extremely fast and support full and incremental builds without sacrificing
  correctness.

- Approch of building:

    - Meson build are like a Meta build sub-system, where instead of building the code it-self, meson builds
      code for different build  system called ninja, and its ninja that actally compiles the code.

    - Ninja is a completely different style of build system, which is designed to be fast and efficient, but
      writing ninja build files are complex, this is where meson is used to build the ninja build files.


- It's a build system designed to optimize programmer productivity. It aims to do this by providing simple,
  out-of-the-box support for modern SW development tools and practices, such as unit  tests, coverage
  reports, Valgrind, Ccache and the like.

- The main Meson executable provides many subcommands to access all the functionality.

- Using Meson:
    Using meson is simple and follows a common two-phase process of most build system:

    1. First you run the meson to configure the build:
        $ meson setup [options] [build directory] [source directory]

    Note: the Build directory is different from the source directory, Meson does not support building in
    source directory.
    
    2. After successfully configuring the build we can build the soure with the build command in the build
       directory:
       $ meson -c build
       $ cd build ; ninja [target]

    The default build backend for meson is ninja which can be invoked as above.


    Meson configuration is required to run once when you configure your build directory. After which we run
    the build command, And meson will autodetect changes in the source directory and regenerate all files
    required to build the project.

- Compiling a Meson project:
    Most common use case of meson is compiling code on a code base you are working on. The steps are simple:
    - $ cd /path/to/source
    - $ meson setup builddir && cd builddir
    - $ meson compile ( or from src folder meson -C builddir )
    - $ meson test 

    ALL build and artifacts are stored in builddir. This allows us to have multiple build trees with
    different configurations at the same time. This way generated files can be excluded from revision
    control by accident.

    We can add "--buildtype=debugoptimized" when running Meson to build optimized biniries.

    Meson automatically add compiler flags to enable debug information and compiler warnings ( -g , -Wall ). 
- Setup command is the default and if no command is passed to meson, it defaults to setup command.

- configuration command : Meson configuration is a way to configure the project from cmd line.
    $ meson configure [builddir] [options to set]

  If build directory is omitted then the current directory is used instead.
  If no arguments are passed then meson configure will print the values of the build options to console.

  To set the values use -D cmd line arguments :
    $ meson configure -Dopt1=val1 -Dopt2=val2

- Test command: meson test is a helper tool for running test suites of projects using Meson.
The default way to run the test suite is to invoke the default build command 
    
    $ meson [test]

meson test provides a richer set of tools for invoking tests.

meson test automatically rebuilds the necessary targets to run tests when used with the  Ninja  backend.
Upon build  failure, meson test will return an exit code of 125.


## Example  project

- Fist create a basic prog: hello.c

    ```c 
    #include <stdio.h>
    int main (int argc, char **argv) {
        printf("Hello World!\n");
        return 0;
    }
    ```
- Create meson build description in a file named "meson.build" in the same directory:
    project('tutorial', 'c')
    executable('hello', 'hello.c')

Thats all. ( Unlike autotools we do not need to add any source headers to the list of sources ).

This is all and we are ready to build the project.

$ meson setup builddir

Followed by compiling the project:

$ cd builddir; ninja

Note: If we are using meson higher then 0.55 then we can use the new backend-agnostic build command:

    $ cd builddir ; meson compile


- Adding Dependencies: say we add some code that is dependent on other libs ( ex gtk ): this Dependencies
  can be added to the meson.build file as below:

    project('hello','c')
    gtkdep = dependency('gtk+-3.0')
    executable('hello','main.c', Dependencies: gtkdep)


