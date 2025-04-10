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
&|\ \text{natvec}(t_{1}, t_{2}, \dots t_{k}) \\
&|\ \text{get}(t_{1}, t_{2}) \\
&|\ \text{getmut}(t_{1}, t_{2}) \\
&|\ \text{push}(t_{1}, t_{2}) \\
&|\ \text{pop}(t_{1}) \\
\end{align*}
$$

$$
\begin{align*}
&\text{Lifetime }\kappa ::= \alpha \\
&\text{Mod } \mu ::= \text{mut} \mid \text{shr} \\
&\text{Non-Reference Types } T_{*} = \text{Nat} \mid \text{Bool} \mid \text{Unit} \mid \forall \alpha. T_{1} \to T_{2} \mid \text{NatVec} \\
&\text{Types } T = \&^{\kappa}_{\mu}\ T \mid T_{*}
\end{align*}
$$
$$
\text{Copy} = \{\text{Nat} , \text{Bool}, \text{Unit}, \&^{\kappa}_{\text{shr}}\ T\}
$$
### Affine rules
$$
\begin{align*}
&\Gamma ::= \cdot_{\Gamma} | \Gamma, x : T ; \alpha \\
&\Gamma(x) = T;\alpha \\
\end{align*}
$$
$$
\begin{align*}
&\Delta ::= \cdot_{\Delta} | \Delta \\
\end{align*}
$$
**Trivially copyable**
$$
\frac{\Gamma(x) = T \quad T \in \text{Copy}}{\Gamma \mid \Delta \vdash x : T\mid \Delta}
$$
**Move semantics**
$$
\frac{\Gamma(x) = T \quad x \not\in \Delta \quad T \not\in \text{Copy} \quad x_{\mu} \not\in B}{\Gamma \mid B \mid \Delta \vdash x : T \mid \Delta, x}
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
\frac{\Gamma \mid \Delta \mid B \vdash t :  T \mid \Delta' \quad \Gamma(x) = T \quad x_{\mu} \not\in B}{\Gamma \mid \Delta \mid B \vdash x := t : \text{Unit} \mid \Delta' \setminus x}
$$
**application**
$$
\frac{\Gamma \mid \Delta \vdash t_{1} : T_{1} \to T_{2} \mid \Delta_{1} \quad \Gamma \mid \Delta_{1} \vdash t_{2} : T_{1} \mid \Delta_{2}}{\Gamma \mid \Delta \vdash t_{1} \ t_{2} : T_{2} \mid \Delta_{2}}
$$

### Lifetimes
**Definition of function context**
"the variables bound in the current function body"
$$
\begin{align*}
&F::= \cdot_{F} | F, x\\
\end{align*}
$$
**Definition of live borrows context**
$$
B ::= \cdot _{B} \mid B, x_{\mu}
$$

