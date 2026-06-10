# An ICON Package for Experimenting with Euclidean Domains

**Author:** Lars Warren Ericson  
**Institution:** Courant Institute of Mathematical Sciences, New York University  
**Report:** NYU Computer Science Technical Report #232  
**Date:** August 1986


## Abstract

For the purpose of understanding the algebraic algorithms over the Euclidean domain presented in the book of Lipson- [LipsoSla], a small package of routines (about 2000 lines of code) was written in ICON, a software prototyping language developed at the U. of Arizona [Grisw83a,Grisw83b]. This package allows the ICON user to write algorithms which apply to any object of a Euclidean domain, and supplies a paradigm for implementing new Euclidean domains. The package implements those Euclidean domains found in Lipson’s book. It turns out that the most difficult part of such a package is the implementation of div and mod for an arbitrary domain. This led the author to exploit a feature of Icon Version 5.10 [Grisw85a] (function call by string image of name) in order to implement a "by-hand" version of the sort of call by inheritance seen in Smalltalk [Ingal78a] and Scratchpad II [Balza84a]. The package may be of use to algebraic algorithm prototypers in the ICON community, or as an adjunct to a course on computer algebra.

---


## 1. Introduction


### 1.1. Programming with Euclidean domains

John Lipson’s book. Elements of Algebra and Algebraic Computing, presents a number of interesting symbolic algebraic algorithms, in a style which seems implementable. The only non-trivial implementation detail for the algorithms pfesepted by Lipson is that they assume div and mod operations which are defined on every. Euclidean domain (and, by implication, representations and definitions of these operations for every Euclidean domain). For example, consider his presentation of the FFT algorithm (p. 298);

<div class="math-left">

$$
\begin{array}{l}
\textbf{procedure } \text{FFT}(N, a(x), \omega, A); \\
\textbf{if } N = 1 \\
\textbf{then} \\
\quad \{ \text{Basis.} \} \ A_0 := a_0 \\
\textbf{else} \\
\textbf{begin} \\
\quad \{ \text{Binary split.} \} \\
\quad\quad n := N/2 \\
\quad\quad b(x) := \sum_{i=0}^{n-1} a_{2i} x^i \\
\quad\quad c(x) := \sum_{i=0}^{n-1} a_{2i+1} x^i \\
\quad \{ \text{Recursive calls.} \} \\
\quad\quad \text{FFT}(n, b(x), \omega^2, B) \\
\quad\quad \text{FFT}(n, c(x), \omega^2, C) \\
\quad \{ \text{Combine.} \} \\
\quad\quad \textbf{for } k := 0 \textbf{ until } n - 1 \textbf{ do} \\
\textbf{begin} \\
\quad\quad\quad A_k := B_k + \omega^k \otimes C_k \\
\quad\quad\quad A_{k+n} := B_k - \omega^k \otimes C_k \\
\quad\quad \textbf{end} \\
\textbf{end}
\end{array}
$$

</div>

The purpose of the package of routines described in this paper is to allow an ICON user to implement an algorithm such as FFT, at about the same level of description as above. By comparison, see Section 3.3.2, which contains our ICON version of the same procedure. 

In order to support a high level of description, it must be possible to describe the implementation of particular Euclidean domains, and to describe algorithms which apply generically to all Euclidean domain instances. We do this by deciding which functions are expected of all Euclidean domain implementations (say, div, mod, + and -), and then implementing a "dispatch" version of each of these. The "dispatch" div function inspects the type of its argument (say, integer, polynomial, quotient domain element or modular domain element), and then calls the associated div function in the domain implementation (say divjnteger, dlv_poly, dlv_Q or dlv_mod). 

The ability to test the run-time environment is a feature of ICON. Given a string, say "X", and an integer corresponding to a number of formal parameters, say 3, proc("X', 3) will return a procedure (a first-class value in ICON, assignable to variables) if the identifier X is globally to a procedure which is defined to take 3 arguments. Otherwise proc fails. To test for the procedure $\otimes_Z$, we evaluate procC'times" || "_Z", 2), and in general, for some string value X which corresponds to a procedure name, Y a domain name, and i a number of formal parameters, we evaluate proc(X || "_" Y, i), where || is the ICON string concatenation operator. For example, here is the code for the "generic" division operation:

<div class="math-left">

$$
\def\odiv{\mathbin{⨸}}
\odiv(a, b) \Leftarrow \Uparrow \text{proc}(\text{"div\_"}\,\|\|\,\text{type}(a), 2)(a, b) \ \blacksquare
$$

</div>

Every implementation of a Euclidean domain must supply certain required procedures. (This notion of "must" corresponds to the idea of a "category" in Scratchpad II.) Optional procedures may be supplied by the domain implementation, but are synthesized if not supplied. The following table lists required, optional and synthesized procedures. 

<p align="center"><strong>BASIC PROCEDURES FOR COMPUTING WITH DOMAINS</strong></p>

| *Type* | *Required* | *Optional* | *Synthesized* |
|:--|:-:|:-:|:-:|
| Constant | 0<br>1 | | |
| Operator | abs<br>$\oplus$<br>$-$<br>$\otimes$<br>$\odiv$ | mod<br>rem<br>normalize | $\ominus$<br>exp |
| Predicates | =<br>$<0$<br>unit<br>$=0$ | $<$ | $|$ |
| Commands | | print | pr<br>prs |

For a typical domain implementation, which serves as a model for other domain implementations, see for example Section 2.3.1, which describes our implementation of Quotient domains. 

A typical application is our implementation of Lipson’s algorithm (p. 264) for Newton Interpolation, seen in Section 3.3.3. 

## 1.2 A summary of package facilities for Euclidean domains

The domains supported are as follows:

<p align="center"><strong>EUCLIDEAN DOMAIN CONSTRUCTIONS</strong></p>

| | | |
|:--|:--|:--|
| **Primitive domains** | *integer* | Machine word integers |
| | *base*<sub>B</sub> | Arbitrary precision unsigned base B integers |
| | $\mathcal{Z}$ | Signed infinite precision integers |
| **Domain constructors** | $\mathcal{Q}$ | Quotient domain |
| | *modulo* | Modular domain |
| | *poly* | Polynomial domain |
| | *tpower* | Truncated power series domain |

The following are the representations in ICON we have adopted for objects in the Euclidean domains we support:

<p align="center"><strong>Domain representation</strong></p>

| | |
|:--|:--|
| *integer* | `integer` |
| *base*<sub>B</sub> | `record base_b (base, digits)` |
| *Z* | `record Z (sign, mantissa)` |
| *Q* | `record Q (dividend, divisor)` |
| *modulo* | `record modulo (item, modulus)` |
| *poly* | `record poly (terms)` |
| | `record term (coef, power)` |
| *tpower* | `record tpower (poly, N)` |

We have implemented the following application algorithms, which may be applied to objects from any Euclidean domain (unless otherwise noted):

<p align="center"><strong>Application Algorithms</strong></p>

| | |
|:--|:--|
| *GCD* | greatest common divisor |
| *EUCLID* | extended GCD |
| *MOD_RS* | polynomial remainder sequence for GCD |
| *PREM* | integral domain remainder |
| *E_PRS* | polynomial remainder sequence for PREM |
| *INVERSE* | inverse of $x \pmod y$ |
| *NIA* | Newton interpolation algorithm |
| *CRA2, CRA* | Chinese remainder algorithm for 2 or more<br>linear congruences |
| *FFT* | Fast Fourier Transform |
| *FFI* | Fast Fourier Interpolation |
| *NPSI* | Newton power series inversion for truncated power series |

The system as described is comprised of about 2000 lines of commented ICON code. Supposing that the code defined in the following sections is stored in a file, say euclid, then it may be executed in ICON by adding the statement link euclid to the application program, and then running the ICON translator. The author will gladly supply this code (as is) to any interested user. Mail to ARPA:ericson@nyu or UUCP:{floyd,ihnp4}!cmcl2!csdl!ericson for more information, or via U.S. Mail (with a 600 ft mag tape) to the address listed at the beginning of this report. (The offer last until the author gets sick of making tapes.)


### 1.3. Our typographical conventions for displaying ICON code

We have dressed up and compressed the syntax of ICON, to give the algorithms presented a more compact, functional appearance. 

Icon variables (simple names for single items, and procedure names) may appear as subscripted quantities. This is purely formal, not actual, subscripting. Also, some operator symbols are defined which would not be legal identifiers in ICON (because the characters don’t exist in ASCII). Rather than spelling them out, in this report we use the symbol we would have liked to use. The following are some examples of the original code and the fancier notation. Note that underscore ("_") is not a meta-character, but an ordinary character that may appear in identifiers in ICON. 

| **Original ICON** | **Fancy Notation** |
|:--|:--|
| `one_base_B` | $1_{base_B}$ |
| `delta_i_minus_1` | $\delta_{i-1}$ |
| `plus_poly` | $\oplus_{poly}$ |

For procedure definitions, instead of the obvious

```icon
procedure F (a, b. c)
  code
end
```

we use the logical-looking

$$
\text{F}(a, b, c) \Leftarrow \text{code} \ \blacksquare
$$

For `return x` we use $\Uparrow x$, and for `return` we use $\Uparrow$. Instead of `fail` we use $\bot$. All other ICON reserved words are bold-faced.


### 1.4. Afterthoughts

This code is no longer under development, and seems to be primarily of educational value. In the future, code such as this will be supplanted by far more capable systems such as Scratchpad H, as they become widely available and inexpensive. 

As an exercise, the author believes that the code addresses some of the essential software organization issues in computer algebra system design; if the code is to be applied in an educational setting, it would be well to stress to students several other important areas (these areas could form the basis of semester projects to extend the package):

* **Algorithm design.** For example, efficient polynomial greatest common divisor, which has seen many attempts to reduce its complexity. Zippel’s notes [Zippe86a] contain a good discussion of this problem.
* **Multivariate polynomials.** This code does not supply any of the several multivariate polynomial representations.
* **Explainability.** Algorithmic (as opposed to "deductive") systems do not explain themselves. An ideal system would supply a proof its conclusion.
* **Numeric-Symbolic Interface.** The results of some computations, for example, polynomial root-finding [Yap86a], are best expressed as numeric approximation intervals, even though they are defining "symbolic" quantities. More work needs to be done to automate the relationship between approximate versus exact computations.


## 2. Euclidean domains: representation and basic arithmetic


### 2.1. Generic arithmetic for Euclidean domains

Lipson’s book, p. 203, contains a significant proviso:

> We assume that our (Algol-like) language allows for the manipulation of values from an arbitrary Euclidean domain *D* with degree function *d*. In particular we assume that our language provides a *Division Algorithm* in the form of two operations “div” and $mod$ which return, respectively, a preferred quotient and remainder in accordance with the Division Property of a Euclidean domain...

 The purpose of this package is to partially implement this proviso. The package implements several primitive domains and *domain constructors*,which are classes of domains composed from other domains. 
 
 When a procedure like $\odiv$ or $mod$ is applied to an object which is an instance of a Euclidean domain, the type of the object is determined by inspection. This is either the primitive type, in the case of an instance of a primitive domain, or the type of the “outermost” constructor, in the case of an instance of a composite domain. In the case of required and optional procedures, the run-time environment is then tested to determine whether the domain implementation supplies an operation of this type. If the name of the domain is $D$, and the procedure name is $P$, then the run-time environment is tested for a procedure named $P_D$. For example, $\odiv$ applied to a quotient will look up the procedure $\odiv_Q$. Required procedures must be defined by the domain implementation, otherwise the operation fails. Implementation-optional procedures will synthesize their values if a more domain-specific implementation does not exist. 
 
**Constants.**
 
 A consequence of the existence of a variety of Euclidean domain instances is that there are a variety of structural representations for 0 and 1. In a given computation, the 0 or 1 used must be of the type of the domain instance. Hence to obtain the correct 0, we evaluate a 0 function which, given an object of the domain instance, returns the 0 of that domain, and similarly for 1.

<div class="math-left">

$$
\begin{array}{l}
\mathbf{0}(a) \Leftarrow \Uparrow \text{proc}(\text{"zero\_"}\,\|\,\text{type}(a), 1)(a) \ \blacksquare \\
\mathbf{1}(a) \Leftarrow \Uparrow \text{proc}(\text{"one\_"}\,\|\,\text{type}(a), 1)(a) \ \blacksquare
\end{array}
$$

</div>

**Operators.**

The following procedures define the basic arithmetic operations for domains. As noted in Table 1, every domain must supply Abs, $\oplus$, $-$, $\otimes$ and $\odiv$. $mod$, rem and normalize are optional, and $\ominus$ and exp are synthesized.

<div class="math-left">

$$
\begin{array}{l}
\text{Abs}(a) \Leftarrow \Uparrow \text{proc}(\text{"Abs\_"}\,\|\|\,\text{type}(a), 1)(a) \ \blacksquare \\
\oplus(a, b) \Leftarrow \Uparrow \text{proc}(\text{"plus\_"}\,\|\|\,\text{type}(a), 2)(a, b) \ \blacksquare \\
\ominus(a, b) \Leftarrow \Uparrow \oplus(a, -(b)) \ \blacksquare \\
- (x) \Leftarrow \Uparrow \text{proc}(\text{"minus\_"}\,\|\|\,\text{type}(x), 2)(x) \ \blacksquare \\
\otimes(a, b) \Leftarrow \Uparrow \text{proc}(\text{"times\_"}\,\|\|\,\text{type}(a), 2)(a, b) \ \blacksquare \\
\odiv(a, b) \Leftarrow \Uparrow \text{proc}(\text{"div\_"}\,\|\|\,\text{type}(a), 2)(a, b) \ \blacksquare \\
\text{mod}(a, b) \Leftarrow \\
\quad \textbf{if } (x := \text{proc}(\text{"mod\_"}\,\|\|\,\text{type}(a), 2)(a, b)) \textbf{ then } \Uparrow x \\
\quad \textbf{if } <(b, \mathbf{0}(b)) \textbf{ then } \Uparrow \text{mod}(a, -(b)) \\
\quad \Uparrow \text{normalize}( \\
\quad\quad \textbf{if } <(a, \mathbf{0}(a)) \\
\quad\quad \textbf{then } \oplus(a, \otimes(b, \oplus(\ominus(-(a), b), \mathbf{1}(a)))) \\
\quad\quad \textbf{else } \oplus(a, -(\otimes(b, \odiv(a, b)))) \\
\quad ) \ \blacksquare
\end{array}
$$

</div>

**Example.** The polynomials

$$
\begin{array}{c}
a(x) = x^3 - 2 \\
b(x) = 2x^2 - 3
\end{array}
$$

in the domain of quotients of machine-word integers are denoted within ICON by the record-constructor expressions and variable assignments

