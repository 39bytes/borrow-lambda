# Trivially copyable types
```ocaml
let x = natvec_make(0, succ 0, succ (succ 0)) in 
let elem = natvec_get_mut(&mut x, succ 0) in 
natvec_push(&mut x, 0)
```

# Move semantics
```ocaml
let x = natvec_make(0, succ 0, succ (succ 0)) in
let y = x in
let z = x in
```

# Move into a closure
```ocaml
let x = natvec_make(0, succ 0, succ (succ 0)) in
let y = (\v. x) : unit -> natvec in
let z = x in
unit
```

# Conditional moves
```ocaml
let x = natvec_make(0, succ 0, succ (succ 0)) in
let y = (if true then x else natvec_make(0)) : natvec in
let z = x in
unit
```

# Borrows (lives long enough)
```ocaml
let x = 0 in
let y = 0 in
let z = (let b = &y in let c = &x in c) in
unit
```

# Borrows (doesn't live long enough)
```ocaml
let x = 0 in
let y = 0 in
let z = (let a = 0 in &a) in
unit
```

# Polymorphic functions
```ocaml
let x = succ 0 in 
let y = (\x. x) : &'a nat -> &'a nat in 
let k = succ (succ 0) in 
let z = y &k in 
unit
```

# Natvec example

```ocaml
let x = natvec_make(0, succ 0, succ (succ 0)) in 
let elem = natvec_get(&mut x, succ 0) in 
natvec_push(&mut x, 0)
```

# Popping
```ocaml
let x = natvec_make(0, succ 0, succ (succ 0)) in
let a = natvec_pop(&mut x) in
let b = natvec_pop(&mut x) in
let c = natvec_pop(&mut x) in
a
```
