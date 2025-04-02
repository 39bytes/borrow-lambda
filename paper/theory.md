$$
\begin{align*}
\text{Terms } t ::= &x \ |\  \lambda x.t \ |\  t_{1}\ t_{2} \ |\ \&x \ |\ \&\text{mut }x \ |\ ^{*}x \\
&|\ \text{if $t_{1}$ then $t_{2}$ else $t_{3}$} \\
&|\ \text{let } x = t_{1} \text{ in } t_{2} \\
&|\ x := t \\
&|\ ^{*}x := t \\
&|\ \text{true} \\
&|\ \text{false} \\
&|\ \text{unit} \\
&|\ 0 \\
&|\ \text{pred }t \\
&|\ \text{succ }t \\
&|\ \text{iszero }t \\
&|\ \text{vec}(t_{1}, t_{2}, \dots t_{k}) \\
&|\ \text{get}(t_{1}, t_{2}) \\
&|\ \text{push}(t_{1}, t_{2}) \\
&|\ \text{pop}(t_{1}) \\
\end{align*}
$$

$$
\begin{align*}
&\text{Copyable Types } T_{c} ::= \text{nat} \ |\ \text{bool} \ |\ \text{unit} \ |\ \&l\ T \ \\
&\text{Movable Types } T_{m} ::= T_{1} \to T_{2} \ | \&l\ \text{mut }T\ | \ \text{NatVec} \\
&\text{Types } T = T_{c}\ |\ T_{m}
\end{align*}
$$

$$
\text{Lifetime }l = \alpha
$$
### Affine rules
$$
\begin{align*}
&\Delta ::= \cdot | \Delta, t \\
\end{align*}
$$
**Trivially copyable**
$$
\frac{\Gamma(x) = T_{c} \quad x \not\in \Delta}{\Gamma \vdash x : T_{c }\mid \cdot}
$$
**Move semantics**
$$
\frac{\Gamma(x) = T_{m} \quad x \not\in \Delta}{\Gamma \vdash x : T_{m} \mid \cdot, x}
$$
**is-zero**
$$
\frac{\Gamma \mid \Delta \vdash t: \text{Nat} \mid \Delta'}{\Gamma \mid \Delta \vdash  \text{iszero }t : \text{Nat} \mid \Delta'}
$$
**if then else**
$$
\frac{\Gamma \mid \Delta \vdash t_{1}: \text{Bool} \mid \Delta_{1} \quad \Gamma \mid \Delta_{1} \vdash t_{2} : T \mid\Delta_{2} \quad \Gamma \mid \Delta_{1} \vdash t_{3} : T \mid \Delta_{3}}{\Gamma \mid \Delta \vdash \text{if $t_{1}$ then $t_{2}$ else $t_{3}$} : T \mid \Delta_{2} \cup \Delta_{3}}
$$
**let... in...**

$$
\frac{\Gamma \mid \Delta \vdash t_{1} : T_{1} \mid \Delta_{1} \quad \Gamma,x : T_{1} \mid \Delta_{1} \vdash t_{2} : T_{2} \mid \Delta_{2}}{\Gamma\mid\Delta \vdash \text{let $x = t_{1}$ in $t_{2}$} : T_{2} \mid \Delta_{2}}
$$
**assignment**
$$
\frac{\Gamma \mid \Delta \vdash t :  T \mid \Delta' \quad \Gamma(x) = T}{\Gamma \mid \Delta \vdash x := t : \text{Unit} \mid \Delta' \setminus x}
$$
**application**
$$
\frac{\Gamma \mid \Delta \vdash t_{1} : T_{1} \to T_{2} \mid \Delta_{1} \quad \Gamma \mid \Delta_{1} \vdash t_{2} : T_{1} \mid \Delta_{2}}{\Gamma \mid \Delta \vdash t_{1} \ t_{2} : T_{2} \mid \Delta_{2}}
$$


### Lifetimes
**Definition of lifetime context**
$$
\begin{align*}
&\Lambda ::= \cdot | \Lambda, x: \alpha \\
\end{align*}
$$
**Subtyping**
$$
\frac{\Gamma \vdash t : T_{1} \quad T_{1} <: T_{2}}{\Gamma \vdash t: T_{2}}
$$
**Reference subtyping**
$$
\frac{\alpha < \beta}{\Gamma \mid \Lambda \vdash \&\alpha\ T <: \&\beta\ T}
$$
**Borrowing**
$$
\frac{\Lambda(x) = \alpha}{\Gamma \mid \Delta \mid \Lambda \vdash \&x : \&\alpha\ T \mid \Delta}
$$
**Binding + evaluates to reference (no escaping)**
$$
\frac{\Gamma \mid \Delta \mid \Lambda \vdash t_{1} : T_{1} \mid \Delta_{1} \quad \Gamma,x : T_{1} \mid \Delta_{1} \mid \Lambda, x : |\Lambda|  \vdash t_{2} : \&\beta\ T_{2} \mid \Delta_{2} \quad \beta < |\Lambda|}{\Gamma\mid\Delta \mid \Lambda \vdash \text{let $x = t_{1}$ in $t_{2}$} : \&\beta\ T_{2} \mid \Delta_{2}}
$$
**Binding + evaluating to some other value**
$$
\frac{\Gamma \mid \Delta \mid \Lambda \vdash t_{1} : T_{1} \mid \Delta_{1} \quad \Gamma,x : T_{1} \mid \Delta_{1} \mid \Lambda, x : |\Lambda|  \vdash t_{2} : T_{2} \mid \Delta_{2}}{\Gamma\mid\Delta \mid \Lambda \vdash \text{let $x = t_{1}$ in $t_{2}$} : T_{2} \mid \Delta_{2}}
$$
**Lambda abstraction no escaping borrows**
Let $C_{b}(t) = \{\alpha | x  \in FV(t)  \land \Gamma \vdash \&x : \&\alpha\ T \} \cup \{\alpha | x \in FV(t) \land \Gamma \vdash x: \&\alpha\  T\}$
???
$$
\frac{\Gamma \mid \Delta \mid \Lambda \vdash C_{b}(t) \subseteq \text{Im}(\Lambda)}{\Gamma \mid \Delta \mid \Lambda \vdash t : T_{1} \to T_{2}}
$$
**abstraction**
$$
\frac{\Gamma, x: T_{1} \mid \Delta  \mid \Lambda, x: |\Lambda| \vdash t : \& \beta\ T_{2} \mid \Delta' \quad \beta < |\Lambda| }{\Gamma \mid \Delta \mid \Lambda \vdash (\lambda x: T_{1}. t) : T_{1} \to \&\beta\ T_{2} \mid \Delta'}
$$
$$
\frac{\Gamma, x: T_{1} \mid \Delta  \mid \Lambda, x: |\Lambda| \vdash t : T_{2} \mid \Delta'}{\Gamma \mid \Delta \mid \Lambda \vdash (\lambda x: T_{1}. t) : T_{1} \to T_{2} \mid \Delta'}
$$
### References
https://www.cs.cmu.edu/~janh/courses/ra19/assets/pdf/lect04.pdf