<div class="math-left">

$$
\begin{array}{l}
\textit{ax} := \text{poly}([\text{term}(\mathcal{Q}(-2,1), 0), \text{term}(\mathcal{Q}(1,1), 3)]) \\
\textit{bx} := \text{poly}([\text{term}(\mathcal{Q}(-3,1), 0), \text{term}(\mathcal{Q}(2,1), 2)])
\end{array}
$$

</div>

*pr*, a printing control structure, causes expressions to be printed out in a pleasing fashion. The ICON expression `pr{ax, " mod ", bx, " = ", mod(ax, bx)}` will print the following result:

$$
(-2)q + 1q \cdot X^3 \bmod (-3)q + 2q \cdot X^2 = (-2)q + \tfrac{3}{2}q \cdot X
$$

Similarly, given $c(x)=\tfrac{3}{2}x - 2$, represented as

<div class="math-left">

$$
\textit{cx} := \text{poly}([\text{term}(\mathcal{Q}(-2,1), 0), \text{term}(\mathcal{Q}(3,2), 1)])
$$

</div>

The result of evaluating `pr{bx, " mod ", cx, " = ", mod(bx, cx)}` is

$$
(-3)q + 2q \cdot X^2 \bmod (-2)q + \tfrac{3}{2}q \cdot X = \tfrac{5}{9}q
$$

<div class="math-left">

$$
\begin{array}{l}
\text{rem}(a, b) \Leftarrow \\
\quad \Uparrow (\textbf{if } (x := \text{proc}(\text{"rem\_"}\,\|\|\,\text{type}(a), 2)(a, b)) \textbf{ then } x \\
\quad\quad \textbf{else } \ominus(a, \otimes(\odiv(a, b), b))) \ \blacksquare
\end{array}
$$

</div>

**Example.** The polynomials

$$
\begin{array}{c}
a(x) = 5 - 2x + x^2 \\
b(x) = 2
\end{array}
$$

in the domain of quotients of machine-word integers are denoted with ICON by

<div class="math-left">

$$
\begin{array}{l}
\textit{ax} := \text{poly}([\text{term}(\mathcal{Q}(5,1), 0), \text{term}(\mathcal{Q}(-2,1), 1), \text{term}(\mathcal{Q}(1,1), 2)]) \\
\textit{bx} := \text{poly\_of}(\mathcal{Q}(2,1))
\end{array}
$$

</div>

The result of evaluating `pr{ax, " rem ", bx, " = ", rem(ax, bx)}` is

$$
5q + (-2)q \cdot X + 1q \cdot X^2 \mathbin{\text{rem}} 2q = 0q
$$

Similarly, given the equations over the integral domain of polynomials over machine integers denoted by

<div class="math-left">

$$
\begin{array}{l}
\textit{ax} := \text{poly}([\text{term}(8, 0), \text{term}(-9, 1), \text{term}(6, 2)]) \\
\textit{bx} := \text{poly\_of}(3)
\end{array}
$$

</div>

The result of evaluating `pr{ax, " rem ", bx, " = ", rem(ax, bx)}` is

$$
8 + (-9)X + 6X^2 \mathbin{\text{rem}} 3 = 2
$$

*normalize* returns a preferred normal form of a value for a given domain. For example, for quotients, it would be the quotient such that the dividend and divisor have no common non-unit factors. For a modular domain, it would be the least positive element of the equivalence class of the value.

<div class="math-left">

$$
\begin{array}{l}
\text{normalize}(a) \Leftarrow \\
\quad \textbf{if } (x := \text{proc}(\text{"normalize\_"}\,\|\,\text{type}(a), 1)(a)) \textbf{ then } \Uparrow x \\
\quad \Uparrow a \ \blacksquare
\end{array}
$$

</div>

*exp* is the Russian Peasants algorithm for exponentiation. Our version Is transliterated
from R.B.K. Dewar’s SETL implementation of arithmetic for the NYU Ada/Ed system
[Dewar81a,Kruch83a].
<div class="math-left">

$$
\begin{array}{l}
\text{exp}(x, p) \Leftarrow \\
\quad \textbf{if } p = 1 \textbf{ then } \Uparrow x \\
\quad \textbf{else } \{ \text{result} := \mathbf{1}(x) \\
\quad\quad u := \text{copy}(x); \ v := p \\
\quad\quad \text{running} := u \\
\quad\quad \textbf{while } v \mathrel{\sim=} 0 \textbf{ do} \\
\quad\quad \{ \textbf{if } v \mathbin{\%} 2 = 1 \textbf{ then result} := \otimes(\text{result}, \text{running}) \\
\quad\quad\quad \text{running} := \otimes(\text{running}, \text{running}) \\
\quad\quad\quad v := v / 2 \} \\
\quad\quad \Uparrow \text{result} \} \ \blacksquare
\end{array}
$$

</div>

**Predicates.**

All of the predicates defined below except | are required to be defined by a domain instance implementation if they are to be used. However, this is not a minimal set: for example, *is_zero* could be defined in terms of =. | is really not a basic predicate, but since it may be defined in a general way, we include it here.

<div class="math-left">

$$
\begin{array}{l}
= (a, b) \Leftarrow \Uparrow \text{proc}(\text{"equal\_"}\,\|\,\text{type}(a), 2)(a, b) \ \blacksquare \\
< (a, b) \Leftarrow \Uparrow ((\text{proc}(\text{"less\_"}\,\|\,\text{type}(a), 2)(a, b)) \mathrel{|} <0(\ominus(a, b))) \ \blacksquare \\
<0 (x) \Leftarrow \Uparrow \text{proc}(\text{"negative\_"}\,\|\,\text{type}(x), 1)(x) \ \blacksquare \\
\mathit{unit}\,(x) \Leftarrow \Uparrow \text{proc}(\text{"unit\_"}\,\|\,\text{type}(x), 1)(x) \ \blacksquare \\
=0 (x) \Leftarrow \Uparrow \text{proc}(\text{"is\_zero\_"}\,\|\,\text{type}(x), 1)(x) \ \blacksquare
\end{array}
$$

</div>

$a \mid c$ (a divides c) if c is a multiple of a, that is, if $\text{rem}(c, a) = 0$.

<div class="math-left">

$$
{|} (a, c) \Leftarrow \Uparrow =0(\text{rem}(c, a)) \ \blacksquare
$$

</div>

**Commands.**

Every domain instance $D$ implementation should define a preferred method of printing values in the domain, $print_D$. On top of this, we supply printing control structures *pr* and *prs*. *pr* takes a list of arguments enclosed in braces, and prints them, using the printing procedure appropriate for the type of each argument, followed by a carriage return. *prs* is the same, omitting the carriage return.

*prs* and *pr* are defined using the user-defined control operation features of ICON 5.10. [Grisw85a, Grisw83a] When *pr* or *prs* is called with a sequence of expressions in braces, the expressions are passed as unactivated co-expressions, which are then activated with the ICON @ operator.

<div class="math-left">

$$
\begin{array}{l}
\text{prs}\,(x) \Leftarrow \text{every } y := \texttt{!x} \textbf{ do } \text{print}(\texttt{@y}) \ \blacksquare \\
\\
\text{pr}\,(x) \Leftarrow \\
\quad (\text{every } y := \texttt{!x} \textbf{ do } \text{print}(\texttt{@y})) \\
\quad \text{write}() \ \blacksquare \\
\\
\text{print}\,(x) \Leftarrow \\
\quad \textbf{if } \text{type}(x) \mathrel{==} \text{"list"} \\
\quad \textbf{then } \{ \text{writes}(\text{"["}) \\
\quad\quad \text{every } y := \texttt{!x}[1:\texttt{*x}] \textbf{ do } \{ \text{print}(y); \text{ writes}(\text{", "}) \} \\
\quad\quad \text{print}(x[\texttt{*x}]); \text{ writes}(\text{"]"}) \} \\
\quad \textbf{else if } pp := \text{proc}(\text{"print\_"}\,\|\|\,\text{type}(x), 1) \textbf{ then } pp(x) \\
\quad \textbf{else if } \text{type}(x) \mathrel{==} \text{"string"} \textbf{ then writes}(x) \\
\quad \textbf{else writes}(\text{image}(x)) \ \blacksquare
\end{array}
$$

</div>


### 2.2. Primitive domains

The primitive domains are those which are not constructed from other domains, or which are best thought of as undecomposable. We have three such domains available: 

* Arbitrary-precision arbitrary-base integers.
* Arbitrary-precision base 10 integers.
* Ordinary machine integers. 

The latter are best unused: ICON does not notify the user of integer multiplication overflow, and overflow can occur very easily in the applications we deal with. For example, subresultant polynomial remainder sequences with cofficients in the 10000 range involve intermediate calculations in the 10000^ range.


#### 2.2.1. Abitrary base, infinite precision non-negative integer

<p align="center"><strong>Base B Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $base_{\mathbf{B}}$; $set_{base}$ |
| **Constants** | $0_{base_{\mathbf{B}}}$, $1_{base_{\mathbf{B}}}$, $k_{base_{\mathbf{B}}}$ |
| **Operators** | $\oplus_{base_{\mathbf{B}}}$, $\ominus_{base_{\mathbf{B}}}$, $\otimes_{base_{\mathbf{B}}}$, $\odiv_{base_{\mathbf{B}}}$, $normalize_{base_{\mathbf{B}}}$ |
| **Predicates** | $<_{base_{\mathbf{B}}}$, $=_{base_{\mathbf{B}}}$ |
| **Commands** | $print_{base_{\mathbf{B}}}$ |

**Data structures.** *base* is a number $B$ such that 1 is less than the maximum machine word integer. Then *digits* is a list of machine word integers less than *base* and greater than 0. Width is the printing width of digits of the base, in terms of decimal digits.

<div class="math-left">

$$
\begin{array}{l}
\textbf{record } base_{\mathbf{B}}\ (base, digits) \\
\textbf{global } Base, Width \\
set_{base}(b, w) \Leftarrow \\
\quad Base \mathrel{:=} b \\
\quad Width \mathrel{:=} *(b \ || \ "") - 1 \ \blacksquare
\end{array}
$$

</div>

**Constants.**

<div class="math-left">

$$
\begin{array}{l}
0_{base_{\mathbf{B}}}(x) \Leftarrow \Uparrow base_{\mathbf{B}}(x.base, [0]) \ \blacksquare \\
1_{base_{\mathbf{B}}}(x) \Leftarrow \Uparrow base_{\mathbf{B}}(x.base, [1]) \ \blacksquare \\
k_{base_{\mathbf{B}}}(x) \Leftarrow \Uparrow base_{\mathbf{B}}(\text{Base}, digits\_of(abs(x), \text{Base})) \ \blacksquare \\
digits\_of(x, B) \Leftarrow \textbf{if } x < B \textbf{ then } \Uparrow [x] \textbf{ else } \Uparrow digits\_of(x/B, B) \ ||| \ [mod_{integer}(x, B)] \ \blacksquare
\end{array}
$$

</div>

**Operators.**

The base $B$ addition algorithm is that of Lipson, p. 199. For input it takes $a$, $b$, lists of integers $\leq B$, of length $m$ returning $a + b$.

<div class="math-left">

$$
\begin{array}{l}
\oplus_{base_{\mathbf{B}}}(a, b) \Leftarrow \\
\quad B \mathrel{:=} a.base \\
\quad \Uparrow base_{\mathbf{B}}(B, \oplus_{digits}(a.digits, b.digits, B)) \ \blacksquare
\end{array}
$$

</div>

<div class="math-left">

$$
\begin{array}{l}
\oplus_{digits}(ad, bd, B) \Leftarrow \\
\quad m \mathrel{:=} \#ad;\ n \mathrel{:=} \#bd \\
\quad \textbf{if } m < n \textbf{ then } \{ a \mathrel{:=} (list(n - m, 0) \ ||| \ ad);\ b \mathrel{:=} bd \} \\
\quad \textbf{else if } m > n \textbf{ then } \{ a \mathrel{:=} ad;\ b \mathrel{:=} list(m - n, 0) \ ||| \ bd \} \\
\quad \textbf{else } \{ a \mathrel{:=} ad;\ b \mathrel{:=} bd \} \\
\quad m \mathrel{:=} \#a; \\
\quad c\_digits \mathrel{:=} list(m + 1, 0); \\
\quad gamma \mathrel{:=} 0 \\
\quad \textbf{every } i \mathrel{:=} m \textbf{ to } 1 \textbf{ by } -1 \textbf{ do } \\
\quad \{ t \mathrel{:=} a[i] + b[i] + gamma \\
\quad\quad c\_digits[i + 1] \mathrel{:=} mod_{integer}(t, B) \\
\quad\quad gamma \mathrel{:=} t / B \} \\
\quad c\_digits[1] \mathrel{:=} gamma \\
\\
\quad \Uparrow normalize_{digits}(c\_digits) \ \blacksquare
\end{array}
$$

</div>

Example. The result of evaluating

<div class="math-left">

$$
\begin{array}{l}
x \mathrel{:=} base_{\mathbf{B}}(8, [1]);\ y \mathrel{:=} base_{\mathbf{B}}(8, [7, 7, 7]) \\
\text{pr}\{x,\ \text{" + "},\ y,\ \text{" = "},\ \oplus_{base_{\mathbf{B}}}(x, y)\}
\end{array}
$$

</div>

is

1 #8# + 7 7 7 #8# = 1 0 0 0 #8#

The base B subtraction algorithm is Knuth Algorithm 4.3.1 S, transliterated from a SETL implementation of Robert Dewar. Assume $a\geq b$ are lists of integers $\leq B$. Returns $a-b$. 

<div class="math-left">

$$
\begin{array}{l}
\ominus_{base_{\mathbf{B}}}(a, bb) \Leftarrow \\
\quad b \mathrel{:=} copy(bb);\ B \mathrel{:=} a.base;\ m \mathrel{:=} *a.digits \\
\quad \textbf{repeat } \\
\quad \{ n \mathrel{:=} *b.digits \\
\quad\quad \textbf{if } m < n \textbf{ then } \text{pr}\{\text{"ERROR: } base_{\mathbf{B}} \text{ integer subtraction underflow"}\} \\
\quad\quad \textbf{else if } m > n \\
\quad\quad \textbf{then } b \mathrel{:=} base_{\mathbf{B}}(B, list(m - n, 0) \ ||| \ b.digits) \\
\quad\quad \textbf{else } \Uparrow base_{\mathbf{B}}(b.base, \ominus_{digits}(a.digits, b.digits, b.base)) \} \ \blacksquare
\end{array}
$$

</div>

<div class="math-left">

