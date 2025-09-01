Cross compilation 

1. Install aarch64 traget :
    Rust uses targets to specific architectures/platforms. 
    You can install the AArch64 Linux target with:

    `rustup target add aarch64-unknown-linux-gnu`

2. Install a cross-linker (gcc toolchain)
    https://copr.fedorainfracloud.org/coprs/lantw44/aarch64-linux-gnu-toolchain/

    To build a AArch64, you need a appropriate cross-compiler toolchain 
    A linker and C standard libraries for AArch64.

    sudo dnf install gcc-aarch64-linux-gnu

    or 
    dnf copr enable lantw44/aarch64-linux-gnu-toolchain
    dnf install aarch64-linux-gnu-{binutils,gcc,glibc}

3. Build using the target: With the target and linker installed you can now cross-compile as:

    `cargo build --target aarch64-unknown-linux-gnu`

    or release
    `cargo build --release --target aarch64-unknown-linux-gnu`

    


THis worked for me:

cargo build --release --target aarch64-unknown-linux-gnu --config=target.aarch64-unknown-linux-gnu.linker=\"aarch64-linux-gnu-gcc\"




