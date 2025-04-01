---
title: "borrow-lambda"
sub_title: "A simplified Rust-like borrow checker"
authors: 
    - Jeff Zhang
    - Taran Dwivedula
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

<!-- end_slide -->

Consider the following Rust code
===

What does this print?

```rust
fn main() {
    let mut nums = vec![1, 2, 3];
    let num = &mut nums[2];
    nums.push(4);
    println!("{}", *num);
}
```