$$
\begin{array}{l}
\ominus_{digits}(a, b, B) \Leftarrow \\
\quad u \mathrel{:=} copy(a) \\
\quad v \mathrel{:=} list(*a - *b, 0) \ ||| \ copy(b) \\
\quad k \mathrel{:=} 0 \\
\quad \textbf{every } j \mathrel{:=} *u \textbf{ to } 1 \textbf{ by } -1 \textbf{ do } \\
\quad \{ u[j] \mathrel{:=} u[j] - v[j] + k \\
\quad\quad \textbf{if } u[j] < 0 \textbf{ then } \{ u[j] \mathrel{+{=}} B;\ k \mathrel{:=} -1 \} \textbf{ else } k \mathrel{:=} 0 \} \\
\\
\quad \Uparrow normalize_{digits}(u) \ \blacksquare
\end{array}
$$

</div>

**Example.**

The result of evaluating

<div class="math-left">

$$
\begin{array}{l}
x \mathrel{:=} base_{\mathbf{B}}(10, [1,0,0,5,6,3]);\ y \mathrel{:=} base_{\mathbf{B}}(10, [5,3,3,5]) \\
\text{pr}\{x,\ \text{" - "},\ y,\ \text{" = "},\ \ominus_{base_{\mathbf{B}}}(x,y)\} \\
x \mathrel{:=} base_{\mathbf{B}}(10,[2,1,2]);\ y \mathrel{:=} base_{\mathbf{B}}(10, [9,9]) \\
\text{pr}\{x,\ \text{" - "},\ y,\ \text{" = "},\ \ominus_{base_{\mathbf{B}}}(x, y)\} \\
y \mathrel{:=} base_{\mathbf{B}}(10, [1,9,9]) \\
\text{pr}\{x,\ \text{" - "},\ y,\ \text{" = "},\ \ominus_{base_{\mathbf{B}}}(x, y)\}
\end{array}
$$

</div>

is

1 0 0 5 6 3 #10# - 5 3 3 5 #10# = 9 5 2 2 8 #10#  
2 1 2 #10# - 9 9 #10# = 1 1 3 #10#  
2 1 2 #10# - 1 9 9 #10# = 1 3 #10#

<div class="math-left">

