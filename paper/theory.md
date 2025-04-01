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
\end{align*}
$$

$$
\begin{align*}
\text{Types } T ::= \text{nat} \ |\ \text{bool} \ |\ \text{unit} \ |\ T_{1} \to T_{2} \ |\ \&l\ T \ | \&l\ \text{mut }T
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
$$
\frac{\Gamma(x) = T \quad x \not\in \Delta}{\Gamma \vdash x : T \mid x}
$$
$$
\frac{\Gamma \mid \Delta \vdash t: \text{Nat} \mid \Delta'}{\Gamma \mid \Delta \vdash  \text{iszero }t : \text{Nat} \mid \Delta'}
$$
$$
\frac{\Gamma \mid \Delta \vdash t_{1}: \text{Bool} \mid \Delta_{1} \quad \Gamma \mid \Delta_{1} \vdash t_{2} : T \mid\Delta_{2} \quad \Gamma \mid \Delta_{1} \vdash t_{3} : T \mid \Delta_{3}}{\Gamma \mid \Delta \vdash \text{if $t_{1}$ then $t_{2}$ else $t_{3}$} : T \mid \Delta_{2} \cup \Delta_{3}}
$$

$$
\frac{\Gamma \mid \Delta \vdash t_{1} : T_{1} \mid \Delta_{1} \quad \Gamma,x : T_{1} \mid \Delta_{1} \vdash t_{2} : T_{2} \mid \Delta_{2}}{\Gamma\mid\Delta \vdash \text{let $x = t_{1}$ in $t_{2}$} : T_{2} \mid \Delta_{2}}
$$
$$
\frac{\Gamma \mid \Delta \vdash t :  T \mid \Delta' \quad \Gamma(x) = T}{\Gamma \mid \Delta \vdash x := t : \text{Unit} \mid \Delta' \setminus x}
$$
$$
\frac{\Gamma \mid \Delta \vdash t_{1} : T_{1} \to T_{2} \mid \Delta_{1} \quad \Gamma \mid \Delta_{1} \vdash t_{2} : T_{1} \mid \Delta_{2}}{\Gamma \mid \Delta \vdash t_{1} \ t_{2} : T_{2} \mid \Delta_{2}}
$$

### Lifetimes
$$
\begin{align*}
&\Lambda ::= \cdot | \Lambda, x: \alpha \\
\end{align*}
$$
(index of lifetime $\alpha$ in the context)
$$
\frac{\Gamma \vdash t : T_{1} \quad T_{1} <: T_{2}}{\Gamma \vdash t: T_{2}}
$$
$$
\frac{\alpha < \beta}{\Gamma \mid \Lambda \vdash \&\alpha\ T <: \&\beta\ T}
$$

$$
\frac{\Lambda(x) = \alpha}{\Gamma \mid \Delta \mid \Lambda \vdash \&x : \&\alpha\ T \mid \Delta}
$$
**Binding + evaluates to reference (no escaping)**
$$
\frac{\Gamma \mid \Delta \mid \Lambda \vdash t_{1} : T_{1} \mid \Delta_{1} \quad \Gamma,x : T_{1} \mid \Delta_{1} \mid \Lambda, x : |\Lambda|  \vdash t_{2} : \&\beta\ T_{2} \mid \Delta_{2} \quad \beta < \alpha}{\Gamma\mid\Delta \mid \Lambda \vdash \text{let $x = t_{1}$ in $t_{2}$} : \&\beta\ T_{2} \mid \Delta_{2}}
$$
**Binding + evaluating to some other value**
$$
\frac{\Gamma \mid \Delta \mid \Lambda \vdash t_{1} : T_{1} \mid \Delta_{1} \quad \Gamma,x : T_{1} \mid \Delta_{1} \mid \Lambda, x : |\Lambda|  \vdash t_{2} : T_{2} \mid \Delta_{2}}{\Gamma\mid\Delta \mid \Lambda \vdash \text{let $x = t_{1}$ in $t_{2}$} : T_{2} \mid \Delta_{2}}
$$
### References
https://www.cs.cmu.edu/~janh/courses/ra19/assets/pdf/lect04.pdf
