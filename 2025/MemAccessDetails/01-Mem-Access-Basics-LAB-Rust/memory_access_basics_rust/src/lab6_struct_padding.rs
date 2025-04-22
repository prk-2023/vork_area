#[repr(C)]
struct Aligned {
    a: u8,
    b: u32,
}

#[repr(C, packed)]
struct Packed {
    a: u8,
    b: u32,
}

fn main() {
    println!("Size of Aligned: {}", std::mem::size_of::<Aligned>());
    println!("Size of Packed: {}", std::mem::size_of::<Packed>());
}