$$
\begin{array}{l}
normalize_{base_{\mathbf{B}}}(r) \Leftarrow \\
\quad d \mathrel{:=} normalize_{digits}(r.digits) \\
\quad \Uparrow base_{\mathbf{B}}(r.base, d) \ \blacksquare \\
\\
normalize_{digits}(d) \Leftarrow \\
\quad \textbf{while } (\#d > 1) \ \& \ (d[1] = 0) \textbf{ do } pop(d) \\
\quad \Uparrow d \ \blacksquare
\end{array}
$$

</div>

The base $B$ multiplication algorithm is that of Lipson, p. 200. As input it takes $a$, $b$, lists of integers $\leq B$, of length $m$ and $n$. It outputs $a \otimes b$. 

<div class="math-left">

$$
\begin{array}{l}
\otimes_{base_{\mathbf{B}}}(a, b) \Leftarrow \Uparrow base_{\mathbf{B}}(a.base, \otimes_{digits}(a.digits, b.digits, a.base)) \ \blacksquare
\end{array}
$$

</div>

<div class="math-left">

$$
\begin{array}{l}
\otimes_{digits}(a, b, B) \Leftarrow \\
\quad m \mathrel{:=} \#a \\
\quad n \mathrel{:=} \#b \\
\quad c \mathrel{:=} list(m + n, 0) \\
\quad \textbf{every } k \mathrel{:=} 0 \textbf{ to } n - 1 \textbf{ by } 1 \textbf{ do } \\
\quad \{ \\
\quad\quad gamma \mathrel{:=} 0 \\
\quad\quad \textbf{every } l \mathrel{:=} 0 \textbf{ to } m - 1 \textbf{ by } 1 \textbf{ do } \\
\quad\quad \{ \\
\quad\quad\quad t \mathrel{:=} a[m - l] * b[n - k] + c[m + n - k - l] + gamma \\
\quad\quad\quad \textbf{if } t < 0 \\
\quad\quad\quad \textbf{then } \text{pr}\{\text{"ERROR: Integer overflow in } \otimes_{base_{\mathbf{B}}}\text{, base = "},\ B\} \\
\quad\quad\quad c[m + n - k - l] \mathrel{:=} mod_{integer}(t, B) \\
\quad\quad\quad gamma \mathrel{:=} t / B \\
\quad\quad \} \\
\quad\quad c[n - k] \mathrel{:=} gamma \\
\quad \} \\
\\
\quad \Uparrow normalize_{digits}(c) \ \blacksquare
\end{array}
$$

</div>

**Example.**

The result of evaluating

<div class="math-left">

$$
\begin{array}{l}
x \mathrel{:=} k_{base_{\mathbf{B}}}(28107324);\ y \mathrel{:=} k_{base_{\mathbf{B}}}(75625) \\
\text{pr}\{x,\ \text{" * "},\ y,\ \text{" = "},\ \otimes_{base_{\mathbf{B}}}(x,y)\} \\
x \mathrel{:=} k_{base_{\mathbf{B}}}(28107324);\ y \mathrel{:=} k_{base_{\mathbf{B}}}(75625) \\
\text{pr}\{x,\ \text{" * "},\ y,\ \text{" = "},\ \otimes_{base_{\mathbf{B}}}(x,y)\} \\
x \mathrel{:=} k_{base_{\mathbf{B}}}(7478);\ y \mathrel{:=} k_{base_{\mathbf{B}}}(4625) \\
\text{pr}\{x,\ \text{" * "},\ y,\ \text{" = "},\ \otimes_{base_{\mathbf{B}}}(x, y)\}
\end{array}
$$

</div>

is

2 8 1 0 7 3 2 4 #10# * 7 5 6 2 5 #10# = 2 1 2 5 6 1 6 3 7 7 5 0 0 #10#  
2 8 1 0 7 3 2 4 #10# * 7 5 6 2 5 #10# = 2 1 2 5 6 1 6 3 7 7 5 0 0 #10#  
7 4 7 8 #10# * 4 6 2 5 #10# = 3 4 5 8 5 7 5 0 #10#


The following algorithm computes $a\over b$ by long division. The design is that of Knuth Algorithm 4.3.1 D [Knuth73a], and the implementation is largely borrowed from a SETL implementation of Robert Dewar [NYU 84a]. Most of the following comments are lifted from the Dewar implementation. 

This is by far the most difficult of the four basic operations. This is because the paper and pencil algorithm involves certain amounts of guess work which cannot be programmed directly. The approach (analyzed in detail by Knuth) is to reduce the guess work by computing a rather good guess at each digit of the result, and then correcting if the guess is wrong. 

<div class="math-left">

$$
\begin{array}{l}
\odiv_{base_{\mathbf{B}}}(a, b) \Leftarrow \Uparrow normalize_{base_{\mathbf{B}}}(base_{\mathbf{B}}(a.base, \odiv_{digits}(a.digits, b.digits, a.base))) \ \blacksquare \\
\\
\odiv_{digits}(a, b, B) \Leftarrow \\
\quad \textbf{If the divisor is 0, then fail.} \\
\quad \textbf{if } (*b = 1) \ \& \ (b[1] = 0) \textbf{ then } \{ \text{pr}\{\text{"ERROR: divide by 0 in } base_{\mathbf{B}}\text{"}\};\ \bot \} \\
\quad \textbf{If } a \textbf{ is shorter than } b, \textbf{ return } 0. \\
\quad \textbf{if } *a < *b \textbf{ then } \Uparrow [0]
\end{array}
$$

</div>


The case of a one digit divisor is treated specially. Not only is this more efficient, but the general algorithm assumes that the divisor contains at least two digits. Basically dividing by a single digit is straightforward. Since we can represent numbers up to $B*B— 1$, we can do the steps of the division exactly without any need for guess work. The division is then done left to right.

<div class="math-left">

$$
\begin{array}{l}
\textbf{if } *b = 1 \textbf{ then } \\
\{ q \mathrel{:=} list(*a, 0) \\
\quad rr \mathrel{:=} 0 \\
\quad \textbf{every } j \mathrel{:=} 1 \textbf{ to } *a \textbf{ do } \\
\quad \{ du \mathrel{:=} rr * B + a[j] \\
\quad\quad q[j] \mathrel{:=} du / b[1] \\
\quad\quad rr \mathrel{:=} du \% b[1] \} \\
\quad \Uparrow normalize_{digits}(q) \}
\end{array}
$$

</div>

Otherwise we must commence with the full long division algorithm.

<div class="math-left">

$$
\begin{array}{l}
u \mathrel{:=} copy(a) \\
v \mathrel{:=} copy(b) \\
n \mathrel{:=} *v \\
m \mathrel{:=} *u - n \\
q \mathrel{:=} list(m + 1, 0)
\end{array}
$$

</div>


Knuth Step D1. [Normalize] The first step is to multiply both the divisor and dividend by a scale factor. Obviously such scaling does not affect the quotient. The purpose of this scaling is to ensure that the first digit of the divisor is at least $B/2$. This condition is required for the proper operation of the quotient estimation algorithm used in the division loop. Note that we added an extra digit at the front of the dividend above.

<div class="math-left">

$$
\begin{array}{l}
d \mathrel{:=} B / (v[1] + 1) \\
u \mathrel{:=} \otimes_{digits}(u, [d], B) \\
\textbf{if } \#u = m + n \textbf{ then } u \mathrel{:=} [0] \ || \ u \\
v \mathrel{:=} \otimes_{digits}(v, [d], B)
\end{array}
$$

</div>

Knuth Step D2. [Initialize $j$] This is the major loop, corresponding to long division steps.

<div class="math-left">

$$
\begin{array}{l}
\textbf{every } j \mathrel{:=} 1 \textbf{ to } m + 1 \textbf{ do } \\
\{
\end{array}
$$

</div>

Knuth Step D3. [Calculate q_hat] Guess the next quotient digit by doing a division based on the leading digits. This estimate is never low and at most 2 high.

<div class="math-left">

$$
\begin{array}{l}
\textbf{if } u[j] = v[1] \textbf{ then } qe \mathrel{:=} B - 1 \textbf{ else } qe \mathrel{:=} ((u[j] * B) + u[j + 1]) / v[1]
\end{array}
$$

</div>

The following loop refines this guess so that it is almost always correct and is at worst one too high (see Knuth [Knuth73a] for proofs). 

<div class="math-left">

$$
\begin{array}{l}
\textbf{while } (v[2] * qe) > (((u[j] * B) + u[j + 1] - (qe * v[1])) * B + u[j + 2]) \textbf{ do } qe \mathrel{{-}{:=}} 1
\end{array}
$$

</div>

Knuth Step D4. [Multiply and subtract] Now (for the moment accepting the estimate as correct), we subtract the appropriate multiple of the divisor. This is similar to the inner loop of the multiplication routine. 

<div class="math-left">

$$
\begin{array}{l}
c \mathrel{:=} 0 \\
\textbf{every } k \mathrel{:=} n \textbf{ to } 1 \textbf{ by } -1 \textbf{ do } \\
\{ du \mathrel{:=} u[j + k] - (qe * v[k]) + c \\
\quad u[j + k] \mathrel{:=} du \% B \\
\quad c \mathrel{:=} du / B \\
\quad \textbf{if } u[j + k] < 0 \textbf{ then } \{ u[j + k] \mathrel{+{=}} B;\ c \mathrel{{-}{:=}} 1 \} \} \\
u[j] \mathrel{+{=}} c
\end{array}
$$

</div>

Knuth Step D5,D6. [Test remainder. Add back] If the estimate was one off, then $u[j]$ went negative when the final carry was added above. In this case, we add back the divisor once, and adjust the quotient digit.

<div class="math-left">

$$
\begin{array}{l}
q[j] \mathrel{:=} qe \\
\textbf{if } u[j] < 0 \textbf{ then } \\
\{ qe \mathrel{{-}{:=}} 1 \\
\quad c \mathrel{:=} 0 \\
\quad \textbf{every } k \mathrel{:=} n \textbf{ to } 1 \textbf{ by } -1 \textbf{ do } \\
\quad \{ u[j + k] \mathrel{+{=}} v[k] + c \\
\quad\quad \textbf{if } u[j + k] \geq B \textbf{ then } \{ u[j + k] \mathrel{{-}{:=}} B;\ c \mathrel{:=} 1 \} \\
\quad\quad \textbf{else } c \mathrel{:=} 0 \} \\
\quad u[j] \mathrel{+{=}} c \} \\
\} \\
\Uparrow normalize_{digits}(q) \ \blacksquare
\end{array}
$$

</div>

**Example.** The result of evaluating 

<div class="math-left">

$$
\begin{array}{l}
\textbf{every } xy \mathrel{:=} ![[10, 1], [4,2], [27, 9], [42,2], [90,1], \\
\quad\quad [188175, 325], [188175, 579], [188175, 580], \\
\quad\quad [188175, 578], [121903, 5335], \\
\quad\quad [212, 99], [115668, 75625]] \\
\textbf{do } \{ x \mathrel{:=} k_{base_{\mathbf{B}}}(xy[1]);\ y \mathrel{:=} k_{base_{\mathbf{B}}}(xy[2]) \\
\quad \text{pr}\{x,\ \text{" / "},\ y,\ \text{" = "},\ \odiv_{base_{\mathbf{B}}}(x, y)\} \}
\end{array}
$$

</div>

is

1 0 #10# / 1 #10# = 1 0 #10#  
4 #10# / 2 #10# = 2 #10#  
2 7 #10# / 9 #10# = 3 #10#  
4 2 #10# / 2 #10# = 2 1 #10#  
9 0 #10# / 1 #10# = 9 0 #10#  
1 8 8 1 7 5 #10# / 3 2 5 #10# = 5 7 9 #10#  
1 8 8 1 7 5 #10# / 5 7 9 #10# = 3 2 5 #10#  
1 8 8 1 7 5 #10# / 5 8 0 #10# = 3 2 4 #10#  
1 8 8 1 7 5 #10# / 5 7 8 #10# = 3 2 5 #10#  
1 2 1 9 0 3 #10# / 5 3 3 5 #10# = 2 2 #10#  
2 1 2 #10# / 9 9 #10# = 2 #10#  
1 1 5 6 6 8 #10# / 7 5 6 2 5 #10# = 1 #10#

**Commands.** We supply a print command. 

<div class="math-left">

$$
\begin{array}{l}
print_{base_{\mathbf{B}}}(b) \Leftarrow \\
\quad \textbf{local } digits \\
\quad writes(b.digits[1],\ \text{" "}) \\
\quad \textbf{every } writes(right(\texttt{!}rest(b.digits),\ Width,\ \text{"0"}),\ \text{" "}) \\
\quad writes(\text{"\#"},\ b.base,\ \text{"\#"}) \ \blacksquare
\end{array}
$$

</div>

**Predicates.** We supply two predicates, $<_{base_{\mathbf{B}}}$ and $=_{base_{\mathbf{B}}}$.

<div class="math-left">

$$
\begin{array}{l}
<_{base_{\mathbf{B}}}(a, b) \Leftarrow \Uparrow <_{digits}(a.digits, b.digits) \ \blacksquare \\
\\
<_{digits}(a, b) \Leftarrow \\
\quad \textbf{if } *a < *b \textbf{ then } \Uparrow \\
\quad \textbf{else if } (*a > *b) \textbf{ then } \bot \\
\quad \textbf{else if } *a = 0 \textbf{ then } \bot \\
\quad \textbf{else if } (a[1] > b[1]) \textbf{ then } \bot \\
\quad \textbf{else if } (a[1] < b[1]) \textbf{ then } \Uparrow \\
\quad \textbf{else } \Uparrow <_{digits}(rest(a), rest(b)) \ \blacksquare \\
\\
=_{base_{\mathbf{B}}}(a, b) \Leftarrow \Uparrow =_{digits}(a.digits, b.digits) \ \blacksquare \\
\\
=_{digits}(a, b) \Leftarrow \\
\quad \textbf{if } *a < *b \textbf{ then } \bot \\
\quad \textbf{else if } (*a > *b) \textbf{ then } \bot \\
\quad \textbf{else if } *a = 0 \textbf{ then } \Uparrow \\
\quad \textbf{else if } (a[1] \neq b[1]) \textbf{ then } \bot \\
\quad \textbf{else } \Uparrow =_{digits}(rest(a), rest(b)) \ \blacksquare
\end{array}
$$

</div>
<div class="math-left">

$$
\begin{array}{l}
rest(x) \Leftarrow \textbf{if } *x < 2 \textbf{ then } \Uparrow []\ \textbf{else } \Uparrow x[2:*x + 1] \ \blacksquare
\end{array}
$$

</div>

#### 2.2.2. Arbitrary precision integer Euclidean domain Z

<p align="center"><strong>Integer Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $Z$ |
| **Constants** | $0_Z$, $1_Z$, $k_Z$ |
| **Operators** | $\oplus_Z$, $-_Z$, $\otimes_Z$, $\odiv_Z$, $mod_Z$, $abs_Z$, $deg_Z$, $normalize_Z$ |
| **Predicates** | $=_Z$, $<_Z$, $unit_Z$, $>0_Z$, $<0_Z$, $=0_Z$ |
| **Commands** | $print_Z$ |

**Data structures.** *sign* is 1 or $-1$. *mantissa* is a base $Base$ integer, where the $Base$ is set by $k_Z$.

<div class="math-left">

$$
\begin{array}{l}
\textbf{record } Z\ (sign, mantissa)
\end{array}
$$

</div>

**Constants.**

<div class="math-left">

$$
\begin{array}{l}
0_Z(a) \Leftarrow \Uparrow Z(1, 0_{base_{\mathbf{B}}}(a.mantissa)) \ \blacksquare \\
1_Z(a) \Leftarrow \Uparrow Z(1, 1_{base_{\mathbf{B}}}(a.mantissa)) \ \blacksquare
\end{array}
$$

</div>

$k_Z$ takes an ICON integer and transforms it into a $Z$ constant.

<div class="math-left">

$$
\begin{array}{l}
k_Z(x) \Leftarrow \\
\quad \textbf{initial } set_{base}(10000) \\
\quad \Uparrow Z(\textbf{if } x = 0 \textbf{ then } 1 \textbf{ else } x/abs(x), \\
\quad\quad base_{\mathbf{B}}(Base, digits\_of(abs(x), Base))) \ \blacksquare
\end{array}
$$

</div>

**Operators.**

<div class="math-left">

$$
\begin{array}{l}
\oplus_Z(a, b) \Leftarrow \\
\quad \textbf{if } <0_Z(a) \ \& \ >0_Z(b) \textbf{ then } \Uparrow \oplus_Z(b, a) \\
\quad \Uparrow normalize_Z( \\
\quad\quad \textbf{if } =0_Z(a) \textbf{ then } b \\
\quad\quad \textbf{else if } =0_Z(b) \textbf{ then } a \\
\quad\quad \textbf{else if } (>0_Z(a) \ \& \ >0_Z(b)) \ | \ (<0_Z(a) \ \& \ <0_Z(b)) \\
\quad\quad \textbf{then } Z(a.sign, \oplus_{base_{\mathbf{B}}}(a.mantissa, b.mantissa)) \\
\quad\quad \textbf{else } \{ \#\ a > 0 \textbf{ and } b < 0,\ \textbf{so...} \\
\quad\quad\quad \textbf{if } <_{base_{\mathbf{B}}}(a.mantissa, b.mantissa) \\
\quad\quad\quad \textbf{then } Z(-1, \ominus_{base_{\mathbf{B}}}(b.mantissa, a.mantissa)) \\
\quad\quad\quad \textbf{else } Z(1, \ominus_{base_{\mathbf{B}}}(a.mantissa, b.mantissa)) \} \\
\quad ) \ \blacksquare
\end{array}
$$

</div>

**Example.** The result of evaluating

<div class="math-left">

$$
\begin{array}{l}
x \mathrel{:=} k_Z(1);\ y \mathrel{:=} k_Z(-999) \\
\text{pr}\{x,\ \text{" + "},\ y,\ \text{" = "},\ \oplus_Z(x, y)\}
\end{array}
$$

</div>

is

$1z + (-999z) = (-998z)$

<div class="math-left">

$$
\begin{array}{l}
-_Z(x) \Leftarrow \Uparrow normalize_Z(Z(-x.sign, x.mantissa)) \ \blacksquare
\end{array}
$$

</div>

**Example.** The result of evaluating 

<div class="math-left">

$$
\begin{array}{l}
x \mathrel{:=} k_Z(212);\ y \mathrel{:=} k_Z(-99) \\
\text{pr}\{\text{"-"},\ x,\ \text{" = "},\ -_Z(x)\} \\
\text{pr}\{\text{"-"},\ y,\ \text{" = "},\ -_Z(y)\}
\end{array}
$$

</div>

is

$-212z = (-212z)$  
$-(-99z) = 99z$

<div class="math-left">

$$
\begin{array}{l}
\otimes_Z(a, b) \Leftarrow \Uparrow normalize_Z(Z(a.sign * b.sign, \otimes_{base_{\mathbf{B}}}(a.mantissa, b.mantissa))) \ \blacksquare
\end{array}
$$

</div>

**Example.**  The result of evaluating 

<div class="math-left">

$$
\begin{array}{l}
\textbf{every } xy \mathrel{:=} ![[10, 1], [121903, 5335], [115668, 75625]] \\
\textbf{do } \{ x \mathrel{:=} k_Z(xy[1]);\ y \mathrel{:=} k_Z(xy[2]); \\
\quad \text{pr}\{x,\ \text{" / "},\ y,\ \text{" = "},\ \odiv_Z(x, y)\} \}
\end{array}
$$

</div>

is

$10z / 1z = 10z$  
$121903z / 5335z = 22z$  
$115668z / 75625z = 1z$

<div class="math-left">

$$
\begin{array}{l}
mod_Z(a, b) \Leftarrow \\
\Uparrow (\textbf{if } <_Z(b, 0_Z(b)) \textbf{ then } mod_Z(a, -_Z(b)) \\
\quad \textbf{else if } <_Z(a, 0_Z(a)) \\
\quad \textbf{then } \oplus_Z(a, -_Z(\otimes_Z(b, \oplus_Z(-_Z(1_Z(a)), \odiv_Z(a, b)))) \\
\quad \textbf{else } \oplus_Z(a, -_Z(\otimes_Z(b, \odiv_Z(a, b)))) )
\end{array}
$$

</div>

**Example.** The result of evaluating

<div class="math-left">

$$
\begin{array}{l}
x \mathrel{:=} k_Z(121903);\ y \mathrel{:=} k_Z(5335) \\
\text{pr}\{x,\ \text{" mod "},\ y,\ \text{" = "},\ mod_Z(x, y)\}
\end{array}
$$

</div>

is

$121903z \bmod 5335z = 4533z$

<div class="math-left">

$$
\begin{array}{l}
abs_Z(x) \Leftarrow \Uparrow Z(1, x.mantissa) \ \blacksquare
\end{array}
$$

</div>

<div class="math-left">

$$
\begin{array}{l}
deg_Z(x) \Leftarrow \Uparrow x \ \blacksquare \\
normalize_Z(x) \Leftarrow \Uparrow (\textbf{if } =0_Z(x) \textbf{ then } Z(1, x.mantissa) \textbf{ else } x) \ \blacksquare
\end{array}
$$

</div>

**Predicates.**

<div class="math-left">

$$
\begin{array}{l}
=_Z(a, b) \Leftarrow \\
\quad \textbf{if } =0_Z(a) \ \& \ =0_Z(b) \textbf{ then } \Uparrow \\
\quad \textbf{else if } a.sign \neq b.sign \textbf{ then } \bot \\
\quad \textbf{else } \Uparrow =_{base_{\mathbf{B}}}(a.mantissa, b.mantissa) \ \blacksquare \\
\\
<_Z(a, b) \Leftarrow \\
\quad \textbf{if } a.sign < b.sign \textbf{ then } \Uparrow \\
\quad \textbf{if } a.sign > b.sign \textbf{ then } \bot \\
\quad \textbf{if } a.sign = 1 \textbf{ then } \Uparrow <_{base_{\mathbf{B}}}(a.mantissa, b.mantissa) \\
\quad \textbf{if } a.sign = -1 \textbf{ then } \Uparrow <_{base_{\mathbf{B}}}(b.mantissa, a.mantissa) \ \blacksquare \\
\\
unit_Z(x) \Leftarrow \Uparrow (=_Z(x, 1_Z(x)) \ | \ =_Z(x, Z(-1, 1_{base_{\mathbf{B}}}(x.mantissa)))) \ \blacksquare \\
>0_Z(x) \Leftarrow \Uparrow ((x.sign = 1) \ \& \ \textbf{not } =0_Z(x)) \ \blacksquare \\
<0_Z(x) \Leftarrow \Uparrow ((x.sign = -1) \ \& \ \textbf{not } =0_Z(x)) \ \blacksquare \\
=0_Z(x) \Leftarrow \Uparrow =_{base_{\mathbf{B}}}(x.mantissa, 0_{base_{\mathbf{B}}}(x.mantissa)) \ \blacksquare
\end{array}
$$

</div>

**Commands.**

<div class="math-left">

$$
\begin{array}{l}
print_Z(a) \Leftarrow \\
\quad \textbf{local } digits \\
\quad \textbf{if } a.sign < 0 \textbf{ then } writes(\text{"(-"}) \\
\quad digits \mathrel{:=} a.mantissa.digits \\
\quad \textbf{every } ch \mathrel{:=} \texttt{!}digits \textbf{ do } writes(right(ch,\ Width,\ \text{"0"})) \\
\quad writes(\text{"z"}) \\
\quad \textbf{if } a.sign < 0 \textbf{ then } writes(\text{")"}) \ \blacksquare
\end{array}
$$

</div>


#### 2.2.3. Small integers Euclidean domain

We provide the following machine integer arithmetic facilities:

<p align="center"><strong>Machine Integer Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Constants** | $0_{integer}$, $1_{integer}$ |
| **Operators** | $\oplus$, $-_{integer}$, $\odot_{integer}$, $\mathit{circleslash}_{integer}$, $rem_{integer}$, $mod_{integer}$, $deg_{integer}$, $abs_{integer}$ |
| **Predicates** | $=0_{integer}$, $<0_{integer}$, $=_{integer}$, $unit_{integer}$ |
| **Commands** | $print_{integer}$ |


**Constants.** We provide constants 0 and 1, as follows:

<div class="math-left">

$$
\begin{array}{l}
0_{integer}(x) \Leftarrow \Uparrow 0 \ \blacksquare \\
1_{integer}(x) \Leftarrow \Uparrow 1 \ \blacksquare
\end{array}
$$

</div>

**Operators.**

<div class="math-left">

$$
\begin{array}{l}
\oplus(a, b) \Leftarrow \Uparrow a + b \ \blacksquare \\
-_integer(x) \Leftarrow \Uparrow -x \ \blacksquare \\
\odot_{integer}(a, b) \Leftarrow \Uparrow a * b \ \blacksquare \\
\mathit{circleslash}_{integer}(a, b) \Leftarrow \Uparrow a / b \ \blacksquare \\
\\
mod_{integer}(a, m) \Leftarrow \\
\quad \textbf{if } m < 0 \textbf{ then } m \mathrel{:=} -m \\
\quad \textbf{repeat } \\
\quad \textbf{if } a < 0 \textbf{ then } a \mathrel{:=} a + (abs(a/m) + 1) * m \textbf{ else } \Uparrow a \% m \ \blacksquare
\end{array}
$$

</div>

*rem* is not *mod*, because *rem* may be negative, but *mod* is never negative.

<div class="math-left">

$$
\begin{array}{l}
rem_{integer}(a, b) \Leftarrow \Uparrow a \% b \ \blacksquare
\end{array}
$$

</div>

<div class="math-left">

$$
\begin{array}{l}
deg_{integer}(x) \Leftarrow \Uparrow x \ \blacksquare \\
abs_{integer}(x) \Leftarrow \Uparrow abs(x) \ \blacksquare
\end{array}
$$

</div>

**Predicates.**

<div class="math-left">

$$
\begin{array}{l}
=0_{integer}(x) \Leftarrow \Uparrow (x = 0) \ \blacksquare \\
<0_{integer}(x) \Leftarrow \Uparrow x < 0 \ \blacksquare \\
=_{integer}(a, b) \Leftarrow \Uparrow a = b \ \blacksquare \\
unit_{integer}(x) \Leftarrow \textbf{if } ((x = 1) \ | \ (x = -1)) \textbf{ then } \Uparrow x \ \blacksquare
\end{array}
$$

</div>

**Commands.**

<div class="math-left">

$$
\begin{array}{l}
print_{integer}(x) \Leftarrow \textbf{if } x < 0 \textbf{ then } writes(\text{"("},\ x,\ \text{")"}) \textbf{ else } writes(x) \ \blacksquare
\end{array}
$$

</div>


### 2.3. Domain constructors

EUCLID provides three classes of domain constructions: quotient domains $Q_D$, modular domains $D/(e)$, polynomials $D[x]$ and truncated power series $T(D[[x]])_n$.


#### 2.3.1. Quotient Euclidean domain $\mathcal{Q}$

<p align="center"><strong>Quotient Domain Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $\mathcal{Q}$ |
| **Constants** | $0_{\mathcal{Q}}$, $1_{\mathcal{Q}}$, $k_{i\mathcal{Q}_x}$ |
| **Operators** | $\oplus_{\mathcal{Q}}$, $-_{\mathcal{Q}}$, $\otimes_{\mathcal{Q}}$, $\odiv_{\mathcal{Q}}$, $mod_{\mathcal{Q}}$, $normalize_{\mathcal{Q}}$, $deg_{\mathcal{Q}}$ |
| **Predicates** | $=_{\mathcal{Q}}$, $unit_{\mathcal{Q}}$ |
| **Commands** | $print_{\mathcal{Q}}$ |

**Data structures.** The domains $\mathcal{Q}$ are of the form $\mathcal{Q}=\{\frac{m}{n} \mid m, n \in D, n \neq 0\}$, for some Euclidean domain $D$. Elements of such a domain $\mathcal{Q}$ are quotients with a dividend and a divisor:

<div class="math-left">

$$
\begin{array}{l}
\textbf{record } Q\ (dividend, divisor)
\end{array}
$$

</div>

**Constants.**

<div class="math-left">

$$
\begin{array}{l}
0_{\mathcal{Q}}(x) \Leftarrow \Uparrow Q(0(x.dividend), 1(x.dividend)) \ \blacksquare \\
1_{\mathcal{Q}}(x) \Leftarrow \Uparrow Q(1(x.dividend), 1(x.dividend)) \ \blacksquare \\
k_{i\mathcal{Q}_x}(l, j) \Leftarrow \Uparrow term(Q(l, 1(l)), j) \ \blacksquare
\end{array}
$$

</div>

**Operators.** Let $a = \frac{p}{q}$, $b = \frac{p'}{q'}$. Then $a + b = \frac{x}{y}$ where $x = pq' \oplus p'q$, $y = qq'$.

<div class="math-left">

$$
\begin{array}{l}
\oplus_{\mathcal{Q}}(a, b) \Leftarrow \\
\quad \textbf{local } zz,\ top \\
\quad top \mathrel{:=} \oplus(\otimes(a.dividend, b.divisor), \otimes(b.dividend, a.divisor)) \\
\quad zz \mathrel{:=} 0(a.dividend) \\
\quad \Uparrow \textbf{if } =_{\mathcal{Q}}(top, zz) \textbf{ then } Q(zz, 1(a.dividend)) \\
\quad \textbf{else } normalize_{\mathcal{Q}}(Q(top, \otimes(a.divisor, b.divisor))) \ \blacksquare
\end{array}
$$

</div>

<div class="math-left">

$$
\begin{array}{l}
-_{\mathcal{Q}}(x) \Leftarrow \Uparrow Q(-(x.dividend), x.divisor) \ \blacksquare \\
\\
\otimes_{\mathcal{Q}}(a, b) \Leftarrow \Uparrow normalize_{\mathcal{Q}}(Q(\otimes(a.dividend, b.dividend), \otimes(a.divisor, b.divisor))) \ \blacksquare \\
\\
\odiv_{\mathcal{Q}}(a, b) \Leftarrow \\
\quad \textbf{local } zz \\
\quad zz \mathrel{:=} 0(b.dividend) \\
\quad \textbf{if } =(b.dividend, zz) \textbf{ then } \text{pr}\{\text{"ERROR: divide by 0 in } \mathcal{Q}\text{"}\} \\
\quad \textbf{else } \Uparrow (\textbf{if } =(a.divisor, zz) \textbf{ then } 0_{\mathcal{Q}}(a) \\
\quad\quad \textbf{else } normalize_{\mathcal{Q}}(Q(\otimes(a.dividend, b.divisor), \otimes(b.dividend, a.divisor)))) \ \blacksquare
\end{array}
$$

</div>

There are no remainders in quotient division.

<div class="math-left">

$$
\begin{array}{l}
mod_{\mathcal{Q}}(a, m) \Leftarrow \Uparrow 0_{\mathcal{Q}}(a) \ \blacksquare
\end{array}
$$

</div>

$normalize_{\mathcal{Q}}(x)$ reduces the size of the dividend and divisor, and ensures that any negative sign is in the dividend. Let $g = GCD(x, y)$. Then $normalize_{\mathcal{Q}}(\frac{x}{y}) = \frac{x \odiv g}{y \odiv g}$.

<div class="math-left">

$$
\begin{array}{l}
normalize_{\mathcal{Q}}(x) \Leftarrow \\
\quad \textbf{local } g,\ top,\ bottom \\
\quad g \mathrel{:=} GCD(x.dividend, x.divisor) \\
\quad top \mathrel{:=} \odiv(x.dividend, g) \\
\quad bottom \mathrel{:=} \odiv(x.divisor, g) \\
\quad \Uparrow (\textbf{if } <0(bottom) \textbf{ then } Q(-(top), -(bottom)) \\
\quad\quad \textbf{else } Q(top, bottom)) \ \blacksquare
\end{array}
$$

</div>

```icon

d8g_Q (X) 4= it X ■
```

**Predicates.**

$\frac{p}{q} = \frac{p'}{q'}$ if and only if $pq' = qp'$.

<div class="math-left">

$$
\begin{array}{l}
=_{\mathcal{Q}}(a, b) \Leftarrow \Uparrow (=(\otimes(a.divisor, b.dividend), \otimes(b.divisor, a.dividend))) \ \blacksquare
\end{array}
$$

</div>

Everything is a unit in $\mathcal{Q}$.

<div class="math-left">

$$
\begin{array}{l}
unit_{\mathcal{Q}}(x) \Leftarrow \Uparrow \ \blacksquare
\end{array}
$$

</div>

**Commands.**

<div class="math-left">

$$
\begin{array}{l}
print_{\mathcal{Q}}(x) \Leftarrow \\
\quad \textbf{if } =(x.divisor, 1(x.divisor)) \\
\quad \textbf{then } prs\{x.dividend,\ \text{"q"}\} \\
\quad \textbf{else } prs\{\text{"("},\ x.dividend,\ \text{"/"},\ x.divisor,\ \text{")q"}\} \ \blacksquare
\end{array}
$$

</div>


#### 2.3.2. Modular Euclidean domain $D/(x)$

<p align="center"><strong>Modular Domain Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $modulo$ |
| **Constants** | $0_{modulo}$, $1_{modulo}$ |
| **Operators** | $\oplus_{modulo}$, $-_{modulo}$, $\otimes_{modulo}$, $\odiv_{modulo}$, $normalize_{modulo}$, $deg_{modulo}$ |
| **Predicates** | $=_{modulo}$, $unit_{modulo}$, $<0_{modulo}$ |
| **Commands** | $print_{modulo}$ |

**Data structures.**

An item from a modular domain, say $Z_5$, is specified by the item in the “base” domain, plus the modulus.

<div class="math-left">

$$
\begin{array}{l}
\textbf{record } modulo\ (item, modulus)
\end{array}
$$

</div>

**Constants.**

<div class="math-left">

$$
\begin{array}{l}
0_{modulo}(a) \Leftarrow \Uparrow modulo(0(a.item), a.modulus) \ \blacksquare \\
1_{modulo}(a) \Leftarrow \Uparrow modulo(1(a.item), a.modulus) \ \blacksquare
\end{array}
$$

</div>

**Operators.**

<div class="math-left">

$$
\begin{array}{l}
\oplus_{modulo}(a, b) \Leftarrow \Uparrow normalize_{modulo}(modulo(\oplus(a.item, b.item), a.modulus)) \ \blacksquare \\
-_{modulo}(x) \Leftarrow \Uparrow normalize_{modulo}(modulo(-(x.item), x.modulus)) \ \blacksquare \\
\otimes_{modulo}(a, b) \Leftarrow \Uparrow normalize_{modulo}(modulo(\otimes(a.item, b.item), a.modulus)) \ \blacksquare \\
\odiv_{modulo}(a, b) \Leftarrow \Uparrow normalize_{modulo}(modulo(\otimes(a.item, INVERSE(b.item, b.modulus)), a.modulus)) \ \blacksquare \\
\\
normalize_{modulo}(x) \Leftarrow \Uparrow modulo(mod(x.item, x.modulus), x.modulus) \ \blacksquare \\
deg_{modulo}(x) \Leftarrow \Uparrow mod(x.item, x.modulus) \ \blacksquare
\end{array}
$$

</div>

**Predicates.**

<div class="math-left">

$$
\begin{array}{l}
=_{modulo}(a, b) \Leftarrow \Uparrow (=(mod(a.item, a.modulus), mod(b.item, b.modulus))) \ \blacksquare \\
unit_{modulo}(a) \Leftarrow \Uparrow (=(\$mod\$(a.item, a.modulus), 1)) \ \blacksquare
\end{array}
$$

</div>

Nothing is negative in a modular domain.

<div class="math-left">

$$
\begin{array}{l}
<0_{modulo}(a) \Leftarrow \bot \ \blacksquare
\end{array}
$$

</div>

**Commands.**

<div class="math-left">

$$
\begin{array}{l}
print_{modulo}(x) \Leftarrow prs\{\text{"("},\ x.item,\ \text{" mod "},\ x.modulus,\ \text{")"}\} \ \blacksquare
\end{array}
$$

</div>


#### 2.3.3. Polynomial Euclidean domain $D[x]$

<p align="center"><strong>Polynomial Domain Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $poly$, $term$; $poly\_of$, $0th\_coef$, $lead\_coef$ |
| **Constants** | $0_{poly}$, $1_{poly}$, $k_{Z_Q}$, $k_{Z_{Qx}}$, $k_{Z_x}$ |
| **Operators** | $\oplus_{poly}$, $-_{poly}$, $\otimes_{poly}$, $\odiv_{poly}$, $mod_{poly}$, $eval_{poly}$, $deg_{poly}$, $-_{deg}$, $\oplus_{deg}$, $normalize_{poly}$ |
| **Predicates** | $<_{degree}$, $=_{poly}$, $unit_{poly}$ |
| **Commands** | $print_{poly}$ |

**Data structures.** Polynomials $a(x) \in D[x]$ are finite sums of the form

$$a(x) = \sum_{i=0}^{m} a_i x^i$$

They are represented as lists of terms, in increasing order of power, such that there is always at least one term, 0, if the polynomial is zero. Otherwise the least term may be of any degree.

<div class="math-left">

$$
\begin{array}{l}
\textbf{record } poly\ (terms) \\
poly\_of(x) \Leftarrow \Uparrow poly([term(x, 0)]) \ \blacksquare
\end{array}
$$

</div>

The coefficient of the constant term as an element of $D$, if there is a constant term, otherwise 0, may be obtained with:

<div class="math-left">

$$
\begin{array}{l}
0th\_coef(fx) \Leftarrow \\
\quad \textbf{local } a \\
\quad a \mathrel{:=} fx.terms[1] \\
\quad \Uparrow (\textbf{if } a.power = 0 \textbf{ then } a.coef \textbf{ else } 0(a.coef)) \ \blacksquare
\end{array}
$$

</div>

The coefficient of the term with the highest degree may be obtained with:

<div class="math-left">

$$
\begin{array}{l}
lead\_coef(ax) \Leftarrow \Uparrow (ax.terms[\texttt{*}ax.terms]).coef \ \blacksquare
\end{array}
$$

</div>

A term, say $ax^n$, is represented as $coef \cdot X^{power}$. It is assumed that coefficient and indeterminate range over the same base domain, and that the power ranges over $\mathcal{N}$.

<div class="math-left">

$$
\begin{array}{l}
\textbf{record } term\ (coef, power)
\end{array}
$$

</div>

**Constants.**

The zero of the base domain of a coefficient of the polynomial is obtained via:

<div class="math-left">

$$
\begin{array}{l}
0_{poly}(p) \Leftarrow \\
\quad z \mathrel{:=} 0(p.terms[1].coef) \\
\quad \Uparrow poly([term(z, 0)]) \ \blacksquare
\end{array}
$$

</div>

**Example.** The result of evaluating

<div class="math-left">

$$
\begin{array}{l}
\text{pr}\{\text{"Q:    0 = "},\ 0_{poly}(poly([term(Q(-2,1), 0)]))\} \\
\text{pr}\{\text{"QZ:   0 = "},\ 0_{poly}(poly([term(k_{Z_{Qx}}(-2, 0)]))\}
\end{array}
$$

</div>

is

$Q\text{:    0 = }0_q$  
$QZ\text{:   0 = }0_{zq}$

The one of the base domain of a coefficient of the polynomial may be obtained with: 

<div class="math-left">

$$
\begin{array}{l}
1_{poly}(p) \Leftarrow \\
\quad z \mathrel{:=} 1(p.terms[1].coef) \\
\quad \Uparrow poly([term(z, 0)]) \ \blacksquare
\end{array}
$$

</div>

An arbitrary-precision rational whole number is obtained with:

<div class="math-left">

$$
\begin{array}{l}
k_{Z_Q}(e) \Leftarrow \\
\quad top \mathrel{:=} k_Z(e) \\
\quad \Uparrow Q(top, 1_Z(top)) \ \blacksquare
\end{array}
$$

</div>

An arbitrary-precision rational whole number-coefficient indeterminate $e x^y$ is obtained with:

<div class="math-left">

$$
\begin{array}{l}
k_{Z_{Qx}}(e, y) \Leftarrow \Uparrow term(k_{Z_Q}(e), y) \ \blacksquare
\end{array}
$$

</div>

An arbitrary-precision integer-coefficient indeterminate $e x^y$ is obtained with:

<div class="math-left">

$$
\begin{array}{l}
k_{Z_x}(e, y) \Leftarrow \Uparrow term(k_Z(e), y) \ \blacksquare
\end{array}
$$

</div>

**Operators.**

<div class="math-left">

$$
\begin{array}{l}
\oplus_{poly}(a, b) \Leftarrow \\
\quad \textbf{local } Terms,\ T,\ z \\
\quad Terms \mathrel{:=} \oplus_{terms}(a.terms, b.terms) \\
\quad T \mathrel{:=} [];\ z \mathrel{:=} 0(a.terms[1].coef) \\
\quad \textbf{every } t \mathrel{:=} \texttt{!}Terms \textbf{ do if not } =(t.coef, z) \textbf{ then } T \ |||{:=}\ [t] \\
\quad \Uparrow (\textbf{if } \#T > 0 \textbf{ then } poly(T) \textbf{ else } 0(a)) \ \blacksquare
\end{array}
$$

</div>

<div class="math-left">

$$
\begin{array}{l}
\oplus_{terms}(a, b) \Leftarrow \\
\quad \textbf{local } c\_coef,\ at,\ ap,\ ac,\ bt,\ bp,\ bc \\
\quad \Uparrow ( \\
\quad\quad \textbf{if } *a = 0 \textbf{ then } b \\
\quad\quad \textbf{else if } *b = 0 \textbf{ then } a \\
\quad\quad \textbf{else } \{ \\
\quad\quad\quad at \mathrel{:=} a[1];\ ap \mathrel{:=} at.power;\ ac \mathrel{:=} at.coef \\
\quad\quad\quad bt \mathrel{:=} b[1];\ bp \mathrel{:=} bt.power;\ bc \mathrel{:=} bt.coef \\
\quad\quad\quad \textbf{if } less(ap, bp) \\
\quad\quad\quad \textbf{then } \{ \\
\quad\quad\quad\quad \textbf{if } =(ac, 0(ac)) \\
\quad\quad\quad\quad \textbf{then } \oplus_{terms}(rest(a), b) \\
\quad\quad\quad\quad \textbf{else } [at] \ || \ \oplus_{terms}(rest(a), b) \} \\
\quad\quad\quad \textbf{else if } =(ap, bp) \\
\quad\quad\quad \textbf{then } \{ \\
\quad\quad\quad\quad c\_coef \mathrel{:=} \oplus(ac, bc) \\
\quad\quad\quad\quad \textbf{if } =(c\_coef, 0(c\_coef)) \\
\quad\quad\quad\quad \textbf{then } \oplus_{terms}(rest(a), rest(b)) \\
\quad\quad\quad\quad \textbf{else } [term(c\_coef, ap)] \ || \ \oplus_{terms}(rest(a), rest(b)) \} \\
\quad\quad\quad \textbf{else } \oplus_{terms}(b, a) \} \\
\quad ) \ \blacksquare
\end{array}
$$

</div>

**Example.** The result of evaluating 

<div class="math-left">

$$
\begin{array}{l}
ax \mathrel{:=} poly([term(Q(-2,1), 0), term(Q(1,1), 3)]) \\
bx \mathrel{:=} poly([term(Q(-3,1), 0), term(Q(2,1), 3)]) \\
fx \mathrel{:=} poly([k_{Z_{Qx}}(-2, 0), k_{Z_{Qx}}(1,3)]) \\
gx \mathrel{:=} poly([k_{Z_{Qx}}(-3, 0), k_{Z_{Qx}}(2,3)]) \\
\text{pr}\{\text{"Q: ("},\ ax,\ \text{") + ("},\ bx,\ \text{") = "},\ \oplus_{poly}(ax, bx)\} \\
\text{pr}\{\text{"QZ: ("},\ fx,\ \text{") + ("},\ gx,\ \text{") = "},\ \oplus_{poly}(fx, gx)\}
\end{array}
$$

</div>

is

$Q\text{: }(-2)q + 1q \cdot X^3) + ((-3)q + 2q \cdot X^3) = (-5)q + 3q \cdot X^3$  
$QZ\text{: }((-2z)q + 1zq \cdot X^3) + ((-3z)q + 2zq \cdot X^3) = (-5z)q + 3zq \cdot X^3$

<div class="math-left">

$$
\begin{array}{l}
-_{poly}(x) \Leftarrow \\
\quad \textbf{local } c \\
\quad c \mathrel{:=} [] \\
\quad \textbf{every } t \mathrel{:=} \texttt{!}x.terms \textbf{ do } c \ |||{:=}\ [-_{term}(t)] \\
\quad \Uparrow poly(c) \ \blacksquare \\
\\
-_{term}(t) \Leftarrow \Uparrow term(-(t.coef), t.power) \ \blacksquare
\end{array}
$$

</div>

**Example.** The result of evaluating

<div class="math-left">

$$
\begin{array}{l}
ax \mathrel{:=} poly([term(Q(-2,1), 0), term(Q(1,1), 3)]) \\
fx \mathrel{:=} poly([k_{Z_{Qx}}(-2, 0), k_{Z_{Qx}}(1,3)]) \\
\text{pr}\{\text{"Q:  - ("},\ ax,\ \text{") = "},\ -_{poly}(ax)\} \\
\text{pr}\{\text{"QZ: - ("},\ fx,\ \text{") = "},\ -_{poly}(fx)\}
\end{array}
$$

</div>

is

$Q\text{:  - }((-2)q + 1q \cdot X^3) = 2q + (-1)q \cdot X^3$  
$QZ\text{: - }((-2z)q + 1zq \cdot X^3) = 2zq + (-1z)q \cdot X^3$

<div class="math-left">

$$
\begin{array}{l}
\otimes_{poly}(a, b) \Leftarrow \Uparrow \otimes_{poly\_terms}(a, b.terms) \ \blacksquare \\
\\
\otimes_{poly\_terms}(a, b\_terms) \Leftarrow \\
\quad \Uparrow (\textbf{if } \#b\_terms = 0 \textbf{ then } 0(a) \\
\quad\quad \textbf{else } \oplus_{poly}(\otimes_{poly\_term}(a, b\_terms[1]), \\
\quad\quad\quad \otimes_{poly\_terms}(a, rest(b\_terms)))) \ \blacksquare
\end{array}
$$

</div>

<div class="math-left">

$$
\begin{array}{l}
\otimes_{poly\_term}(a, b\_term) \Leftarrow \\
\quad \Uparrow (\textbf{if } *a.terms < 2 \\
\quad\quad \textbf{then } poly([\otimes_{term\_term}(a.terms[1], b\_term)]) \\
\quad\quad \textbf{else } \oplus_{poly}(poly([\otimes_{term\_term}(a.terms[1], b\_term)]), \\
\quad\quad\quad \otimes_{poly\_term}(poly(rest(a.terms)), b\_term))) \ \blacksquare \\
\\
\otimes_{term\_term}(a\_term, b\_term) \Leftarrow \\
\quad \Uparrow term(\otimes(a\_term.coef, b\_term.coef), a\_term.power + b\_term.power) \ \blacksquare
\end{array}
$$

</div>

**Example.** The result of evaluating

```icon
ax := poly(Itorm(j2{-2,1), 0), torm(j2(1.'l). 3)])
bx := poly([torm(^(-3,l), 0), term(^(2,1), 3)1)
```

fx := poly(I^Z5jf(-2. 0). ^fZfixd.S)!)

```icon
gx := poly([/rZi2x(-3. 0), A:Zj2x (2.3)1)
prffi:
```

(". ax. “) * bx. ") = ". ®(ax. bx)} prfQZ: r. fx. ") • (". gx. ") = ”, ®(fx. gx)} ({-2)^ + 1q*X*3) * ((■3)q + 2q*X‘3) = 6q + (-7)q*X*3 + 2q*X*6 Q2: ((■22)q + 1zq*X*3) * {(-32)q + 2zq*X*3) = 6zq + (-72)q*X‘3 + 2zq*X*6 ®poiy (a. b) local n. m. r. q. quotient

