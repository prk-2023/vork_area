use std::intrinsics::sqrtf32;

fn main() {
    //Immutable variables

    let x = 5;

    println!("the value of x = {}", x);

    //Mutable variables
    let mut y = 10;
    //.powi(4) raises to the power of 4
    y = (y as f64).powi(4) as i32; // Raise to the power of 4 and cast back to i32
    println!("y raised to the power of 4: {}", y); // Output the result

    y = (y as f64).sqrt() as i32;
    println!("value of y after sqrt {}", y);
}
