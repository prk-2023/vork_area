#[repr(C, packed)]
struct Packed {
    a: u8,
    b: u32,
}

fn main() {
    let data = Packed { a: 1, b: 0xDEADBEEF };
    unsafe {
        let ptr = &data.b as *const u32;
        println!("Misaligned read: 0x{:X}", *ptr);
    }
}