```icon
n := degpoiy{.t)
r := copy(a)
quotient := Opofy(r)
repeat { m := rfegpo/y(r)
then 'I} quotient
else { q := poly([term(\odiv(ZeaJco</<f)7eac?coe/b)).m-n)])
Enciidean domains: representation and basic arithmetic
If m = 0
then -ft-\odivpoiyCquotient, q)
• Ise { subtrand := ~pofy(®pofy(q. b))
r := \odivpo/y(r. subtrand)
- quotient := \odivpo/y(quotlont, q)
```

Example. The result of evaluating

```icon
ax := poly_of(1): bx := poly_of(3)
prpintegers: ", ax, "T, bx, " = ", \odivpoj^(ax, bx)}
poly(Iterm(fi(5,9), 0)])
poly(Iterm(i2(-2,1), 0), term(^2(3,2), 1)])
fx := poly ([term (j2(A:2(5),^2(9)), 0)])
gx poly([term(j2(^21'2).^2O))’ tef'”(fi(^7(3).^2(2)), 1)1)
pr{"fi:
(", ax, ") ! (", bx, ") = ", \odivpofy{»^. bx)}
pr{"QZ:
```

C. gx. ") ! (", fx, ") - ", \odivpoiyig^. fx)}

```icon
ax := poly(lterm((2()5:2(166), Jt2(243)), 0), term(i2(fcz(-275),fc2(243)),1)l)
bx := poly([term(i2(^2(‘'''®®®®)' ^2(^5625)), 0)])
pr{"QZlx]; ax, "I ", bx, ") = 0", \odiv(ax, bx)}
integers: 1/3 = 0
((5/9)q)/((•2)q + (3/2)q*X) - Oq
QZ:
((-2z)q + (32/2z)q*X) ! ((5z/9z)q) = ((-18z)/5z)q + (272/10z)q*X
QZlx): ((166z/243z)q + ((-275z)/243z)q*X / (1156682/75625z)q) =
(6276875z/14053662z)q + ((•20796875z)/28107324z)q*X
Enclidean domains: representation and basic arithmetic
modpoiy (a, b) ■<= -ft \odiv(a, ®(b, \odiv(a, b))) ■
Evaluate /(x) at a, that is evaluate /(a):
evalpofy (fx, a)
local r
ovary x := Ifx.tarma do r :« @(r, evaltermi.^^ *))
Evaluate cx^ 3.1 x=a'.
eval,„n (t. a) 4= H®n.coof, axp(a, t.power)) ■
Degrees of polynomials are values which may be integers, or the string
Accordingly, special subtraction and addition procedures are required.
degpoiy (X) <=
-poly(^> ^polyM} than -jy Infinity"
also fl* x.terms[*x.terms].power
dtg (a. b)
■f) (If type(a) == "string" then b
r r-
else If type(b) == "string" then a
else a - b)
■fy (If typo(a) == "string" then b
else If type(b) == "string" then a
Euclidean domaini: repreientation and basic arithmetic
else a + b)
```

