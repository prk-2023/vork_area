fn main() {
    const MMIO_ADDR: *mut u32 = 0x1000_0000 as *mut u32;
    unsafe {
        MMIO_ADDR.write_volatile(0xDEADBEEF);
        let val = MMIO_ADDR.read_volatile();
        println!("MMIO Read: 0x{:X}", val);
    }
}