---
title: "borrow-lambda"
sub_title: "A simplified Rust-like borrow checker"
authors: 
    - Jeff Zhang
    - Taran Dwivedula
theme:
    name: catppuccin-mocha
---

Consider the following C++ code
===

What does this print?

```cpp
int main() {
    std::vector<int> nums = {1, 2, 3};
    int *num = &nums[2];
    nums.push_back(4);
    std::cout << *num << std::endl;
}
```

<!-- pause -->

Answer: undefined behavior!

```bash
🪷 borrow_lambda on  main 
❯ g++ test.cpp

🪷 borrow_lambda on  main 
❯ ./a.out
-1894668746

🪷 borrow_lambda on  main 
❯ ./a.out
-2120099788

🪷 borrow_lambda on  main 
❯ ./a.out
1710462087
```

<!-- end_slide -->

Consider the following Rust code
===

What does this print?

```rust
fn main() {
    let mut nums = vec![1, 2, 3];
    let num = &nums[2];
    nums.push(4);
    println!("{}", *num);
}
```

<!-- pause -->

Answer: compile error :)
```bash
🪷 borrow_lambda on  main [1]
❮ rustc foo.rs
error[E0502]: cannot borrow `nums` as mutable because it is also borrowed as immutable
 --> foo.rs:4:5
  |
3 |     let num = &nums[2];
  |                ---- immutable borrow occurs here
4 |     nums.push(4);
  |     ^^^^^^^^^^^^ mutable borrow occurs here
5 |     println!("{}", *num);
  |                    ---- immutable borrow later used here

error: aborting due to 1 previous error

For more information about this error, try `rustc --explain E0502`.
```

<!-- end_slide -->

Why borrow checking? (background)
===

<!-- end_slide -->

Borrow checking overview
===

# 1. Ownership 

# 2. Borrowing 

# 3. Lifetimes


<!-- end_slide -->

Ownership
===

- Rust's ownership is an implementation of something called an *affine type system*. What this means is that values can only be used at most once.
- This is a particular instance of the more general concept of **substructural type systems**. (elaborate)

<!-- end_slide -->

Borrowing
===

<!-- end_slide -->

Lifetimes
===

<!-- end_slide -->


Implementation
===

<!-- end_slide -->

Demo
===

<!-- end_slide -->

Conclusion and further improvements
===

<!-- end_slide -->