A normal-form polynomial is one whose terms are in normal form (and in ascending order of power).

```icon
normalizepoiy (x) <=
```

every t Ix.terma do ts 11]:= [term(normalize(i.co»1), t.power)] ^poly(t8) Predicates. ^degree (*•

```icon
If type(a) == "string"
then "ftnot (type{b) == "string")
else -(I a < b
—poly b) 4= 11 =»ermj (a.terms. b.terms) ■
— arms (®«
If ’a "= *b then ±
If *a = 0 then li-
```

lt = r«Tn{aI1l. bPl) then 11 -termj(rest(a). restfb)) — term («• h) 4= 11( = (a.coef, b.coef) & ={a.power, b.power)) K

```icon
unitpoiy W IKCx.terms = 1) & (x.term8[1l.power = 0) 4 «nif(x.term8(11.coef)) ■
```

Commands. Enclidean domains: representation and basic arithmetic

```icon
printpoiy (x) <=
print,erm{x.tarms[1])
•very t := Irest(x.terms) do { wrltosf" + "); print term (t) }
printterm (X) 4=
print(x.coef)
if X.power = 1 then write8(”*X")
else If X.power > 1 then prsC’X*", x.power}
```


#### 2.3.4. Truncated Power Series domain r(F[[x]])„.

Truncated Power Series Domain Arithmetic Facilities Data structures tpower Constants ^tpower t ^tpower Operators ®tpowerr ~g>owert ^tpowert \odivtpowert normalizetpower Predicates ~ tpower f ^^^^^ower Commands printtpower Data structures.

```icon
record tpower (Poly, N)
```

Constants. The zero of the base domain of a coefficient of the polynomial:

```icon
^tpower (X) ■«J= -JhtpowerfOpoz/x.Poly), x.N)) ■
```

The one of the base domain of a coefficient of the polynomial:

```icon
Iqjwer (x) <= 1} tpowor(l^o/y{x.Poly), X.N) ■
```

Operators. Qtpower («. b) -4=

```icon
b.Poly), a.N) ■
-tpowtr (X) <= Ittpowert-poZyfx.Poly). x.N) ■
truncate (p, n) <= -(t poly(p.termslV.n + 1l) ■
```

®ipow«- (a. *») <= ■(ttpowor(truncat8(®poly(a.Poly. b.Poly). a.N), a.N) ■ $\odiv$9»0H-er

```icon
**) •()^tpower(truncate(\odivpo/y(a.Poly, b.Poly), a.N), a.N) ■
normalize,p„^„ (x) -<= Ittpower(norma/zzfipoZy(x.PoIy). x.N) ■
```

Predicates. “ipmver (a. b) f (a.N = b.N) 4 =po/y(a.Poly. b.Poly) ■

```icon
unittpo^er (X) <= -ft uni/poZy(x-Poly) ■
```

Commands.

```icon
printpon'er (X) <= printpofy(^.PoW} ■
Algorithm! for Tarioos problems over Enclidean domains
```


## 3. Algorithms for various problems over Euclidean domains

We provide algorithms for number of application areas: • GCD, linear congruences and Diophantine equations. • Polynomial remainder sequences. • Power series and polynomial inversion and interpolation. Tn addition, we provide a simple timer facility.


### 3.1. GCD, Linear Congruences and Diophantine Equations

We provide algorithms for the following applications: <» Euclid’s algorithm for greatest common divisor, in simple and extended • versions. • Inverse of a $mod$ m. • The Chinese Remainder for 1, 2 or N congruences. • The solutions to the Diophantine equation ax + by = c.


#### 3.1.1. Greatest Common Divisor

We have two versions of Euclid’s Algorithm over a Euclidean domain D, from Lipson, p.

```icon
GCD(a,h,D)
Input: a,h€D, not both zero.
Output: a gcd of a,b.
GCD (a, b) <= "ft (If *(b, 0(b)) then normalize(&} else GCD(b, mod(a, b))) ■
```

The following is a table of expressions and their gcd's, as computed via GCD: AlforithiBf for Tsrioni problwnt over Encltdosn doniolnt Greatest Common Divisors Domain GCD S333z *lSz Z5[x] ((-2) $mod$ 5)+(l $mod$ 5)*X*3 (3$mod$5)+(4$mod$5) "X QZtx] (166zZ243z)q + ((-275z)/243z)q*X QZ[x] (-2z)q + lzq’X*3 (5z/9z)q EUCUD{a,b) Input: a,h€D, not both zero. Output: g,s,t such that g is a ged of fl, b and g=jfl+rb.

```icon
EUCLID (A. B)
local q, a, a, t
```

a := [copy(A), copy(B)]

```icon
while not(®=(a(2]. 0(A))) do
```

a := (a[21. e(a[1l. ®(al21. q))] a (•[21. e(sI1l. 0(8(21. q))l t ItI21. e(tll]. ®(tI21. q))] } ■fl' [nflrmfl/zze(aI1]). normalize(9{'\]), nflZ7nfl/ize(tI1l)l Algoritlimi for ▼ariooi problem* over Enclidean domains The following is a table of expressions and their extended gcd’s, as computed via EUCLID: Extended Greatest Common Divisors A, B GCD, s, t (5/9)q, (.16/9)q-»-(-4/3)q’X, lq-h(8/9)q’X+(2Z3)q’X^ (.2$mod$5)+(lmod5)*X3. (-3$mod$5)+(2$mod$5)’X^) (3$mod$5)-t-{4$mod$5)’X, (Imod 5), (2$mod$5)*X


