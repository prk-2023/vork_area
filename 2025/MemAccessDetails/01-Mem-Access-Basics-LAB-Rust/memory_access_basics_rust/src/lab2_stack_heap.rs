fn main() {
    let stack_var = 42;
    let heap_var = Box::new(84);
    println!("Stack var: {}, addr: {:p}", stack_var, &stack_var);
    println!("Heap var: {}, addr: {:p}", heap_var, &*heap_var);
}