**Subtyping**
$$
\frac{\Gamma \vdash t : T_{1} \quad T_{1} <: T_{2}}{\Gamma \vdash t: T_{2}}
$$
**Reference subtyping**
$$
\begin{align*}
&\frac{\alpha \leq \beta}{\Gamma \vdash \&^{\alpha}_{\mu}\ T <: \&^{\alpha}_{\mu}\ T} \\
\\
&\frac{\alpha \leq \beta}{\Gamma \vdash \&^{\alpha}_{\text{mut }} T <: \&^{\beta}_{\text{shr}}\ T}
\end{align*}
$$
**Borrowing**
$$
\begin{align*}
&\frac{\Gamma(x) = T, \alpha \quad x \not\in \Delta \quad x \in F \quad x_{\text{mut}} \not\in B}{\Gamma \mid F \mid B \mid \Delta \vdash \&x : \&^{\alpha}_{\text{shr}}\ T \mid \Delta \mid B, x_{\text{shr}}} \\
\\
&\frac{\Gamma(x) = \alpha \quad x \not\in \Delta \quad x \in F \quad x_{\mu} \not\in B}{\Gamma \mid F \mid B \mid \Delta \vdash \&\text{mut }x : \&^{\alpha}_{\text{mut}}\ T \mid \Delta \mid B, x_{\text{mut}}} \\
\\
&\frac{\Gamma \mid F \mid \Delta \vdash x : \&^{\alpha}_{\mu}\ T \mid \Delta' \quad T \in \text{Copy}}{\Gamma \mid F \mid  \Delta \vdash\ ^{*}x : T  \mid \Delta'}
\end{align*}
$$
**Binding + evaluates to reference (no escaping)**
$$
\frac{\Gamma \mid F \mid \Delta \mid B \vdash t_{1} : T_{1} \mid \Delta_{1} \mid B_{1} \quad \Gamma,x : T_{1} ; |\Gamma| \mid F,x \mid \Delta_{1} \mid B_{1} \vdash t_{2} : \&^{\beta}_{\mu} T_{2} \mid \Delta_{2} \mid B_{2} \quad \beta \leq |\Gamma|}{\Gamma \mid F \mid \Delta \mid B \vdash \text{let $x = t_{1}$ in $t_{2}$} : \&^{\beta}_{\mu}\ T_{2} \mid \Delta_{2} \mid B}
$$
Need to keep track of which references are borrowing which variables.
**Binding + evaluating to some other value**
$$
\frac{\Gamma \mid F \mid  \Delta \mid B \vdash t_{1} : T_{1} \mid \Delta_{1} \mid B_{1} \quad \Gamma,x : T_{1} ; |\Gamma| \mid F, x\mid \Delta_{1}  \vdash t_{2} : T_{*} \mid \Delta_{2} \mid B_{2}}{\Gamma \mid F \mid \Delta \vdash \text{let $x = t_{1}$ in $t_{2}$} : T_{*} \mid \Delta_{2} \mid B}
$$
**Lambda abstraction**
(escaping ref rule not needed, since all return types must be lifetime variables)
$$
\frac{\Gamma, x: T_{1}  ; |\Gamma| \mid \cdot_{F},x \mid \Delta  \vdash t : \&^{\beta}_{\mu}\ T_{2} \mid \Delta' \quad \beta < |\Gamma| }{\Gamma \mid F \mid  \Delta \vdash (\lambda x: T_{1}. t) : T_{1} \to \&^{\beta}_{\mu}\ T_{2} \mid \Delta'}
$$
$$
\frac{\Gamma, x: T_{1} ; |\Gamma| \mid \cdot_{F}, x \mid \Delta  \vdash t : T_{*} \mid \Delta'}{\Gamma \mid F \mid \Delta \vdash (\lambda x: T_{1}. t) : T_{1} \to T_{*} \mid \Delta'}
$$
**NatVec**
$$
\begin{align*}
&\frac{\Gamma \mid \Delta \vdash t_{1} : \text{Nat} \mid \Delta_{1} \quad \Gamma \mid \Delta_{1} \vdash t_{2} : \text{Nat} \mid \Delta_{2} \quad \dots \quad \Gamma \mid \Delta_{k-1} \vdash t_{k} : \text{Nat} \mid \Delta_{k}}{\Gamma  \mid \Delta \vdash \text{natvec}(t_{1}, t_{2},\dots t_{k}) : \text{NatVec} \mid \Delta_{k}} \\
\\
&\frac{\Gamma \mid \Delta \vdash t_{1} : \&^{\alpha}_{\mu}\ \text{NatVec} \mid \Delta_{1} \quad \Gamma \mid \Delta_{1} \vdash t_{2}:\text{Nat} \mid \Delta_{2}}{\Gamma \mid \Delta \vdash \text{get}(t_{1}, t_{2}) : \&^{\alpha}_{\text{shr}}\ \text{Nat} \mid \Delta_{2}} \\
\\
&\frac{\Gamma \mid \Delta \vdash t_{1} : \&^{\alpha}_{\text{mut}}\ \text{NatVec} \mid \Delta_{1} \quad \Gamma \mid \Delta_{1} \vdash t_{2}:\text{Nat} \mid \Delta_{2}}{\Gamma \mid \Delta \vdash \text{getmut}(t_{1}, t_{2}) : \&^{\alpha}_{\text{mut}}\ \text{Nat} \mid \Delta_{2}} \\
\\
&\frac{\Gamma \mid \Delta \vdash t_{1} : \&^{\alpha}_{\text{mut}}\ \text{NatVec} \mid \Delta_{1} \quad \Gamma \mid \Delta_{1} \vdash t_{2}:\text{Nat} \mid \Delta_{2}}{\Gamma \mid \Delta \vdash \text{push}(t_{1}, t_{2}) : \text{Unit} \mid \Delta_{2}} \\
\\
&\frac{\Gamma \mid \Delta \vdash t_{1} : \&^{\alpha}_{\text{mut}}\ \text{NatVec} \mid \Delta_{1} \quad \Gamma \mid \Delta_{1} \vdash t_{2}:\text{Nat} \mid \Delta_{2}}{\Gamma \mid \Delta \vdash \text{pop}(t_{1}, t_{2}) : \text{Nat} \mid \Delta_{2}} \\
\end{align*}
$$
### References
https://www.cs.cmu.edu/~janh/courses/ra19/assets/pdf/lect04.pdf
https://www.cs.cornell.edu/courses/cs4110/2018fa/lectures/lecture29.pdf
https://davidchristiansen.dk/tutorials/bidirectional.pdf
https://blog.ezyang.com/2013/05/the-ast-typing-problem/


(Jung et al. 2018) https://dl.acm.org/doi/10.1145/3158154
(Dang et al. 2019) https://dl.acm.org/doi/10.1145/3371102
