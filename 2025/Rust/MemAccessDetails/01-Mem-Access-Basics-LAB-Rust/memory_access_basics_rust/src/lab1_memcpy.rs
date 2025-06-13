//The below rust code does not compile if we do not specify the --target while building as there is
//a error below with "variable shadowing"
//Error: reference to packed field is unaligned
//This occurs when you're reading a field from a #[repr(packed)] struct directly, which Rust forbids
//for safety on unaligned access (especially important on AArch64, which doesn't tolerate it).
//Fix it by using ptr::read_unaligned instead of direct dereference:
//or refer to lab5_alignment.rs
//
//let ptr = &data.b as *const u32;
//println!("Misaligned read: 0x{:X}", *ptr); // ❌ Unsafe unaligned read
//
//change this to
//let ptr = &data.b as *const u32;
//let val = unsafe { std::ptr::read_unaligned(ptr) };
//println!("Misaligned read (safe-ish): 0x{:X}", val); // ✅ Correct unaligned read
//
//The problem is :
//The Problem: Variable Shadowing in the Same Scope
// let src = [1u8, 2, 3, 4, 5];
// ...
// let src = [10u8, 20, 30, 40, 50];  // ❌ Error: cannot redeclare `src`
//
// declaring src and dst twice in the same scope (main()),
// which causes a "cannot redeclare immutable variable" error.
// Rust doesn’t allow shadowing with let in the same block scope unless you explicitly want to shadow,
// usually within a smaller scope or by using {} blocks.
//
// To fix this :
// 1. use different variable names
// or
// 2. use another inner scope {} to isolate variables
//
fn main() {
    let src = [1u8, 2, 3, 4, 5];
    let mut dst = [0u8, 5];

    dst.copy_from_slice(&src);
    println!("Safe Copy file {:?}", dst);
    let src = [10u8, 20, 30, 40, 50];
    let mut dst = [0u8; 5];

    unsafe {
        std::ptr::copy_nonoverlapping(src.as_ptr(), dst.as_mut_ptr(), src.len());
    }
    println!("Unsafe copy (memcpy): {:?}", dst);
}