#### 3.1.2. Modular Inverse

Our modular inverse algorithms is that of Lipson, p. 214. INVERSE{a,m): Computation of a~^modm Input: a,m€D, where D is a Euclidean domain. Output: If then a~^modm: otherwise error.

```icon
INVERSE (a. m) 4=
local gst
gat := EUCLID(m, a)
If unit (gstllj) then -ftwod (\odiv (gstI3], gstll]), m)
also pr{*’E R R O R: a, "“-1 ", " mod ", m, " doaa not exist"}
```

A table of modular inverses as computed by INVERSE is as follows: modulus ERROR (lmod2)-f-(lmod2)*X*2 (lmod2)+(lmod2)’X*2-l-(lmod2/X‘5) (lmod2)-t-(lmod2)*X-t- (lmod2) •X*2 -t- (Imodl) ‘XM (9/5)q -1- (8/5)q*X + (6/5)q*X-2 Algorithm! for Tarlont problem! over Enclldean domain!


#### 3.1.3. Chinese Remainders and Single-Variable Linear Congruential

Systems We provide three algorithms, CRAl for solving equations of the form a x ■« b $mod$ m, and CRA2 and CRA for solving systems of equations of 2 or more congruences of the form X ■■ a $mod$ m. CRAl (a, b, m): Solution of a single linear congruence relation. Input: a,b,m such that a x ■« b $mod$ m. Output: a particular solution xi. Niven and Zuckerman [NivenSOa], in their section 2.3 note that, given a congruence ax^bmodm^ we can reduce it to my^— bmoda. If yo is a solution of the reduced (myo+^) congruence, then xo=-------------is a solution for the origmal congruence. They apply the reduction until the congruence is solvable “by inspection’’. This we do not do. They also have some tricks for size reduction (on p. 43) we will not apply (due to laziness). Our “by inspection’’ termination condition will be to perform the reduction until a $mod$ m=l or b—Q. Then we return b $mod$ a, in a recursive setting which builds up the original x q .

```icon
CRAl (la, bb, m) <=
local a, b, g
g GCD(aa, m)
If not |(g, bb) than pr{”ERROR: no solution to linear congruence"}
else { a :— mod(»a, m); b := mod(hb, m)
If =(a, 1(a)) then b
else If =(b, 0(b)) then i)O(b)
else If =(a, b) then-f)-1(b)
```

else fl-$\odiv$($\odiv$(®(m. CRA1 (m. -(b), a)), b), a) } Algorithm! for ▼arioni problem! over Enclidean domain! Example. The following results were obtained from executing CRAl (the examples are from Niven and Zuckerman [NivenSOa], Sect. 2.3: • C2?A(7,1432,5317): x such that 7x-14327noJ5317 is 4762. • C/?A(863,880,2151): x such that 863x»880nioJ2151 is 173. • C22A(589,5O9,817): There is no x such that 589x"'509/nod817. CJ?A2 and CRA aic from Lipson, p. 254 and p. 257. CRA2 (r, m, s, n): Two-congruence Chinese Remainder Algorithm for Z Input: r,ni,j,n€Z, where n,/n are relatively prime. Output: tZ€Z such that U"*rmodm, U^smodn. CRA2 (r. m. a. n) <=

```icon
local c, a, U
c :— INVERSE(m. n)
ff :=
P/rampU- The X such that x"*6mod’l and x»3mod9 is 48, as obuined by evaluating
CRA (rmjist): N-congruence Chinese Remainder Algorithm for Z
Input: [[r*,mjt]]€Z, where the ixt relatively prime. Output: CZ€Z such that U^riinodmi.
CRA (rmJIst) <=
local rms, rm, M , U , c, tr
rms := copy(rm_ll!t)
rm := pop(rms); r rmllj; m ;= tm[21
U := mod(i, m)
ovary k := 1 to *rm! do
rm := popCrms); r rrnll]: m := rmI21
c := INVERSE(M. m)
Algorithm I for ▼arioni problems over Eaclidean domains
```

CT := TOoJ(®(e(r. TOod(U. m)). c), m) Example. The problem is to find u(x) in Z[x] such that u(x)$mod$3=x, u{x)modl= 1,

```icon
M(x)moJ4=2x+3, and
tt(x)mcwi5=3x+3
```

Let u(x)=ax+b. Then a $mod$ 3=1 b $mod$ 3 = 0 a $mod$ 7 = 0 b $mod$ 7=1 a $mod$ 4 = 2 b $mod$ 4 = 3 a $mod$ 5 = 3 We can solve for a and b individually using the n-congruence CRA algorithm, and we are done. Executing the following code:

```icon
a_congruonco8 := HI, 3], 10, 7], [2, 4], [3, 5]]
b_congruonco8 := tlO, 31, [1, 7], 13, 4], (3, 51]
```

a := CRA(a_congru8nc88)

```icon
b := CRA(b_congru8nc88)
ux := poly([t8rm(b, 0), t8rm(a, 1)])
pr{"u(x) = ", ux}
```

we discover (final term due to Yap) that m(x ) = 183+238*X+3-7-4-52^iX*. Example. Another example, from Lipson, p. 258, is to compute u such that M"l(m<x/3) u«‘3(moJ5) u^Q{modl) u^lOCmodll) Executing the following code pr{CRA{U1. 3], 13, 5], [0, 7], (10, 1111)} yields a value of 868 for U.


#### 3.1.4. Linear Diophantine Equations in Two Variables

According to Niven, sect. 5.2, ax+by—c is solvable iff g\c where g=gcd(a,b). If gjc then all solutions are of the form x=xi+(—)t,y=yi-(-7)t where f is an arbitrary integer and x=xi, y=yi is any particular solution of the equation. Particular solutions are obtained by solving one of the linear congruences ax“cmod|bl,by"C7nod|fll for XI or yi, then substituting yi or xi into ax+by=c to obtain a particular yi or xi. For computational convenience, if lh|s|a|, we solve the first congruence, otherwise we solve the second.

```icon
DIOPHANTINE (a, b, c); solves linear Diophantine equations in 2 variables.
Input: a,b,c such that ax+by=c. Output; g,xi,yi, described above.
DIOPHANTINE (a, b, c) -4=
local gst, g, xi, yi
gat := EUCLID(a. b)
g := gattll: t ;= gst[3]
If not |(g, c) than prf'ERROR: Diophantine solution nonexistent**}
else { if <{abs(h). abskt.))
then { xj := CRA1(a, c, ahj(b))
•Is® { yi CRA1(b, c, ab5(a))
```

XI := $\odiv$(e(c, ®(b. yi)). a) } -n-Ig.xi.yi] } Example. By evaluating D/OPHANrZN£(84,54,-24), we find that all integer solutions (x,y) of the equation 84x+54y=(—24) are of the form x=l + 9t, y=(—2) —14t. Example. By evaluating DZOPHANrZNE(999,-49,5000), we find that all integer solutions (x,y) of the equation 999x+(—49)y=5000 are of the form x=13+49t, y- 163-(-999)f. Example. By evaluating DZOPHA2V77N£(247,589,817), we find that all integer solutions (x,y) of the equation 247x+589y=817 are of the form x=( —ll)+31t, 4y=6— 13t. 3-2 Polynomial remainder sequences Polynomial remainder sequences are studied as a method of finding variants of the greatest common divisor for elements of integral domains. Variation in the definition is required because integral domains do not support long division. It is also desirable to compute values which share properties of the greatest common divisor (which might then be reclaimed by homomorphic image methods; see Lipson, ch. 8), such that the computation does not suffer the large coefficient growth of Euclid’s algorithm on even moderate-sized polynomials. Yap [Yap85a] discusses the issue, presenting an example of Knuth exhibiting the coefficient growth problem. Polynomial remainder sequences are discussed in greater depth in the paper by Loos [Loosa]. We have implemented three variants of polynomial remainder sequence: • $mod$-based PRS. • prem, a pseudo-remainder for division over integral domains, and a •prem-based PRS, as defined in Yap |Yap85a]. • Subresultant PRS, as defined in Yap [Yap85a] and based on an algorithm of • Collins, as presented by Brown. 3.2.1 MOD-based PRS The simplest polynomial remainder sequence is simply that of Euclid’s algorithm. That is, we define MOD_RS{a,b) to be the PRS of $mod${a,b).

```icon
MOD.RS (a, b) 4= -ft l»l 11 (W =(b. 0(b)) then [b] else MOD_RS(b, mod(a, b))) ■
```

Example. In Qz[x], the remainder sequence of as encoded in ICON by settimeO

```icon
ax := poly(lJkZfix(2. 0).
2), kZ^x^^.A}. ^Zfixd-S)!)
bx := poly([fcZfix(2, 0),
I)- ^ZfixO- 3)1)
```

pr{"QZ[xl; MOD_RS(", ax. ",0", bx. ") = 0. MOD_RS(ax. bx)} Algorithma for Tarioas problems over Euclidean domains ahowtImeO QZIxl: MOD_RS(2zq + (■1z)q*X + 3zq*X‘2 + 2zq’X*4 + 1zq’X 5. 2zq + (-1z)q*X + 3zq*X“3) = I2zq + (-1z)q*X + 3zq*X*2 + 2zq*X‘4 + 1zq*X*5, 2zq + (-1z)q*X + 3zn*X‘3, (16z/9z)q + ((-20z)/9z)q*X + 3zq*X*2, (166z/243z)q + ((-27 5z)/243z)q*X, Ozql

```icon
[221033 msecs]
3.2.2 Pseudo-remainder for division over integral domains
PREM(px, qx): Pseudo-remainder of -^px,qx^I[x}
where Z[x] is an integral domain.
Method:
```


## 1. Let deg(jf)-deg{q') 2. Let b lead coefficient of q(x) 3. Return rem(h‘^'^^px,9x)

```icon
PREM (px, qx) <=
local d, b
d := -deg {degpoiy{p^}. degpoiyi^^}}
b := poly_of(/ea/icoe/(q x))
```

■(y rem(®po/y(exP (b. d + l), px). qx) Example. The following table lists values and their pseudo-remainders. Algorithm! for Tarions problems over Enclidean domains Domain prem(p, q) QZlx] 2DO5427Uz+1785a34z*X StSX2Simi6tST3l82S2MOz -S8S12S9Z798467382S246000000000000Z QZlx] 21z+(.9z)*X+(.4i)’r2+5z*X‘4+3z*X‘6 (-39S35z)+3Q375zTC+15795z*X:2 QZlxl 22q+(-lz)q’X+3zq*X^+22q’X’4+lxq*X‘6 2xq+(-li)q*X+3zq*y3 198zq+(-225z)q*X+306zq’X^ QZlx] 198zq+(-2252)q*X+306zq*X3 iauj+369zq*X iniegen[x] 3.2.3 PREM-based PRS

```icon
E_PRS(a, b): Euclidean polynomial remainder sequence.
I.e., a trace of the steps of Euclid’s algorithm modified to use PREM.
E_PRS (a. b) <=
[a] Bl (If “(b. 0(b)) then [bl else E_PRS(b, PREM{a, b))) ■
3.2.4 Subresultant PRS
```

The following algorithm is the Collins-Brown subresultant PRS algorithm, as presented in Yap [Yap85a].

```icon
S_PRS(pO, pl): Subresultant polynomial remainder sequence.
Input: polynomials
```

