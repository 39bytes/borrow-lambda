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

Why borrow checking?
===

Manual memory management (like in C) is performant, but very error prone. We use automatic memory management strategies to make programming easier.

<!-- pause -->

# Garbage Collection
- A second procedure whose job is to find unreachable values, and free their memory.
- Different strategies, each with pros and cons (ref cycles, fragmentation).
- Bottom line: we compromise performance for memory safety.

<!-- pause -->

# Borrow Checking
- A set of rules enforced during compile time that prevent common memory errors from being able to happen.
    - dangling pointer
    - use after free
    - double free
    - null dereference
- We can ensure our code is memory safe, without the runtime overhead of a garbage collector!

<!-- end_slide -->

History and Motivations
===
# Cyclone
- A research language from the early 2000s that was designed to provide memory safety to C.
- Main goal was to prevent vulnerabilities in C code (buffer overflow, incorrect typecasts, null pointer dereference) by attacking the semantics of the language itself.
- Introduces Regions to C: areas (scopes) where objects live and are deallocated simultaneously.
    - Region subtyping / "outlives" relation.
    - Prevents errors like null pointer dereferencing at compile time.
- A basis for Lifetimes, an important feature of the Rust borrow checker.
- Now a discontinued project, but many of Cyclone's features have been ported over to Rust.
- "Region-Based Memory Management in Cyclone" (Grossman et al. 2002)

<!-- pause -->

# Ownership Types
- Before Rust, ownership types were being studied as another way to enforce safe code.
- Ownership types manage resources (memory) by statically enforcing who can use or modify them.
- Popular in research on safety of concurrent programs.
    - "Ownership Types for Safe Programming: Preventing Data Races and Deadlocks" (Boyapati et al. 2002)
    - "Uniqueness and Reference Immutability for Safe Parallelism" (Gordon et al. 2012)
    - "'Use-Once' Variables and Linear Objects" (Baker 1994)
<!-- pause -->
<!-- newline -->
Today, Rust has the most mainstream and industry-standard implementation of a borrow checker.

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
