/*
 * The code does not compile:
 * Check the errors and verify with LSP
 */

//#[allow(unused_variables)]
#[allow(unused)]
fn main() {
    let s1 = String::from("hello Ownership");
    let s2 = s1; // Ownership of string s1 is transferred to s2,

    println!("{}", s2);
    //println!("{}", s1);
    //

    let ss1 = String::from("hello borrow ref");
    // Multiple immutable references is allowed;
    let ss2 = &ss1; //immutable borrow
    let ss3 = &ss1; //another immutable borrow

    // try to borrow immutable as mutable is not allowed
    //let ss4 = &mut ss1;

    let r1 = give_ownership(s2);
    println!("{}", r1);

    let mut ms1 = String::from("passing mutable string for editing");
    println!("{ms1}");
    give_ownership_borrows(&mut ms1);
    println!("{ms1}");

    //lifetime's
    let r;
    {
        let s = String::from("hello");
        r = &s; // r borrows s here
    } // s goes out of scope and is dropped here
      // comment the below as it generates error
      // println!("{}", r); // ERROR! r points to dropped memory
      //
      //Borrow checker conflict
    {
        let mut _newstr = String::from("new string");
        let r1 = &_newstr; /* immutable borrow */
        // let r2 = &mut newstr;  // cannot borrow as its already borrowed as immutable by r1
        // println!("{} {}", r1, r2);
        println!("{} ", r1);
    }
}

fn give_ownership(some_string: String) -> String {
    some_string // Ownership is returned
}
//Edit the mut borrow ref and pass over
fn give_ownership_borrows(s: &mut String) -> &mut String {
    s.push_str("!!!");
    s
}