for some integral domain Z. Output: Subresultant PRS (potPi.-P*) such that pjt+i=O. Let 8,=deg(p,)-rfeg(p,+i). Let Ci=^lead{pi). Let (Ri.Ri ' ■ ' be a sequence of length k defined by Ri=ci®° Let (P2.P3 ■ * ‘ Pi) be a sequence of length k— 1 defined by 3i=((-l)^^*®”’bc.-2((R'"2)’“’)./=3..;: Then we wish to compute the sequence (po.Z’i>”Pi) ot length A:+l such thatpo andpi are given polynomials, and prem{pi-x,pi-2) , --------- Z--------- ,1-2..k. S_PRS (po. Pl) <=

```icon
local Sq, ^2’ P2> P > ^1> Initial values
# Iterate values
So := 8,(po' Pl)
Sequence Initial values
cO := C/(po)
P2 := poly_of(exp(-(l(cO)), Sq+I))
P2 := PiipO’Pl. P2): z := 0(p2)
```

If =(P2. ^) then H tPo. Pll 2?1 := exp(c,(pi), Sq) 8,•-2 := ^dPl’Pl) Loop Iterate Initialization, P,-

```icon
Ci-2 := Ci(pi)
Ri-2
Pi-2 := Pl
#torpf
repeat {
p,- := p/ (8|_2, Ci-2, Ri-2)
```

Pi ■= Pi (Pi-2. Pi-1. Pi) If =(pi, z) then -ft- P else P ||:- [p,] Pi-2 Pi-1 Pi-1 •- Pi Ci~2 ■— Ci(pi-2)

```icon
Pi-2 := Ri(Ci-2. 8i_2, Ri-2)
8i {Pi, Pi-¥1) (y <leg(^^Spofy(Pi)> ^^Spoly(Pi+l)) ■
Ci {Pi) <= -ft &adc«!f(Pi) ■
/?i {Ci, S,-—!, Pj —1) 4=
```

exp(P,_i. -<fe,(8,_i. 1))) Pi (8i-2. C,—2. /?»-2) <= ■ft poly_of(®(®(oxp(-(l(c/-2)). Pi {Pi-2. Pi-1. Pi) <= -ft $\odiv$(P R E M {Pi-2. Pi-1}. Pi) ■ 3*3 Power series and polynomial inversion and interpolation Under this heading we provide the following facilities; • Newton’s method for construction of polynomials by interpolation. • Fast Fourier Transform (FFT) and Interpolation (FFI). • Newton’s method for truncated power series inversion. 3.3.1 Newton’s method for construction of polynomials by interpolation NIA (rm_list); Newton’s Interpolation Algorithm (CRA for F[x]) Input: [[ak, bk]] such that U(ak) = bk, U(x) € F[x] Output: U(x)

```icon
N lA (abjist) 4=
local ab_s. ab, a, b, Ux, Mx, c, a
ab_8 :« copy(ab_ll8t)
ab := pop(ab_8); a :« ab(1J; b := ab[2]
Ux := poly_of(b)
Mx := l(Ux)
```

every k ;= 1 to *ab_$ do

```icon
{ Mx := ®{Mx, \odiv(polydterm(1(b), 1)]), poly_of(a)))
ab := pop(ab_8); a ;= ab[1l; b := abl2l
c := \odiv{1(a), eva/pofy(Mx, a))
```

a := ®{$\odiv$(poly_of(b), poly_of(evaZpoZj,(Ux, a))), poly_of(c))

```icon
Ux := ®(Ux, ®(CT, Mx))
3.3.2 Fast Fourier Transform (FFT) and Interpolation (FFI)
FFT(N,a(x),omega,A): Fast Fourier transform
Input: integer N = 2‘m, polynomial a(x) = sum(i=0, N-1, ai * a*i), primitive Nth root of
unity omega Output: array A = (AO
AN-1) where Ak = a(omega"k)
FFT (N , ax. omega) <=
local A, n, bx, ex, (o^, B, C, (o*
if N = 1
# basis
then A11]:= OrAc^j^ax)
else { n := N/2
# binary spilt
bx := poly_of_everi_powered_terms(ax)
ex := poly_of_odel_powered_terms(ax)
co^ exp(omega, 2)
B := FFT(n, bx, (o^)
# recursive calls
```

C FFT(n. ex. (O^) every k 1 to n do

```icon
:= exp(omega, k-1)
A[kl := ®(B(k], Clk]))
Alk + nl := e(BIk]. ClkD) }}
ITA
Even powered terms.
poly_of_even_powered_t8rm8(ax) ■<1=
local r
r := Il
```

every t := lax.terms do If modjffffgfrd.oo^er. 2) = 0 then r 111:= [term(t.coef, t.power/2)l H poly(f) Odd powered terms. poly_of_odd_powored_torm8(ax) ■<=

```icon
local r
```

every t lax.terms do if znoJi„,e<er(t-powei’.2) = 1 then r (term(t.coef, (t.power - 1)/2)] If *r > 0 then -ff poly(r) else -ff 0(ax.terms[1l)

```icon
FFI(N,B.omega); Fast Fourier interpolation
Input; integer N “ 2‘m, sample values B = (bO, ... bN-l), primitive Nth root of unity
omega Output; a(x) = sum(i=0, N-1, ai x*i) where a(omega*k) = bk, k=0..N-l.
FFI (N , B, omega) <=
local bx, C, ax
bx polynomlallze(B)
C := FFT(N, bx, \odiv(l(omega), omega))
ax := polynomlallze(\odivvector ,caZar(C, modulo(N ,13)))
polynomiaiize (B) <=
local r, I
```

every b ;= IB do { If not( = (b, 0(b))) then r lterm(b, I)] H poly(r) ®vector scalar

```icon
local R , I
R := IlstCV); I ;= 1
```

every v ;= IV do { R[I] ;= $\odiv$(VII], x); I +:= 1 } -fr R 3.3.3 Newton’s method for truncated power series inversion NPSI (): Newton’s Power Series Inversion Method Input: a(t) $mod$ t*(2‘n) » sum(i=0,2‘n-l,ai t*i), aO # 0. Output: x‘(n)(t) « a(t)*-l $mod$ t*2‘n

```icon
NPSI (at)
local ax, xt. n
ax := at.Poly
xt poly_ot(Ot/ico^ax))
n Iog2(*ax.tarms)
•vary k :«■ 0 to n-1
do xt := ®(®(xt. xt),
•“(®p<»iyOfuncata(ax, 2‘(k + l)), ®(xt, xt))))
•jy tpowar(truncata(xt, at.N), at.N)
Iog2 (X) <=
local I
while X > 1 do {x :« nl2', I := i + 1 }
3’4 A. simple timer
```

A call to settimeQ initializes the timer. A call to shawtimeO prints the elapsed time since settimeQ wzs invoked.

```icon
global timer
showtime () <= pr{"I", Atlme - timer, " msecs]”} ■
eettime () <= timer := Atime ■
```

The following documentation filter is inspired by Knuth’s Tex (specifically the LaTex variant [Lampo83a,Knuth82a]. Blocks of comments are compiled as paragraphs. Paragraphs are demarcated by blank comment lines. Paragraphs are typeset with .Ip. Code is set off with .nf, and .fi. We strip any leading white space from comment lines before further processing.

```icon
global command_llno, lastjine, cur_flles, read_now, words
maln(x) <=
local fn
words :» tablsl"")
wordsriy"! ;= "‘fr"
wordsC’B"! :=
commandjine :=» x
If *command_llns > 0
than { fn := command_llns[1]
Ioad_u8ar_keyword8(fnir’.keys’’)
cur_flle8 := [r8ad_now ;= open(fn||".lcn", "r")] }
else cur_files := [r8ad_now := iinput]
lastjine := 4null
write!".so /U8r2/erlc8on/euclid/lpp/8td.me”)
process!)
getjine!)
local X
X := &null
If 8t_llne: "(y X }
else If X := read!read_now) then 'jy x
Reads lines until encountering end of file or ##ond or ##end command.
process (command) <=
local line
while line := get_llne() do If not proce8S_llne(llne, command) then break
processjine (line, command) <=
then { If llne[3;61 —
then { end_commarid(command, llneI7:*line + l]): ± }
else do_command(line(3:*llne + l]) }
else If llne[1J == "#” then write_llne(line[2:*llne + 11)
else pretty_pfint(llne, command)
If command is non-null then ##end command should match command.
end_command (command, line) -<=
if f then write(&errout, "ERROR:Mismatched END, wanted ",command,”, got ", line)
```

For interpreting ## commands

```icon
do_command (line) <=
local command, args
X := {upto("&lca8e, line) | (‘line + 1))
command ;= llne[1;xl
args := Ilnelx + 1 ;*line + ll
If not(y := proc("do_" || command, 2))
then write(&errout, "ERROR; Unknown command: ", command)
else y(args)
##list and ##enci list.
do_llst (args)
local line
wrlte(".(l I F")
while line := get_llne()
then { If llneI3:6] == "■”
then { wrlte(".)r'); end_coinmand(command,llneI7:*^lne + 1]): ± }
else do_command(llne[3:*llne + l]) }
else If line[1] ==
then { line
llne[2:*llne+ 1]
repeat If upto('
*, llne[1])
then line := llne[2:*llne + ll else break
‘MK>
If ’line > 0 then wrlte("* ", line) else wrlte() }
else pretty_prlnt(llne, command)
wrlte(".)l")
##sectlon <l> <tltle> and ##end section <l>.
Section nestings are relative to the file, from 1 on up. An ##include file’s nestings are
relative to the current level of the including file plus previous cumulative nesting. I.e., if
cumulative nesting is 3, and nesting in the including file is 2, then 1 in the included file
translates to 6 in the final output.
do_sactlon (args) <=
X := (upto(’('0123456789’), args) jCargs + 1))
level :« args(1 :x] + 0
title :■» argslx + l:’args + fl
wrlte(".sh ", level, "
wrlte(".sp 2v0lp")
process("sectlon "||level)
##sklp and ##end skip.
Deletes *everything* between skip and end skip.
do_8klp (x) •«i=
local lino
while lino := get_Ilno()
do If ilne[1:3] ==
then If Ilnol3:6] ==
then { #nd_command(command, llne[7:*llne + l]): break }
##lnclude <file>.
Includes file. Home directory for includes within included file is home directory of file
relative to current home directory. I.e., if you include foo/bar (.icn is assumed), and
foo/bar includes dot/zot, then we look for foo/dot/zot. If -I switch is present, don’t bother
doing includes.
do_lnclude (arg) ■<=
local new_flle
cur_flle := arg
now_flle := opon(cur_filel|".lcn’', "r")
If /now_fllo then wrlte("E R RO R : couldn’t open ", cur_flle, ".Icn")
else { road_now := new_flle
push(cur_flles, read_now)
Ioad_u8er_keyword8(cur_flle||".keys")
proce8s("lnclude")
# until ■ of file
clo8e(pop(cur_flles))
read_now := cur_flles[1] }
##example and ##end example
Example paragraphs are left-justified and preceded by an appropriately numbered’
boldfaced ’Example" keyword.
do_example (arg) <=
wrltos('’\fB ExampleAfR ")
pro cess ("ex am pie")
##code and ##end code
Code is unjustified and Helveticized. Uncommented lines are processed as code.
Commented lines bracketed by ##code are treated similarly; the purpose is to present
code examples in the file that are not to be seen by the ICON compiler.
do_cods (arg) <=
local line
wrlte(".nfOfH ")
while line := get_llne()
do If ltne[1:6] — "##■" then break
else pretty_prlnt_llne(llne(2:*llne + ll)
wrlte(".flOfR ")
##equatlons and ##end equations
Typeset with TBL, one .EQ and .EN. per line, except that if the line is terminated by ,
continue equation on the next line.
do.equations (arg)
wrIteC’.EQ")
process("equatlons")
writo(".EN")
##quote and ##end quote
```

These are typeset with .(q and .)q.

```icon
do_quote (arg) <=
wrlte(".(q")
process("quote**)
write(’'.)q")
##table and ##end table
```

Outputs .TS and -TE commands. Body is straight TBL. do.table (args) ■<= writo(".sp 4vO(cOTS")

```icon
process("table’’)
wrlte(".TEO)cO)
```

For printing documentation lines. If the text following the # is white space, output a .Ip

```icon
writejine (line) 4=
repeat If uptoC Ilnell]) then line := Ilne[2:*llne + 1] else break
if *line = 0 then wrlte('*.lp") else wrlte(line)
```

For printing list lines.

```icon
plaln_write_llne (line) <=
repeat If upto(’ line[1]) then line := line[2:*line-r-11 else break
wrlta(llne)
```

pretty_print(lme): For printing code. Output a .nf. Pretty print lines until end-of-file or comment. Output a .fi. Write-line; the comment if there was one. pretty_prlnt (1, command) •<=

```icon
local line
write(".nfOfH")
pretty _prlnt_llne(l)
while line := oet_llne()
do If Ilnel1:21 -- "#"
then { wrlte(".flOfR")
wrlte(".lp"): last_llne := line; ±}
else pretty_prlnt_line(llne)
wrIteC’.flOfR")
Pretty-print does special formatting in the following cases:
Procedure definitions Control structures Reserved words User keywords
If the -U<filename> option is present, then keywords are read into the words table, with
troff equivalents.
protty_print_lino (lino) ■<=
local first, last, key, x, y
dure", line) 4= <=
{ X := (upto((&lcase + + &ucase + + ’_0123456789’), line) l*llne + l)
If X = *llne + 1 then { wrltos(line): break }
ocedure (Ilno(*x + l0:*llne + l]||" <=") -<^4=
y := (upto('(Alcaso + + &ucase + 4-’_0123456789’), line) |*llne + 1)
key := (llne[1:y] I "")
first ;= (llne[1 :x] | "")
line := (llne[x:*llne + ll 1"")
else {while ‘line > 0 do
If word8[keyl "== "" then key word8(keyl
last := llnely;*llne + 1l
w rites (firs t, key)
line := last }
wrIteO }
Ioad_u8er_keywords(fname) •<=
local w, a, X
If not(w := open(fnarne, 'r')) then ±
If 75whllo X := read(w)
do { a ;= upto(’:’, x)
wordslxlltail := x[a + 1:*x + ll }
close(w)
Procedure definitions. Instead of the obvious
procedure F (a, b, c)
code
end
```

we use the logical-looking

```icon
F (a, b, c) <= code ■
If 2 == then pretty_prlnt_llne (llne|ly|l" ■")
else { pretty_prlnt_llne(llno)
If y == "■"then pretty _prlnt_llne(line |l "±«")
else { z := get_line()
local y
:= got_llne()
pretty_prlnt_llne(y): pretty_prlnt_llne(z) }}
Control Structures: return, fall and every.
Instead of return x we use uparrowx, and for return we use uparrow. Instead of fall we use
```

For every i1 to j do C every i:» j to 1 by -1 do C and every x := !Y do C we useevery i in 1, 2..j do C every i in j, j-1 .. 1 do C end every x in Y do C ; A JO 'rtJi' d'JJJAJJJA>A2 ooA" , os'-- bsiiPo’- JiJ'' . Balza84a. Stepehn R. Balzac, James H. Davenport, Patrizia Gianni, Richard D. Jenks, Victor S. Miller, Scott C. Morrison, Michael Rothstein, Christine J. Sundaresan, Robert S. Sutor, and Barry M. Trager, Scratchpad 11: An experimental computer algebra system. Mathematical Sciences Department, IBM Thomas J. Watson Research Center, Yorktown Heights, NY 10598, May, 1984. Dewar81a. Robert B.K. Dewar, Ed Schonberg, and Jacob T. Schwartz, Higher level programming: Introduction to the use of the set-theoretic programming language SETL, Grisw83a. Ralph E. Griswold, “An overview of the Icon programming language (revised, September, 1985),” TR 83-3a, Dept, of Computer Science, University of Arizona, Grisw83b. Ralph E. Griswold and Madge T. Griswold, The Icon Programming Language, Prentice-Hall, Inc., Englewood Cliffs, New Jersey, 1983. Grisw85a. Ralph E. Griswold and William H. Mitchell, Version 5.10 of Icon, TR 85-15, Dept, of Computer Science, University of Arizona, August, 1985. Ingal78a. D.H.H. Ingalls, “The SMALLTALK-76 programming system design and implementation,” in Fifth Annual ACM Symposium on Principles of Programming Languages, pp. 9-16, 1978. Knuth73a. Knuth, The art of computer programming, 1973. Knuth82a. Knuth, Donald, “Web documentation system,” UNIX TeX Distribution Tape, U. of Washington, 1982. Kruch83a. Philippe Kruchten and Edmond Schonberg, The AdalEd system: a large-scale experiment in software prototyping using SETL, Computer Science Department, Lampo83a, Lamport, Leslie, The LaTex Document Preparation System, 1983. Lipso81a. John D. Lipson, Elements of Algebra and Algebraic Computing, Benjamin/Cummings, Loosa. Loos, Polynomial remainder sequences. Computer Algebra (ed. Buchberger). NYU 84a. NYU Ada Project, AdaSem: Static Semantics for Ada, Ada Project, Courant Institute, New York University, 251 Mercer St., New York, NY, 10012, June, 1984. Niven80a. Ivan Niven and H.S. Zuckerman, An introduction to the theory of numbers, 4th ed., John Wiley & Sons, 1980. Yap85a. Yap, Chee, Polynomial remainder sequences and theory of subresultants. Unpublished lecture notes, NYU Courant Institute, Fall, 1985. Yap 86a. Chee Yap, Root Isolation, Unpublished lecture notes, N.Y.U., 1986. Zippe86a. Richard E. Zippel, Algebraic Manipulation, Unpublished lecture notes, M.I.T., 1986.
