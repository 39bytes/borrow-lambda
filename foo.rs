struct A(u32);

fn main() {
    let a = vec![1, 2, 3];
    let b = &a;
    let c = *b;
    println!("{}", b[0]);
}
