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

```math
\begin{aligned}
&\textbf{procedure } \text{FFT}(N, a(x), \omega, A); \\
&\textbf{if } N = 1 \\
&\textbf{then} \\
&\quad \{ \text{Basis.} \} \ A_0 := a_0 \\
&\textbf{else} \\
&\textbf{begin} \\
&\quad \{ \text{Binary split.} \} \\
&\quad\quad n := N/2 \\
&\quad\quad b(x) := \sum_{i=0}^{n-1} a_{2i} x^i \\
&\quad\quad c(x) := \sum_{i=0}^{n-1} a_{2i+1} x^i \\
&\quad \{ \text{Recursive calls.} \} \\
&\quad\quad \text{FFT}(n, b(x), \omega^2, B) \\
&\quad\quad \text{FFT}(n, c(x), \omega^2, C) \\
&\quad \{ \text{Combine.} \} \\
&\quad\quad \textbf{for } k := 0 \textbf{ until } n - 1 \textbf{ do} \\
&\textbf{begin} \\
&\quad\quad\quad A_k := B_k + \omega^k \otimes C_k \\
&\quad\quad\quad A_{k+n} := B_k - \omega^k \otimes C_k \\
&\quad\quad \textbf{end} \\
&\textbf{end}
\end{aligned}
```


</div>

The purpose of the package of routines described in this paper is to allow an ICON user to implement an algorithm such as FFT, at about the same level of description as above. By comparison, see Section 3.3.2, which contains our ICON version of the same procedure. 

In order to support a high level of description, it must be possible to describe the implementation of particular Euclidean domains, and to describe algorithms which apply generically to all Euclidean domain instances. We do this by deciding which functions are expected of all Euclidean domain implementations (say, div, mod, + and -), and then implementing a "dispatch" version of each of these. The "dispatch" div function inspects the type of its argument (say, integer, polynomial, quotient domain element or modular domain element), and then calls the associated div function in the domain implementation (say divjnteger, dlv_poly, dlv_Q or dlv_mod). 

The ability to test the run-time environment is a feature of ICON. Given a string, say "X", and an integer corresponding to a number of formal parameters, say 3, proc("X", 3) will return a procedure (a first-class value in ICON, assignable to variables) if the identifier X is globally to a procedure which is defined to take 3 arguments. Otherwise proc fails. To test for the procedure $`\otimes_{Z}`$, we evaluate `proc("times" || "_Z", 2)`, and in general, for some string value X which corresponds to a procedure name, Y a domain name, and i a number of formal parameters, we evaluate `proc(X || "_" || Y, i)`, where `||` is the ICON string concatenation operator. For example, here is the code for the "generic" division operation:

<div class="math-left">

```math
\begin{aligned}
&\mathbin{⨸}(a, b) \Leftarrow \Uparrow \text{proc}(\text{"div\_"}\mathrel{\texttt{||}}\,\text{type}(a), 2)(a, b) \ \blacksquare
\end{aligned}
```


</div>

Every implementation of a Euclidean domain must supply certain required procedures. (This notion of "must" corresponds to the idea of a "category" in Scratchpad II.) Optional procedures may be supplied by the domain implementation, but are synthesized if not supplied. The following table lists required, optional and synthesized procedures. 

<p align="center"><strong>BASIC PROCEDURES FOR COMPUTING WITH DOMAINS</strong></p>

| *Type* | *Required* | *Optional* | *Synthesized* |
|:--|:-:|:-:|:-:|
| Constant | 0<br>1 | | |
| Operator | abs<br>$`\oplus`$<br>$`-`$<br>$`\otimes`$<br>$`\mathbin{⨸}`$ | mod<br>rem<br>normalize | $`\ominus`$<br>exp |
| Predicates | =<br>$`<0`$<br>unit<br>$`=0`$ | $`<`$ | $`|`$ |
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
| | $`\mathcal{Z}`$ | Signed infinite precision integers |
| **Domain constructors** | $`\mathcal{Q}`$ | Quotient domain |
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
| *INVERSE* | inverse of $`x \pmod y`$ |
| *NIA* | Newton interpolation algorithm |
| *CRA2, CRA* | Chinese remainder algorithm for 2 or more<br>linear congruences |
| *FFT* | Fast Fourier Transform |
| *FFI* | Fast Fourier Interpolation |
| *NPSI* | Newton power series inversion for truncated power series |

The system as described is comprised of about 2000 lines of commented ICON code. Supposing that the code defined in the following sections is stored in a file, say euclid, then it may be executed in ICON by adding the statement link euclid to the application program, and then running the ICON translator. The author will gladly supply this code (as is) to any interested user. Mail to ARPA:ericson@nyu or UUCP:{floyd,ihnp4}!cmcl2!csdl!ericson for more information, or via U.S. Mail (with a 600 ft mag tape) to the address listed at the beginning of this report. (The offer last until the author gets sick of making tapes.)


### 1.3. Our typographical conventions for displaying ICON code

We have dressed up and compressed the syntax of ICON, to give the algorithms presented a more compact, functional appearance. 

Icon variables (simple names for single items, and procedure names) may appear as subscripted quantities. This is purely formal, not actual, subscripting. Also, some operator symbols are defined which would not be legal identifiers in ICON (because the characters don’t exist in ASCII). Rather than spelling them out, in this report we use the symbol we would have liked to use. The following are some examples of the original code and the fancier notation. Note that underscore (`"_"`) is not a meta-character, but an ordinary character that may appear in identifiers in ICON. 

| **Original ICON** | **Fancy Notation** |
|:--|:--|
| `one_base_B` | $`1_{base_B}`$ |
| `delta_i_minus_1` | $`\delta_{i-1}`$ |
| `plus_poly` | $`\oplus_{poly}`$ |

For procedure definitions, instead of the obvious

```icon
procedure F (a, b. c)
  code
end
```

we use the logical-looking

$$\text{F}(a, b, c) \Leftarrow \text{code} \ \blacksquare$$

For `return x` we use $`\Uparrow x`$, and for `return` we use $`\Uparrow`$. Instead of `fail` we use $`\bot`$. All other ICON reserved words are bold-faced.


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

> We assume that our (Algol-like) language allows for the manipulation of values from an arbitrary Euclidean domain *D* with degree function *d*. In particular we assume that our language provides a *Division Algorithm* in the form of two operations “div” and $`mod`$ which return, respectively, a preferred quotient and remainder in accordance with the Division Property of a Euclidean domain...

 The purpose of this package is to partially implement this proviso. The package implements several primitive domains and *domain constructors*,which are classes of domains composed from other domains. 
 
 When a procedure like $`\mathbin{⨸}`$ or $`mod`$ is applied to an object which is an instance of a Euclidean domain, the type of the object is determined by inspection. This is either the primitive type, in the case of an instance of a primitive domain, or the type of the “outermost” constructor, in the case of an instance of a composite domain. In the case of required and optional procedures, the run-time environment is then tested to determine whether the domain implementation supplies an operation of this type. If the name of the domain is $`D`$, and the procedure name is $`P`$, then the run-time environment is tested for a procedure named $`P_{D}`$. For example, $`\mathbin{⨸}`$ applied to a quotient will look up the procedure $`\mathbin{⨸}_{Q}`$. Required procedures must be defined by the domain implementation, otherwise the operation fails. Implementation-optional procedures will synthesize their values if a more domain-specific implementation does not exist. 
 
**Constants.**
 
 A consequence of the existence of a variety of Euclidean domain instances is that there are a variety of structural representations for 0 and 1. In a given computation, the 0 or 1 used must be of the type of the domain instance. Hence to obtain the correct 0, we evaluate a 0 function which, given an object of the domain instance, returns the 0 of that domain, and similarly for 1.

<div class="math-left">

```math
\begin{aligned}
&\mathbf{0}(a) \Leftarrow \Uparrow \text{proc}(\text{"zero\_"}\mathrel{\texttt{||}}\text{type}(a), 1)(a) \ \blacksquare \\
&\mathbf{1}(a) \Leftarrow \Uparrow \text{proc}(\text{"one\_"}\mathrel{\texttt{||}}\text{type}(a), 1)(a) \ \blacksquare
\end{aligned}
```


</div>

**Operators.**

The following procedures define the basic arithmetic operations for domains. As noted in Table 1, every domain must supply Abs, $`\oplus`$, $`-`$, $`\otimes`$ and $`\mathbin{⨸}`$. $`mod`$, rem and normalize are optional, and $`\ominus`$ and exp are synthesized.

<div class="math-left">

```math
\begin{aligned}
&\text{Abs}(a) \Leftarrow \Uparrow \text{proc}(\text{"Abs\_"}\mathrel{\texttt{||}}\,\text{type}(a), 1)(a) \ \blacksquare \\
&\oplus(a, b) \Leftarrow \Uparrow \text{proc}(\text{"plus\_"}\mathrel{\texttt{||}}\,\text{type}(a), 2)(a, b) \ \blacksquare \\
&\ominus(a, b) \Leftarrow \Uparrow \oplus(a, -(b)) \ \blacksquare \\
&- (x) \Leftarrow \Uparrow \text{proc}(\text{"minus\_"}\mathrel{\texttt{||}}\,\text{type}(x), 2)(x) \ \blacksquare \\
&\otimes(a, b) \Leftarrow \Uparrow \text{proc}(\text{"times\_"}\mathrel{\texttt{||}}\,\text{type}(a), 2)(a, b) \ \blacksquare \\
&\mathbin{⨸}(a, b) \Leftarrow \Uparrow \text{proc}(\text{"div\_"}\mathrel{\texttt{||}}\,\text{type}(a), 2)(a, b) \ \blacksquare \\
&\text{mod}(a, b) \Leftarrow \\
&\quad \textbf{if } (x := \text{proc}(\text{"mod\_"}\mathrel{\texttt{||}}\,\text{type}(a), 2)(a, b)) \textbf{ then } \Uparrow x \\
&\quad \textbf{if } <(b, \mathbf{0}(b)) \textbf{ then } \Uparrow \text{mod}(a, -(b)) \\
&\quad \Uparrow \text{normalize}( \\
&\quad\quad \textbf{if } <(a, \mathbf{0}(a)) \\
&\quad\quad \textbf{then } \oplus(a, \otimes(b, \oplus(\ominus(-(a), b), \mathbf{1}(a)))) \\
&\quad\quad \textbf{else } \oplus(a, -(\otimes(b, \mathbin{⨸}(a, b)))) \\
&\quad ) \ \blacksquare
\end{aligned}
```


</div>

**Example.** The polynomials

$$\begin{array}{c}
a(x) = x^3 - 2 \\
b(x) = 2x^2 - 3
\end{array}$$

in the domain of quotients of machine-word integers are denoted within ICON by the record-constructor expressions and variable assignments

<div class="math-left">

```math
\begin{aligned}
&\textit{ax} := \text{poly}([\text{term}(\mathcal{Q}(-2,1), 0), \text{term}(\mathcal{Q}(1,1), 3)]) \\
&\textit{bx} := \text{poly}([\text{term}(\mathcal{Q}(-3,1), 0), \text{term}(\mathcal{Q}(2,1), 2)])
\end{aligned}
```


</div>

*pr*, a printing control structure, causes expressions to be printed out in a pleasing fashion. The ICON expression `pr{ax, " mod ", bx, " = ", mod(ax, bx)}` will print the following result:

$$(-2)q + 1q \cdot X^3 \bmod (-3)q + 2q \cdot X^2 = (-2)q + \tfrac{3}{2}q \cdot X$$

Similarly, given $`c(x)=\tfrac{3}{2}x - 2`$, represented as

<div class="math-left">

```math
\begin{aligned}
&\textit{cx} := \text{poly}([\text{term}(\mathcal{Q}(-2,1), 0), \text{term}(\mathcal{Q}(3,2), 1)])
\end{aligned}
```


</div>

The result of evaluating `pr{bx, " mod ", cx, " = ", mod(bx, cx)}` is

$$(-3)q + 2q \cdot X^2 \bmod (-2)q + \tfrac{3}{2}q \cdot X = \tfrac{5}{9}q$$

<div class="math-left">

```math
\begin{aligned}
&\text{rem}(a, b) \Leftarrow \\
&\quad \Uparrow (\textbf{if } (x := \text{proc}(\text{"rem\_"}\mathrel{\texttt{||}}\,\text{type}(a), 2)(a, b)) \textbf{ then } x \\
&\quad\quad \textbf{else } \ominus(a, \otimes(\mathbin{⨸}(a, b), b))) \ \blacksquare
\end{aligned}
```


</div>

**Example.** The polynomials

$$\begin{array}{c}
a(x) = 5 - 2x + x^2 \\
b(x) = 2
\end{array}$$

in the domain of quotients of machine-word integers are denoted with ICON by

<div class="math-left">

```math
\begin{aligned}
&\textit{ax} := \text{poly}([\text{term}(\mathcal{Q}(5,1), 0), \text{term}(\mathcal{Q}(-2,1), 1), \text{term}(\mathcal{Q}(1,1), 2)]) \\
&\textit{bx} := \text{poly\_of}(\mathcal{Q}(2,1))
\end{aligned}
```


</div>

The result of evaluating `pr{ax, " rem ", bx, " = ", rem(ax, bx)}` is

$$5q + (-2)q \cdot X + 1q \cdot X^2 \mathbin{\text{rem}} 2q = 0q$$

Similarly, given the equations over the integral domain of polynomials over machine integers denoted by

<div class="math-left">

```math
\begin{aligned}
&\textit{ax} := \text{poly}([\text{term}(8, 0), \text{term}(-9, 1), \text{term}(6, 2)]) \\
&\textit{bx} := \text{poly\_of}(3)
\end{aligned}
```


</div>

The result of evaluating `pr{ax, " rem ", bx, " = ", rem(ax, bx)}` is

$$8 + (-9)X + 6X^2 \mathbin{\text{rem}} 3 = 2$$

*normalize* returns a preferred normal form of a value for a given domain. For example, for quotients, it would be the quotient such that the dividend and divisor have no common non-unit factors. For a modular domain, it would be the least positive element of the equivalence class of the value.

<div class="math-left">

```math
\begin{aligned}
&\text{normalize}(a) \Leftarrow \\
&\quad \textbf{if } (x := \text{proc}(\text{"normalize\_"}\mathrel{\texttt{||}}\text{type}(a), 1)(a)) \textbf{ then } \Uparrow x \\
&\quad \Uparrow a \ \blacksquare
\end{aligned}
```


</div>

*exp* is the Russian Peasants algorithm for exponentiation. Our version Is transliterated
from R.B.K. Dewar’s SETL implementation of arithmetic for the NYU Ada/Ed system
[Dewar81a,Kruch83a].
<div class="math-left">

```math
\begin{aligned}
&\text{exp}(x, p) \Leftarrow \\
&\quad \textbf{if } p = 1 \textbf{ then } \Uparrow x \\
&\quad \textbf{else } \{ \text{result} := \mathbf{1}(x) \\
&\quad\quad u := \text{copy}(x); \ v := p \\
&\quad\quad \text{running} := u \\
&\quad\quad \textbf{while } v \neq 0 \textbf{ do} \\
&\quad\quad \{ \textbf{if } v \bmod 2 = 1 \textbf{ then result} := \otimes(\text{result}, \text{running}) \\
&\quad\quad\quad \text{running} := \otimes(\text{running}, \text{running}) \\
&\quad\quad\quad v := v / 2 \} \\
&\quad\quad \Uparrow \text{result} \} \ \blacksquare
\end{aligned}
```


</div>

**Predicates.**

All of the predicates defined below except | are required to be defined by a domain instance implementation if they are to be used. However, this is not a minimal set: for example, *is_zero* could be defined in terms of =. | is really not a basic predicate, but since it may be defined in a general way, we include it here.

<div class="math-left">

```math
\begin{aligned}
&= (a, b) \Leftarrow \Uparrow \text{proc}(\text{"equal\_"}\mathrel{\texttt{||}}\text{type}(a), 2)(a, b) \ \blacksquare \\
&< (a, b) \Leftarrow \Uparrow ((\text{proc}(\text{"less\_"}\mathrel{\texttt{||}}\text{type}(a), 2)(a, b)) \mathrel{|} <0(\ominus(a, b))) \ \blacksquare \\
&<0 (x) \Leftarrow \Uparrow \text{proc}(\text{"negative\_"}\mathrel{\texttt{||}}\text{type}(x), 1)(x) \ \blacksquare \\
&\mathit{unit}\,(x) \Leftarrow \Uparrow \text{proc}(\text{"unit\_"}\mathrel{\texttt{||}}\text{type}(x), 1)(x) \ \blacksquare \\
&=0 (x) \Leftarrow \Uparrow \text{proc}(\text{"is\_zero\_"}\mathrel{\texttt{||}}\text{type}(x), 1)(x) \ \blacksquare
\end{aligned}
```


</div>

$`a \mid c`$ (a divides c) if c is a multiple of a, that is, if $`\text{rem}(c, a) = 0`$.

<div class="math-left">

```math
\begin{aligned}
&{|} (a, c) \Leftarrow \Uparrow =0(\text{rem}(c, a)) \ \blacksquare
\end{aligned}
```


</div>

**Commands.**

Every domain instance $`D`$ implementation should define a preferred method of printing values in the domain, $`print_{D}`$. On top of this, we supply printing control structures *pr* and *prs*. *pr* takes a list of arguments enclosed in braces, and prints them, using the printing procedure appropriate for the type of each argument, followed by a carriage return. *prs* is the same, omitting the carriage return.

*prs* and *pr* are defined using the user-defined control operation features of ICON 5.10. [Grisw85a, Grisw83a] When *pr* or *prs* is called with a sequence of expressions in braces, the expressions are passed as unactivated co-expressions, which are then activated with the ICON @ operator.

<div class="math-left">

```math
\begin{aligned}
&\text{prs}\,(x) \Leftarrow \text{every } y := \texttt{!x} \textbf{ do } \text{print}(\texttt{@y}) \ \blacksquare \\
&\\
&\text{pr}\,(x) \Leftarrow \\
&\quad (\text{every } y := \texttt{!x} \textbf{ do } \text{print}(\texttt{@y})) \\
&\quad \text{write}() \ \blacksquare \\
&\\
&\text{print}\,(x) \Leftarrow \\
&\quad \textbf{if } \text{type}(x) \mathrel{==} \text{"list"} \\
&\quad \textbf{then } \{ \text{writes}(\text{"["}) \\
&\quad\quad \text{every } y := \texttt{!x}[1:\texttt{*x}] \textbf{ do } \{ \text{print}(y); \text{ writes}(\text{", "}) \} \\
&\quad\quad \text{print}(x[\texttt{*x}]); \text{ writes}(\text{"]"}) \} \\
&\quad \textbf{else if } pp := \text{proc}(\text{"print\_"}\mathrel{\texttt{||}}\,\text{type}(x), 1) \textbf{ then } pp(x) \\
&\quad \textbf{else if } \text{type}(x) \mathrel{==} \text{"string"} \textbf{ then writes}(x) \\
&\quad \textbf{else writes}(\text{image}(x)) \ \blacksquare
\end{aligned}
```


</div>


### 2.2. Primitive domains

The primitive domains are those which are not constructed from other domains, or which are best thought of as undecomposable. We have three such domains available: 

* Arbitrary-precision arbitrary-base integers.
* Arbitrary-precision base 10 integers.
* Ordinary machine integers. 

The latter are best unused: ICON does not notify the user of integer multiplication overflow, and overflow can occur very easily in the applications we deal with. For example, subresultant polynomial remainder sequences with cofficients in the 10000 range involve intermediate calculations in the `10000^4` range.


#### 2.2.1. Abitrary base, infinite precision non-negative integer

<p align="center"><strong>Base B Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $`base_{\mathbf{B}}`$; $`set_{base}`$ |
| **Constants** | $`0_{base_{\mathbf{B}}}`$, $`1_{base_{\mathbf{B}}}`$, $`k_{base_{\mathbf{B}}}`$ |
| **Operators** | $`\oplus_{base_{\mathbf{B}}}`$, $`\ominus_{base_{\mathbf{B}}}`$, $`\otimes_{base_{\mathbf{B}}}`$, $`\mathbin{⨸}_{base_{\mathbf{B}}}`$, $`normalize_{base_{\mathbf{B}}}`$ |
| **Predicates** | $`<_{base_{\mathbf{B}}}`$, $`=_{base_{\mathbf{B}}}`$ |
| **Commands** | $`print_{base_{\mathbf{B}}}`$ |

**Data structures.** *base* is a number $`B`$ such that 1 is less than the maximum machine word integer. Then *digits* is a list of machine word integers less than *base* and greater than 0. Width is the printing width of digits of the base, in terms of decimal digits.

<div class="math-left">

```math
\begin{aligned}
&\textbf{record } base_{\mathbf{B}}\ (base, digits) \\
&\textbf{global } Base, Width \\
&set_{base}(b, w) \Leftarrow \\
&\quad Base \mathrel{:=} b \\
&\quad Width \mathrel{:=} \texttt{*}(b \ \mathrel{\texttt{||}} \ "") - 1 \ \blacksquare
\end{aligned}
```


</div>

**Constants.**

<div class="math-left">

```math
\begin{aligned}
&0_{base_{\mathbf{B}}}(x) \Leftarrow \Uparrow base_{\mathbf{B}}(x.base, [0]) \ \blacksquare \\
&1_{base_{\mathbf{B}}}(x) \Leftarrow \Uparrow base_{\mathbf{B}}(x.base, [1]) \ \blacksquare \\
&k_{base_{\mathbf{B}}}(x) \Leftarrow \Uparrow base_{\mathbf{B}}(\text{Base}, digits\_of(abs(x), \text{Base})) \ \blacksquare \\
&digits\_of(x, B) \Leftarrow \textbf{if } x < B \textbf{ then } \Uparrow [x] \textbf{ else } \Uparrow digits\_of(x/B, B) \mathrel{\texttt{|||}} \ [mod_{integer}(x, B)] \ \blacksquare
\end{aligned}
```


</div>

**Operators.**

The base $`B`$ addition algorithm is that of Lipson, p. 199. For input it takes $`a`$, $`b`$, lists of integers $`\leq B`$, of length $`m`$ returning $`a + b`$.

<div class="math-left">

```math
\begin{aligned}
&\oplus_{base_{\mathbf{B}}}(a, b) \Leftarrow \\
&\quad B \mathrel{:=} a.base \\
&\quad \Uparrow base_{\mathbf{B}}(B, \oplus_{digits}(a.digits, b.digits, B)) \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&\oplus_{digits}(ad, bd, B) \Leftarrow \\
&\quad m \mathrel{:=} \texttt{*}ad;\ n \mathrel{:=} \texttt{*}bd \\
&\quad \textbf{if } m < n \textbf{ then } \{ a \mathrel{:=} (list(n - m, 0) \mathrel{\texttt{|||}} \ ad);\ b \mathrel{:=} bd \} \\
&\quad \textbf{else if } m > n \textbf{ then } \{ a \mathrel{:=} ad;\ b \mathrel{:=} list(m - n, 0) \mathrel{\texttt{|||}} \ bd \} \\
&\quad \textbf{else } \{ a \mathrel{:=} ad;\ b \mathrel{:=} bd \} \\
&\quad m \mathrel{:=} \texttt{*}a; \\
&\quad c\_digits \mathrel{:=} list(m + 1, 0); \\
&\quad gamma \mathrel{:=} 0 \\
&\quad \textbf{every } i \mathrel{:=} m \textbf{ to } 1 \textbf{ by } -1 \textbf{ do } \\
&\quad \{ t \mathrel{:=} a[i] + b[i] + gamma \\
&\quad\quad c\_digits[i + 1] \mathrel{:=} mod_{integer}(t, B) \\
&\quad\quad gamma \mathrel{:=} t / B \} \\
&\quad c\_digits[1] \mathrel{:=} gamma \\
&\\
&\quad \Uparrow normalize_{digits}(c\_digits) \ \blacksquare
\end{aligned}
```


</div>

Example. The result of evaluating

<div class="math-left">

```math
\begin{aligned}
&x \mathrel{:=} base_{\mathbf{B}}(8, [1]);\ y \mathrel{:=} base_{\mathbf{B}}(8, [7, 7, 7]) \\
&\text{pr}\{x,\ \text{" + "},\ y,\ \text{" = "},\ \oplus_{base_{\mathbf{B}}}(x, y)\}
\end{aligned}
```


</div>

is

1 #8# + 7 7 7 #8# = 1 0 0 0 #8#

The base B subtraction algorithm is Knuth Algorithm 4.3.1 S, transliterated from a SETL implementation of Robert Dewar. Assume $`a\geq b`$ are lists of integers $`\leq B`$. Returns $`a-b`$. 

<div class="math-left">

```math
\begin{aligned}
&\ominus_{base_{\mathbf{B}}}(a, bb) \Leftarrow \\
&\quad b \mathrel{:=} copy(bb);\ B \mathrel{:=} a.base;\ m \mathrel{:=} \texttt{*}a.digits \\
&\quad \textbf{repeat } \\
&\quad \{ n \mathrel{:=} \texttt{*}b.digits \\
&\quad\quad \textbf{if } m < n \textbf{ then } \text{pr}\{\text{"ERROR: } base_{\mathbf{B}} \text{ integer subtraction underflow"}\} \\
&\quad\quad \textbf{else if } m > n \\
&\quad\quad \textbf{then } b \mathrel{:=} base_{\mathbf{B}}(B, list(m - n, 0) \mathrel{\texttt{|||}} \ b.digits) \\
&\quad\quad \textbf{else } \Uparrow base_{\mathbf{B}}(b.base, \ominus_{digits}(a.digits, b.digits, b.base)) \} \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&\ominus_{digits}(a, b, B) \Leftarrow \\
&\quad u \mathrel{:=} copy(a) \\
&\quad v \mathrel{:=} list(\texttt{*}a - \texttt{*}b, 0) \mathrel{\texttt{|||}} \ copy(b) \\
&\quad k \mathrel{:=} 0 \\
&\quad \textbf{every } j \mathrel{:=} \texttt{*}u \textbf{ to } 1 \textbf{ by } -1 \textbf{ do } \\
&\quad \{ u[j] \mathrel{:=} u[j] - v[j] + k \\
&\quad\quad \textbf{if } u[j] < 0 \textbf{ then } \{ u[j] \mathrel{+{=}} B;\ k \mathrel{:=} -1 \} \textbf{ else } k \mathrel{:=} 0 \} \\
&\\
&\quad \Uparrow normalize_{digits}(u) \ \blacksquare
\end{aligned}
```


</div>

**Example.**

The result of evaluating

<div class="math-left">

```math
\begin{aligned}
&x \mathrel{:=} base_{\mathbf{B}}(10, [1,0,0,5,6,3]);\ y \mathrel{:=} base_{\mathbf{B}}(10, [5,3,3,5]) \\
&\text{pr}\{x,\ \text{" - "},\ y,\ \text{" = "},\ \ominus_{base_{\mathbf{B}}}(x,y)\} \\
&x \mathrel{:=} base_{\mathbf{B}}(10,[2,1,2]);\ y \mathrel{:=} base_{\mathbf{B}}(10, [9,9]) \\
&\text{pr}\{x,\ \text{" - "},\ y,\ \text{" = "},\ \ominus_{base_{\mathbf{B}}}(x, y)\} \\
&y \mathrel{:=} base_{\mathbf{B}}(10, [1,9,9]) \\
&\text{pr}\{x,\ \text{" - "},\ y,\ \text{" = "},\ \ominus_{base_{\mathbf{B}}}(x, y)\}
\end{aligned}
```


</div>

is

1 0 0 5 6 3 #10# - 5 3 3 5 #10# = 9 5 2 2 8 #10#  
2 1 2 #10# - 9 9 #10# = 1 1 3 #10#  
2 1 2 #10# - 1 9 9 #10# = 1 3 #10#

<div class="math-left">

```math
\begin{aligned}
&normalize_{base_{\mathbf{B}}}(r) \Leftarrow \\
&\quad d \mathrel{:=} normalize_{digits}(r.digits) \\
&\quad \Uparrow base_{\mathbf{B}}(r.base, d) \ \blacksquare \\
&\\
&normalize_{digits}(d) \Leftarrow \\
&\quad \textbf{while } (\texttt{*}d > 1) \ \& \ (d[1] = 0) \textbf{ do } pop(d) \\
&\quad \Uparrow d \ \blacksquare
\end{aligned}
```


</div>

The base $`B`$ multiplication algorithm is that of Lipson, p. 200. As input it takes $`a`$, $`b`$, lists of integers $`\leq B`$, of length $`m`$ and $`n`$. It outputs $`a \otimes b`$. 

<div class="math-left">

```math
\begin{aligned}
&\otimes_{base_{\mathbf{B}}}(a, b) \Leftarrow \Uparrow base_{\mathbf{B}}(a.base, \otimes_{digits}(a.digits, b.digits, a.base)) \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&\otimes_{digits}(a, b, B) \Leftarrow \\
&\quad m \mathrel{:=} \texttt{*}a \\
&\quad n \mathrel{:=} \texttt{*}b \\
&\quad c \mathrel{:=} list(m + n, 0) \\
&\quad \textbf{every } k \mathrel{:=} 0 \textbf{ to } n - 1 \textbf{ by } 1 \textbf{ do } \\
&\quad \{ \\
&\quad\quad gamma \mathrel{:=} 0 \\
&\quad\quad \textbf{every } l \mathrel{:=} 0 \textbf{ to } m - 1 \textbf{ by } 1 \textbf{ do } \\
&\quad\quad \{ \\
&\quad\quad\quad t \mathrel{:=} a[m - l] * b[n - k] + c[m + n - k - l] + gamma \\
&\quad\quad\quad \textbf{if } t < 0 \\
&\quad\quad\quad \textbf{then } \text{pr}\{\text{"ERROR: Integer overflow in } \otimes_{base_{\mathbf{B}}}\text{, base = "},\ B\} \\
&\quad\quad\quad c[m + n - k - l] \mathrel{:=} mod_{integer}(t, B) \\
&\quad\quad\quad gamma \mathrel{:=} t / B \\
&\quad\quad \} \\
&\quad\quad c[n - k] \mathrel{:=} gamma \\
&\quad \} \\
&\\
&\quad \Uparrow normalize_{digits}(c) \ \blacksquare
\end{aligned}
```


</div>

**Example.**

The result of evaluating

<div class="math-left">

```math
\begin{aligned}
&x \mathrel{:=} k_{base_{\mathbf{B}}}(28107324);\ y \mathrel{:=} k_{base_{\mathbf{B}}}(75625) \\
&\text{pr}\{x,\ \text{" * "},\ y,\ \text{" = "},\ \otimes_{base_{\mathbf{B}}}(x,y)\} \\
&x \mathrel{:=} k_{base_{\mathbf{B}}}(28107324);\ y \mathrel{:=} k_{base_{\mathbf{B}}}(75625) \\
&\text{pr}\{x,\ \text{" * "},\ y,\ \text{" = "},\ \otimes_{base_{\mathbf{B}}}(x,y)\} \\
&x \mathrel{:=} k_{base_{\mathbf{B}}}(7478);\ y \mathrel{:=} k_{base_{\mathbf{B}}}(4625) \\
&\text{pr}\{x,\ \text{" * "},\ y,\ \text{" = "},\ \otimes_{base_{\mathbf{B}}}(x, y)\}
\end{aligned}
```


</div>

is

2 8 1 0 7 3 2 4 #10# * 7 5 6 2 5 #10# = 2 1 2 5 6 1 6 3 7 7 5 0 0 #10#  
2 8 1 0 7 3 2 4 #10# * 7 5 6 2 5 #10# = 2 1 2 5 6 1 6 3 7 7 5 0 0 #10#  
7 4 7 8 #10# * 4 6 2 5 #10# = 3 4 5 8 5 7 5 0 #10#


The following algorithm computes $`a\over b`$ by long division. The design is that of Knuth Algorithm 4.3.1 D [Knuth73a], and the implementation is largely borrowed from a SETL implementation of Robert Dewar [NYU 84a]. Most of the following comments are lifted from the Dewar implementation. 

This is by far the most difficult of the four basic operations. This is because the paper and pencil algorithm involves certain amounts of guess work which cannot be programmed directly. The approach (analyzed in detail by Knuth) is to reduce the guess work by computing a rather good guess at each digit of the result, and then correcting if the guess is wrong. 

<div class="math-left">

```math
\begin{aligned}
&\mathbin{⨸}_{base_{\mathbf{B}}}(a, b) \Leftarrow \Uparrow normalize_{base_{\mathbf{B}}}(base_{\mathbf{B}}(a.base, \mathbin{⨸}_{digits}(a.digits, b.digits, a.base))) \ \blacksquare \\
&\\
&\mathbin{⨸}_{digits}(a, b, B) \Leftarrow \\
&\quad \textbf{If the divisor is 0, then fail.} \\
&\quad \textbf{if } (\texttt{*}b = 1) \ \& \ (b[1] = 0) \textbf{ then } \{ \text{pr}\{\text{"ERROR: divide by 0 in } base_{\mathbf{B}}\text{"}\};\ \bot \} \\
&\quad \textbf{If } a \textbf{ is shorter than } b, \textbf{ return } 0. \\
&\quad \textbf{if } \texttt{*}a < \texttt{*}b \textbf{ then } \Uparrow [0]
\end{aligned}
```


</div>


The case of a one digit divisor is treated specially. Not only is this more efficient, but the general algorithm assumes that the divisor contains at least two digits. Basically dividing by a single digit is straightforward. Since we can represent numbers up to $`B*B— 1`$, we can do the steps of the division exactly without any need for guess work. The division is then done left to right.

<div class="math-left">

```math
\begin{aligned}
&\textbf{if } \texttt{*}b = 1 \textbf{ then } \\
&\{ q \mathrel{:=} list(\texttt{*}a, 0) \\
&\quad rr \mathrel{:=} 0 \\
&\quad \textbf{every } j \mathrel{:=} 1 \textbf{ to } \texttt{*}a \textbf{ do } \\
&\quad \{ du \mathrel{:=} rr * B + a[j] \\
&\quad\quad q[j] \mathrel{:=} du / b[1] \\
&\quad\quad rr \mathrel{:=} du \% b[1] \} \\
&\quad \Uparrow normalize_{digits}(q) \}
\end{aligned}
```


</div>

Otherwise we must commence with the full long division algorithm.

<div class="math-left">

```math
\begin{aligned}
&u \mathrel{:=} copy(a) \\
&v \mathrel{:=} copy(b) \\
&n \mathrel{:=} \texttt{*}v \\
&m \mathrel{:=} \texttt{*}u - n \\
&q \mathrel{:=} list(m + 1, 0)
\end{aligned}
```


</div>


Knuth Step D1. [Normalize] The first step is to multiply both the divisor and dividend by a scale factor. Obviously such scaling does not affect the quotient. The purpose of this scaling is to ensure that the first digit of the divisor is at least $`B/2`$. This condition is required for the proper operation of the quotient estimation algorithm used in the division loop. Note that we added an extra digit at the front of the dividend above.

<div class="math-left">

```math
\begin{aligned}
&d \mathrel{:=} B / (v[1] + 1) \\
&u \mathrel{:=} \otimes_{digits}(u, [d], B) \\
&\textbf{if } \texttt{*}u = m + n \textbf{ then } u \mathrel{:=} [0] \ \mathrel{\texttt{||}} \ u \\
&v \mathrel{:=} \otimes_{digits}(v, [d], B)
\end{aligned}
```


</div>

Knuth Step D2. [Initialize $`j`$] This is the major loop, corresponding to long division steps.

<div class="math-left">

```math
\begin{aligned}
&\textbf{every } j \mathrel{:=} 1 \textbf{ to } m + 1 \textbf{ do } \\
&\{
\end{aligned}
```


</div>

Knuth Step D3. [Calculate q_hat] Guess the next quotient digit by doing a division based on the leading digits. This estimate is never low and at most 2 high.

<div class="math-left">

```math
\begin{aligned}
&\textbf{if } u[j] = v[1] \textbf{ then } qe \mathrel{:=} B - 1 \textbf{ else } qe \mathrel{:=} ((u[j] * B) + u[j + 1]) / v[1]
\end{aligned}
```


</div>

The following loop refines this guess so that it is almost always correct and is at worst one too high (see Knuth [Knuth73a] for proofs). 

<div class="math-left">

```math
\begin{aligned}
&\textbf{while } (v[2] * qe) > (((u[j] * B) + u[j + 1] - (qe * v[1])) * B + u[j + 2]) \textbf{ do } qe \mathrel{{-}{:=}} 1
\end{aligned}
```


</div>

Knuth Step D4. [Multiply and subtract] Now (for the moment accepting the estimate as correct), we subtract the appropriate multiple of the divisor. This is similar to the inner loop of the multiplication routine. 

<div class="math-left">

```math
\begin{aligned}
&c \mathrel{:=} 0 \\
&\textbf{every } k \mathrel{:=} n \textbf{ to } 1 \textbf{ by } -1 \textbf{ do } \\
&\{ du \mathrel{:=} u[j + k] - (qe * v[k]) + c \\
&\quad u[j + k] \mathrel{:=} du \% B \\
&\quad c \mathrel{:=} du / B \\
&\quad \textbf{if } u[j + k] < 0 \textbf{ then } \{ u[j + k] \mathrel{+{=}} B;\ c \mathrel{{-}{:=}} 1 \} \} \\
&u[j] \mathrel{+{=}} c
\end{aligned}
```


</div>

Knuth Step D5,D6. [Test remainder. Add back] If the estimate was one off, then $`u[j]`$ went negative when the final carry was added above. In this case, we add back the divisor once, and adjust the quotient digit.

<div class="math-left">

```math
\begin{aligned}
&q[j] \mathrel{:=} qe \\
&\textbf{if } u[j] < 0 \textbf{ then } \\
&\{ qe \mathrel{{-}{:=}} 1 \\
&\quad c \mathrel{:=} 0 \\
&\quad \textbf{every } k \mathrel{:=} n \textbf{ to } 1 \textbf{ by } -1 \textbf{ do } \\
&\quad \{ u[j + k] \mathrel{+{=}} v[k] + c \\
&\quad\quad \textbf{if } u[j + k] \geq B \textbf{ then } \{ u[j + k] \mathrel{{-}{:=}} B;\ c \mathrel{:=} 1 \} \\
&\quad\quad \textbf{else } c \mathrel{:=} 0 \} \\
&\quad u[j] \mathrel{+{=}} c \} \\
&\} \\
&\Uparrow normalize_{digits}(q) \ \blacksquare
\end{aligned}
```


</div>

**Example.** The result of evaluating 

<div class="math-left">

```math
\begin{aligned}
&\textbf{every } xy \mathrel{:=} ![[10, 1], [4,2], [27, 9], [42,2], [90,1], \\
&\quad\quad [188175, 325], [188175, 579], [188175, 580], \\
&\quad\quad [188175, 578], [121903, 5335], \\
&\quad\quad [212, 99], [115668, 75625]] \\
&\textbf{do } \{ x \mathrel{:=} k_{base_{\mathbf{B}}}(xy[1]);\ y \mathrel{:=} k_{base_{\mathbf{B}}}(xy[2]) \\
&\quad \text{pr}\{x,\ \text{" / "},\ y,\ \text{" = "},\ \mathbin{⨸}_{base_{\mathbf{B}}}(x, y)\} \}
\end{aligned}
```


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

```math
\begin{aligned}
&print_{base_{\mathbf{B}}}(b) \Leftarrow \\
&\quad \textbf{local } digits \\
&\quad writes(b.digits[1],\ \text{" "}) \\
&\quad \textbf{every } writes(right(\texttt{!}rest(b.digits),\ Width,\ \text{"0"}),\ \text{" "}) \\
&\quad writes(\texttt{"\#"},\ b.base,\ \texttt{"\#"}) \ \blacksquare
\end{aligned}
```


</div>

**Predicates.** We supply two predicates, $`<_{base_{\mathbf{B}}}`$ and $`=_{base_{\mathbf{B}}}`$.

<div class="math-left">

```math
\begin{aligned}
&<_{base_{\mathbf{B}}}(a, b) \Leftarrow \Uparrow <_{digits}(a.digits, b.digits) \ \blacksquare \\
&\\
&<_{digits}(a, b) \Leftarrow \\
&\quad \textbf{if } \texttt{*}a < \texttt{*}b \textbf{ then } \Uparrow \\
&\quad \textbf{else if } (\texttt{*}a > \texttt{*}b) \textbf{ then } \bot \\
&\quad \textbf{else if } \texttt{*}a = 0 \textbf{ then } \bot \\
&\quad \textbf{else if } (a[1] > b[1]) \textbf{ then } \bot \\
&\quad \textbf{else if } (a[1] < b[1]) \textbf{ then } \Uparrow \\
&\quad \textbf{else } \Uparrow <_{digits}(rest(a), rest(b)) \ \blacksquare \\
&\\
&=_{base_{\mathbf{B}}}(a, b) \Leftarrow \Uparrow =_{digits}(a.digits, b.digits) \ \blacksquare \\
&\\
&=_{digits}(a, b) \Leftarrow \\
&\quad \textbf{if } \texttt{*}a < \texttt{*}b \textbf{ then } \bot \\
&\quad \textbf{else if } (\texttt{*}a > \texttt{*}b) \textbf{ then } \bot \\
&\quad \textbf{else if } \texttt{*}a = 0 \textbf{ then } \Uparrow \\
&\quad \textbf{else if } (a[1] \neq b[1]) \textbf{ then } \bot \\
&\quad \textbf{else } \Uparrow =_{digits}(rest(a), rest(b)) \ \blacksquare
\end{aligned}
```


</div>
<div class="math-left">

```math
\begin{aligned}
&rest(x) \Leftarrow \textbf{if } \texttt{*}x < 2 \textbf{ then } \Uparrow []\ \textbf{else } \Uparrow x[2:\texttt{*}x + 1] \ \blacksquare
\end{aligned}
```


</div>

#### 2.2.2. Arbitrary precision integer Euclidean domain Z

<p align="center"><strong>Integer Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $`Z`$ |
| **Constants** | $`0_{Z}`$, $`1_{Z}`$, $`k_{Z}`$ |
| **Operators** | $`\oplus_{Z}`$, $`-_{Z}`$, $`\otimes_{Z}`$, $`\mathbin{⨸}_{Z}`$, $`mod_{Z}`$, $`abs_{Z}`$, $`deg_{Z}`$, $`normalize_{Z}`$ |
| **Predicates** | $`=_{Z}`$, $`<_{Z}`$, $`unit_{Z}`$, $`>0_{Z}`$, $`<0_{Z}`$, $`=0_{Z}`$ |
| **Commands** | $`print_{Z}`$ |

**Data structures.** *sign* is 1 or $`-1`$. *mantissa* is a base $`Base`$ integer, where the $`Base`$ is set by $`k_{Z}`$.

<div class="math-left">

```math
\begin{aligned}
&\textbf{record } Z\ (sign, mantissa)
\end{aligned}
```


</div>

**Constants.**

<div class="math-left">

```math
\begin{aligned}
&0_Z(a) \Leftarrow \Uparrow Z(1, 0_{base_{\mathbf{B}}}(a.mantissa)) \ \blacksquare \\
&1_Z(a) \Leftarrow \Uparrow Z(1, 1_{base_{\mathbf{B}}}(a.mantissa)) \ \blacksquare
\end{aligned}
```


</div>

$`k_{Z}`$ takes an ICON integer and transforms it into a $`Z`$ constant.

<div class="math-left">

```math
\begin{aligned}
&k_Z(x) \Leftarrow \\
&\quad \textbf{initial } set_{base}(10000) \\
&\quad \Uparrow Z(\textbf{if } x = 0 \textbf{ then } 1 \textbf{ else } x/abs(x), \\
&\quad\quad base_{\mathbf{B}}(Base, digits\_of(abs(x), Base))) \ \blacksquare
\end{aligned}
```


</div>

**Operators.**

<div class="math-left">

```math
\begin{aligned}
&\oplus_Z(a, b) \Leftarrow \\
&\quad \textbf{if } <0_Z(a) \ \& \ >0_Z(b) \textbf{ then } \Uparrow \oplus_Z(b, a) \\
&\quad \Uparrow normalize_Z( \\
&\quad\quad \textbf{if } =0_Z(a) \textbf{ then } b \\
&\quad\quad \textbf{else if } =0_Z(b) \textbf{ then } a \\
&\quad\quad \textbf{else if } (>0_Z(a) \ \& \ >0_Z(b)) \ | \ (<0_Z(a) \ \& \ <0_Z(b)) \\
&\quad\quad \textbf{then } Z(a.sign, \oplus_{base_{\mathbf{B}}}(a.mantissa, b.mantissa)) \\
&\quad\quad \textbf{else } \{ \texttt{\#}a > 0 \textbf{ and } b < 0,\ \textbf{so...} \\
&\quad\quad\quad \textbf{if } <_{base_{\mathbf{B}}}(a.mantissa, b.mantissa) \\
&\quad\quad\quad \textbf{then } Z(-1, \ominus_{base_{\mathbf{B}}}(b.mantissa, a.mantissa)) \\
&\quad\quad\quad \textbf{else } Z(1, \ominus_{base_{\mathbf{B}}}(a.mantissa, b.mantissa)) \} \\
&\quad ) \ \blacksquare
\end{aligned}
```


</div>

**Example.** The result of evaluating

<div class="math-left">

```math
\begin{aligned}
&x \mathrel{:=} k_Z(1);\ y \mathrel{:=} k_Z(-999) \\
&\text{pr}\{x,\ \text{" + "},\ y,\ \text{" = "},\ \oplus_Z(x, y)\}
\end{aligned}
```


</div>

is

$`1z + (-999z) = (-998z)`$

<div class="math-left">

```math
\begin{aligned}
&-_Z(x) \Leftarrow \Uparrow normalize_Z(Z(-x.sign, x.mantissa)) \ \blacksquare
\end{aligned}
```


</div>

**Example.** The result of evaluating 

<div class="math-left">

```math
\begin{aligned}
&x \mathrel{:=} k_Z(212);\ y \mathrel{:=} k_Z(-99) \\
&\text{pr}\{\text{"-"},\ x,\ \text{" = "},\ -_Z(x)\} \\
&\text{pr}\{\text{"-"},\ y,\ \text{" = "},\ -_Z(y)\}
\end{aligned}
```


</div>

is

$`-212z = (-212z)`$  
$`-(-99z) = 99z`$

<div class="math-left">

```math
\begin{aligned}
&\otimes_Z(a, b) \Leftarrow \Uparrow normalize_Z(Z(a.sign * b.sign, \otimes_{base_{\mathbf{B}}}(a.mantissa, b.mantissa))) \ \blacksquare
\end{aligned}
```


</div>

**Example.**  The result of evaluating 

<div class="math-left">

```math
\begin{aligned}
&\textbf{every } xy \mathrel{:=} ![[10, 1], [121903, 5335], [115668, 75625]] \\
&\textbf{do } \{ x \mathrel{:=} k_Z(xy[1]);\ y \mathrel{:=} k_Z(xy[2]); \\
&\quad \text{pr}\{x,\ \text{" / "},\ y,\ \text{" = "},\ \mathbin{⨸}_Z(x, y)\} \}
\end{aligned}
```


</div>

is

$`10z / 1z = 10z`$  
$`121903z / 5335z = 22z`$  
$`115668z / 75625z = 1z`$

<div class="math-left">

```math
\begin{aligned}
&mod_Z(a, b) \Leftarrow \\
&\Uparrow (\textbf{if } <_Z(b, 0_Z(b)) \textbf{ then } mod_Z(a, -_Z(b)) \\
&\quad \textbf{else if } <_Z(a, 0_Z(a)) \\
&\quad \textbf{then } \oplus_Z(a, -_Z(\otimes_Z(b, \oplus_Z(-_Z(1_Z(a)), \mathbin{⨸}_Z(a, b)))) \\
&\quad \textbf{else } \oplus_Z(a, -_Z(\otimes_Z(b, \mathbin{⨸}_Z(a, b)))) )
\end{aligned}
```


</div>

**Example.** The result of evaluating

<div class="math-left">

```math
\begin{aligned}
&x \mathrel{:=} k_Z(121903);\ y \mathrel{:=} k_Z(5335) \\
&\text{pr}\{x,\ \text{" mod "},\ y,\ \text{" = "},\ mod_Z(x, y)\}
\end{aligned}
```


</div>

is

$`121903z \bmod 5335z = 4533z`$

<div class="math-left">

```math
\begin{aligned}
&abs_Z(x) \Leftarrow \Uparrow Z(1, x.mantissa) \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&deg_Z(x) \Leftarrow \Uparrow x \ \blacksquare \\
&normalize_Z(x) \Leftarrow \Uparrow (\textbf{if } =0_Z(x) \textbf{ then } Z(1, x.mantissa) \textbf{ else } x) \ \blacksquare
\end{aligned}
```


</div>

**Predicates.**

<div class="math-left">

```math
\begin{aligned}
&=_Z(a, b) \Leftarrow \\
&\quad \textbf{if } =0_Z(a) \ \& \ =0_Z(b) \textbf{ then } \Uparrow \\
&\quad \textbf{else if } a.sign \neq b.sign \textbf{ then } \bot \\
&\quad \textbf{else } \Uparrow =_{base_{\mathbf{B}}}(a.mantissa, b.mantissa) \ \blacksquare \\
&\\
&<_Z(a, b) \Leftarrow \\
&\quad \textbf{if } a.sign < b.sign \textbf{ then } \Uparrow \\
&\quad \textbf{if } a.sign > b.sign \textbf{ then } \bot \\
&\quad \textbf{if } a.sign = 1 \textbf{ then } \Uparrow <_{base_{\mathbf{B}}}(a.mantissa, b.mantissa) \\
&\quad \textbf{if } a.sign = -1 \textbf{ then } \Uparrow <_{base_{\mathbf{B}}}(b.mantissa, a.mantissa) \ \blacksquare \\
&\\
&unit_Z(x) \Leftarrow \Uparrow (=_Z(x, 1_Z(x)) \ | \ =_Z(x, Z(-1, 1_{base_{\mathbf{B}}}(x.mantissa)))) \ \blacksquare \\
&>0_Z(x) \Leftarrow \Uparrow ((x.sign = 1) \ \& \ \textbf{not } =0_Z(x)) \ \blacksquare \\
&<0_Z(x) \Leftarrow \Uparrow ((x.sign = -1) \ \& \ \textbf{not } =0_Z(x)) \ \blacksquare \\
&=0_Z(x) \Leftarrow \Uparrow =_{base_{\mathbf{B}}}(x.mantissa, 0_{base_{\mathbf{B}}}(x.mantissa)) \ \blacksquare
\end{aligned}
```


</div>

**Commands.**

<div class="math-left">

```math
\begin{aligned}
&print_Z(a) \Leftarrow \\
&\quad \textbf{local } digits \\
&\quad \textbf{if } a.sign < 0 \textbf{ then } writes(\text{"(-"}) \\
&\quad digits \mathrel{:=} a.mantissa.digits \\
&\quad \textbf{every } ch \mathrel{:=} \texttt{!}digits \textbf{ do } writes(right(ch,\ Width,\ \text{"0"})) \\
&\quad writes(\text{"z"}) \\
&\quad \textbf{if } a.sign < 0 \textbf{ then } writes(\text{")"}) \ \blacksquare
\end{aligned}
```


</div>


#### 2.2.3. Small integers Euclidean domain

We provide the following machine integer arithmetic facilities:

<p align="center"><strong>Machine Integer Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Constants** | $`0_{integer}`$, $`1_{integer}`$ |
| **Operators** | $`\oplus`$, $`-_{integer}`$, $`\odot_{integer}`$, $`\mathit{circleslash}_{integer}`$, $`rem_{integer}`$, $`mod_{integer}`$, $`deg_{integer}`$, $`abs_{integer}`$ |
| **Predicates** | $`=0_{integer}`$, $`<0_{integer}`$, $`=_{integer}`$, $`unit_{integer}`$ |
| **Commands** | $`print_{integer}`$ |


**Constants.** We provide constants 0 and 1, as follows:

<div class="math-left">

```math
\begin{aligned}
&0_{integer}(x) \Leftarrow \Uparrow 0 \ \blacksquare \\
&1_{integer}(x) \Leftarrow \Uparrow 1 \ \blacksquare
\end{aligned}
```


</div>

**Operators.**

<div class="math-left">

```math
\begin{aligned}
&\oplus(a, b) \Leftarrow \Uparrow a + b \ \blacksquare \\
&-_integer(x) \Leftarrow \Uparrow -x \ \blacksquare \\
&\odot_{integer}(a, b) \Leftarrow \Uparrow a * b \ \blacksquare \\
&\mathit{circleslash}_{integer}(a, b) \Leftarrow \Uparrow a / b \ \blacksquare \\
&\\
&mod_{integer}(a, m) \Leftarrow \\
&\quad \textbf{if } m < 0 \textbf{ then } m \mathrel{:=} -m \\
&\quad \textbf{repeat } \\
&\quad \textbf{if } a < 0 \textbf{ then } a \mathrel{:=} a + (abs(a/m) + 1) * m \textbf{ else } \Uparrow a \% m \ \blacksquare
\end{aligned}
```


</div>

*rem* is not *mod*, because *rem* may be negative, but *mod* is never negative.

<div class="math-left">

```math
\begin{aligned}
&rem_{integer}(a, b) \Leftarrow \Uparrow a \% b \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&deg_{integer}(x) \Leftarrow \Uparrow x \ \blacksquare \\
&abs_{integer}(x) \Leftarrow \Uparrow abs(x) \ \blacksquare
\end{aligned}
```


</div>

**Predicates.**

<div class="math-left">

```math
\begin{aligned}
&=0_{integer}(x) \Leftarrow \Uparrow (x = 0) \ \blacksquare \\
&<0_{integer}(x) \Leftarrow \Uparrow x < 0 \ \blacksquare \\
&=_{integer}(a, b) \Leftarrow \Uparrow a = b \ \blacksquare \\
&unit_{integer}(x) \Leftarrow \textbf{if } ((x = 1) \ | \ (x = -1)) \textbf{ then } \Uparrow x \ \blacksquare
\end{aligned}
```


</div>

**Commands.**

<div class="math-left">

```math
\begin{aligned}
&print_{integer}(x) \Leftarrow \textbf{if } x < 0 \textbf{ then } writes(\text{"("},\ x,\ \text{")"}) \textbf{ else } writes(x) \ \blacksquare
\end{aligned}
```


</div>


### 2.3. Domain constructors

EUCLID provides three classes of domain constructions: quotient domains $`Q_{D}`$, modular domains $`D/(e)`$, polynomials $`D[x]`$ and truncated power series $`T(D[[x]])_{n}`$.


#### 2.3.1. Quotient Euclidean domain $`\mathcal{Q}`$

<p align="center"><strong>Quotient Domain Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $`\mathcal{Q}`$ |
| **Constants** | $`0_{\mathcal{Q}}`$, $`1_{\mathcal{Q}}`$, $`k_{i\mathcal{Q}_x}`$ |
| **Operators** | $`\oplus_{\mathcal{Q}}`$, $`-_{\mathcal{Q}}`$, $`\otimes_{\mathcal{Q}}`$, $`\mathbin{⨸}_{\mathcal{Q}}`$, $`mod_{\mathcal{Q}}`$, $`normalize_{\mathcal{Q}}`$, $`deg_{\mathcal{Q}}`$ |
| **Predicates** | $`=_{\mathcal{Q}}`$, $`unit_{\mathcal{Q}}`$ |
| **Commands** | $`print_{\mathcal{Q}}`$ |

**Data structures.** The domains $`\mathcal{Q}`$ are of the form $`\mathcal{Q}=\{\frac{m}{n} \mid m, n \in D, n \neq 0\}`$, for some Euclidean domain $`D`$. Elements of such a domain $`\mathcal{Q}`$ are quotients with a dividend and a divisor:

<div class="math-left">

```math
\begin{aligned}
&\textbf{record } Q\ (dividend, divisor)
\end{aligned}
```


</div>

**Constants.**

<div class="math-left">

```math
\begin{aligned}
&0_{\mathcal{Q}}(x) \Leftarrow \Uparrow Q(0(x.dividend), 1(x.dividend)) \ \blacksquare \\
&1_{\mathcal{Q}}(x) \Leftarrow \Uparrow Q(1(x.dividend), 1(x.dividend)) \ \blacksquare \\
&k_{i\mathcal{Q}_x}(l, j) \Leftarrow \Uparrow term(Q(l, 1(l)), j) \ \blacksquare
\end{aligned}
```


</div>

**Operators.** Let $`a = \frac{p}{q}`$, $`b = \frac{p'}{q'}`$. Then $`a + b = \frac{x}{y}`$ where $`x = pq' \oplus p'q`$, $`y = qq'`$.

<div class="math-left">

```math
\begin{aligned}
&\oplus_{\mathcal{Q}}(a, b) \Leftarrow \\
&\quad \textbf{local } zz,\ top \\
&\quad top \mathrel{:=} \oplus(\otimes(a.dividend, b.divisor), \otimes(b.dividend, a.divisor)) \\
&\quad zz \mathrel{:=} 0(a.dividend) \\
&\quad \Uparrow \textbf{if } =_{\mathcal{Q}}(top, zz) \textbf{ then } Q(zz, 1(a.dividend)) \\
&\quad \textbf{else } normalize_{\mathcal{Q}}(Q(top, \otimes(a.divisor, b.divisor))) \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&-_{\mathcal{Q}}(x) \Leftarrow \Uparrow Q(-(x.dividend), x.divisor) \ \blacksquare \\
&\\
&\otimes_{\mathcal{Q}}(a, b) \Leftarrow \Uparrow normalize_{\mathcal{Q}}(Q(\otimes(a.dividend, b.dividend), \otimes(a.divisor, b.divisor))) \ \blacksquare \\
&\\
&\mathbin{⨸}_{\mathcal{Q}}(a, b) \Leftarrow \\
&\quad \textbf{local } zz \\
&\quad zz \mathrel{:=} 0(b.dividend) \\
&\quad \textbf{if } =(b.dividend, zz) \textbf{ then } \text{pr}\{\text{"ERROR: divide by 0 in } \mathcal{Q}\text{"}\} \\
&\quad \textbf{else } \Uparrow (\textbf{if } =(a.divisor, zz) \textbf{ then } 0_{\mathcal{Q}}(a) \\
&\quad\quad \textbf{else } normalize_{\mathcal{Q}}(Q(\otimes(a.dividend, b.divisor), \otimes(b.dividend, a.divisor)))) \ \blacksquare
\end{aligned}
```


</div>

There are no remainders in quotient division.

<div class="math-left">

```math
\begin{aligned}
&mod_{\mathcal{Q}}(a, m) \Leftarrow \Uparrow 0_{\mathcal{Q}}(a) \ \blacksquare
\end{aligned}
```


</div>

$`normalize_{\mathcal{Q}}(x)`$ reduces the size of the dividend and divisor, and ensures that any negative sign is in the dividend. Let $`g = GCD(x, y)`$. Then $`normalize_{\mathcal{Q}}(\frac{x}{y}) = \frac{x \mathbin{⨸} g}{y \mathbin{⨸} g}`$.

<div class="math-left">

```math
\begin{aligned}
&normalize_{\mathcal{Q}}(x) \Leftarrow \\
&\quad \textbf{local } g,\ top,\ bottom \\
&\quad g \mathrel{:=} GCD(x.dividend, x.divisor) \\
&\quad top \mathrel{:=} \mathbin{⨸}(x.dividend, g) \\
&\quad bottom \mathrel{:=} \mathbin{⨸}(x.divisor, g) \\
&\quad \Uparrow (\textbf{if } <0(bottom) \textbf{ then } Q(-(top), -(bottom)) \\
&\quad\quad \textbf{else } Q(top, bottom)) \ \blacksquare
\end{aligned}
```


</div>

```icon

d8g_Q (X) 4= it X ■
```

**Predicates.**

$`\frac{p}{q} = \frac{p'}{q'}`$ if and only if $`pq' = qp'`$.

<div class="math-left">

```math
\begin{aligned}
&=_{\mathcal{Q}}(a, b) \Leftarrow \Uparrow (=(\otimes(a.divisor, b.dividend), \otimes(b.divisor, a.dividend))) \ \blacksquare
\end{aligned}
```


</div>

Everything is a unit in $`\mathcal{Q}`$.

<div class="math-left">

```math
\begin{aligned}
&unit_{\mathcal{Q}}(x) \Leftarrow \Uparrow \ \blacksquare
\end{aligned}
```


</div>

**Commands.**

<div class="math-left">

```math
\begin{aligned}
&print_{\mathcal{Q}}(x) \Leftarrow \\
&\quad \textbf{if } =(x.divisor, 1(x.divisor)) \\
&\quad \textbf{then } prs\{x.dividend,\ \text{"q"}\} \\
&\quad \textbf{else } prs\{\text{"("},\ x.dividend,\ \text{"/"},\ x.divisor,\ \text{")q"}\} \ \blacksquare
\end{aligned}
```


</div>


#### 2.3.2. Modular Euclidean domain $`D/(x)`$

<p align="center"><strong>Modular Domain Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $`modulo`$ |
| **Constants** | $`0_{modulo}`$, $`1_{modulo}`$ |
| **Operators** | $`\oplus_{modulo}`$, $`-_{modulo}`$, $`\otimes_{modulo}`$, $`\mathbin{⨸}_{modulo}`$, $`normalize_{modulo}`$, $`deg_{modulo}`$ |
| **Predicates** | $`=_{modulo}`$, $`unit_{modulo}`$, $`<0_{modulo}`$ |
| **Commands** | $`print_{modulo}`$ |

**Data structures.**

An item from a modular domain, say $`Z_{5}`$, is specified by the item in the “base” domain, plus the modulus.

<div class="math-left">

```math
\begin{aligned}
&\textbf{record } modulo\ (item, modulus)
\end{aligned}
```


</div>

**Constants.**

<div class="math-left">

```math
\begin{aligned}
&0_{modulo}(a) \Leftarrow \Uparrow modulo(0(a.item), a.modulus) \ \blacksquare \\
&1_{modulo}(a) \Leftarrow \Uparrow modulo(1(a.item), a.modulus) \ \blacksquare
\end{aligned}
```


</div>

**Operators.**

<div class="math-left">

```math
\begin{aligned}
&\oplus_{modulo}(a, b) \Leftarrow \Uparrow normalize_{modulo}(modulo(\oplus(a.item, b.item), a.modulus)) \ \blacksquare \\
&-_{modulo}(x) \Leftarrow \Uparrow normalize_{modulo}(modulo(-(x.item), x.modulus)) \ \blacksquare \\
&\otimes_{modulo}(a, b) \Leftarrow \Uparrow normalize_{modulo}(modulo(\otimes(a.item, b.item), a.modulus)) \ \blacksquare \\
&\mathbin{⨸}_{modulo}(a, b) \Leftarrow \Uparrow normalize_{modulo}(modulo(\otimes(a.item, INVERSE(b.item, b.modulus)), a.modulus)) \ \blacksquare \\
&\\
&normalize_{modulo}(x) \Leftarrow \Uparrow modulo(mod(x.item, x.modulus), x.modulus) \ \blacksquare \\
&deg_{modulo}(x) \Leftarrow \Uparrow mod(x.item, x.modulus) \ \blacksquare
\end{aligned}
```


</div>

**Predicates.**

<div class="math-left">

```math
\begin{aligned}
&=_{modulo}(a, b) \Leftarrow \Uparrow (=(mod(a.item, a.modulus), mod(b.item, b.modulus))) \ \blacksquare \\
&unit_{modulo}(a) \Leftarrow \Uparrow (=(\$mod\$(a.item, a.modulus), 1)) \ \blacksquare
\end{aligned}
```


</div>

Nothing is negative in a modular domain.

<div class="math-left">

```math
\begin{aligned}
&<0_{modulo}(a) \Leftarrow \bot \ \blacksquare
\end{aligned}
```


</div>

**Commands.**

<div class="math-left">

```math
\begin{aligned}
&print_{modulo}(x) \Leftarrow prs\{\text{"("},\ x.item,\ \text{" mod "},\ x.modulus,\ \text{")"}\} \ \blacksquare
\end{aligned}
```


</div>


#### 2.3.3. Polynomial Euclidean domain $`D[x]`$

<p align="center"><strong>Polynomial Domain Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $`poly`$, $`term`$; $`poly\_of`$, $`0th\_coef`$, $`lead\_coef`$ |
| **Constants** | $`0_{poly}`$, $`1_{poly}`$, $`k_{Z_Q}`$, $`k_{Z_{Qx}}`$, $`k_{Z_x}`$ |
| **Operators** | $`\oplus_{poly}`$, $`-_{poly}`$, $`\otimes_{poly}`$, $`\mathbin{⨸}_{poly}`$, $`mod_{poly}`$, $`eval_{poly}`$, $`deg_{poly}`$, $`-_{deg}`$, $`\oplus_{deg}`$, $`normalize_{poly}`$ |
| **Predicates** | $`<_{degree}`$, $`=_{poly}`$, $`unit_{poly}`$ |
| **Commands** | $`print_{poly}`$ |

**Data structures.** Polynomials $`a(x) \in D[x]`$ are finite sums of the form

$$a(x) = \sum_{i=0}^{m} a_i x^i$$

They are represented as lists of terms, in increasing order of power, such that there is always at least one term, 0, if the polynomial is zero. Otherwise the least term may be of any degree.

<div class="math-left">

```math
\begin{aligned}
&\textbf{record } poly\ (terms) \\
&poly\_of(x) \Leftarrow \Uparrow poly([term(x, 0)]) \ \blacksquare
\end{aligned}
```


</div>

The coefficient of the constant term as an element of $`D`$, if there is a constant term, otherwise 0, may be obtained with:

<div class="math-left">

```math
\begin{aligned}
&0th\_coef(fx) \Leftarrow \\
&\quad \textbf{local } a \\
&\quad a \mathrel{:=} fx.terms[1] \\
&\quad \Uparrow (\textbf{if } a.power = 0 \textbf{ then } a.coef \textbf{ else } 0(a.coef)) \ \blacksquare
\end{aligned}
```


</div>

The coefficient of the term with the highest degree may be obtained with:

<div class="math-left">

```math
\begin{aligned}
&lead\_coef(ax) \Leftarrow \Uparrow (ax.terms[\texttt{*}ax.terms]).coef \ \blacksquare
\end{aligned}
```


</div>

A term, say $`ax^n`$, is represented as $`coef \cdot X^{power}`$. It is assumed that coefficient and indeterminate range over the same base domain, and that the power ranges over $`\mathcal{N}`$.

<div class="math-left">

```math
\begin{aligned}
&\textbf{record } term\ (coef, power)
\end{aligned}
```


</div>

**Constants.**

The zero of the base domain of a coefficient of the polynomial is obtained via:

<div class="math-left">

```math
\begin{aligned}
&0_{poly}(p) \Leftarrow \\
&\quad z \mathrel{:=} 0(p.terms[1].coef) \\
&\quad \Uparrow poly([term(z, 0)]) \ \blacksquare
\end{aligned}
```


</div>

**Example.** The result of evaluating

<div class="math-left">

```math
\begin{aligned}
&\text{pr}\{\text{"Q:    0 = "},\ 0_{poly}(poly([term(Q(-2,1), 0)]))\} \\
&\text{pr}\{\text{"QZ:   0 = "},\ 0_{poly}(poly([term(k_{Z_{Qx}}(-2, 0)]))\}
\end{aligned}
```


</div>

is

$`Q\text{:    0 = }0_{q}`$  
$`QZ\text{:   0 = }0_{zq}`$

The one of the base domain of a coefficient of the polynomial may be obtained with: 

<div class="math-left">

```math
\begin{aligned}
&1_{poly}(p) \Leftarrow \\
&\quad z \mathrel{:=} 1(p.terms[1].coef) \\
&\quad \Uparrow poly([term(z, 0)]) \ \blacksquare
\end{aligned}
```


</div>

An arbitrary-precision rational whole number is obtained with:

<div class="math-left">

```math
\begin{aligned}
&k_{Z_Q}(e) \Leftarrow \\
&\quad top \mathrel{:=} k_Z(e) \\
&\quad \Uparrow Q(top, 1_Z(top)) \ \blacksquare
\end{aligned}
```


</div>

An arbitrary-precision rational whole number-coefficient indeterminate $`e x^y`$ is obtained with:

<div class="math-left">

```math
\begin{aligned}
&k_{Z_{Qx}}(e, y) \Leftarrow \Uparrow term(k_{Z_Q}(e), y) \ \blacksquare
\end{aligned}
```


</div>

An arbitrary-precision integer-coefficient indeterminate $`e x^y`$ is obtained with:

<div class="math-left">

```math
\begin{aligned}
&k_{Z_x}(e, y) \Leftarrow \Uparrow term(k_Z(e), y) \ \blacksquare
\end{aligned}
```


</div>

**Operators.**

<div class="math-left">

```math
\begin{aligned}
&\oplus_{poly}(a, b) \Leftarrow \\
&\quad \textbf{local } Terms,\ T,\ z \\
&\quad Terms \mathrel{:=} \oplus_{terms}(a.terms, b.terms) \\
&\quad T \mathrel{:=} [];\ z \mathrel{:=} 0(a.terms[1].coef) \\
&\quad \textbf{every } t \mathrel{:=} \texttt{!}Terms \textbf{ do if not } =(t.coef, z) \textbf{ then } T \mathrel{\texttt{|||}}\mathrel{:=} \ [t] \\
&\quad \Uparrow (\textbf{if } \texttt{*}T > 0 \textbf{ then } poly(T) \textbf{ else } 0(a)) \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&\oplus_{terms}(a, b) \Leftarrow \\
&\quad \textbf{local } c\_coef,\ at,\ ap,\ ac,\ bt,\ bp,\ bc \\
&\quad \Uparrow ( \\
&\quad\quad \textbf{if } \texttt{*}a = 0 \textbf{ then } b \\
&\quad\quad \textbf{else if } \texttt{*}b = 0 \textbf{ then } a \\
&\quad\quad \textbf{else } \{ \\
&\quad\quad\quad at \mathrel{:=} a[1];\ ap \mathrel{:=} at.power;\ ac \mathrel{:=} at.coef \\
&\quad\quad\quad bt \mathrel{:=} b[1];\ bp \mathrel{:=} bt.power;\ bc \mathrel{:=} bt.coef \\
&\quad\quad\quad \textbf{if } less(ap, bp) \\
&\quad\quad\quad \textbf{then } \{ \\
&\quad\quad\quad\quad \textbf{if } =(ac, 0(ac)) \\
&\quad\quad\quad\quad \textbf{then } \oplus_{terms}(rest(a), b) \\
&\quad\quad\quad\quad \textbf{else } [at] \ \mathrel{\texttt{||}} \ \oplus_{terms}(rest(a), b) \} \\
&\quad\quad\quad \textbf{else if } =(ap, bp) \\
&\quad\quad\quad \textbf{then } \{ \\
&\quad\quad\quad\quad c\_coef \mathrel{:=} \oplus(ac, bc) \\
&\quad\quad\quad\quad \textbf{if } =(c\_coef, 0(c\_coef)) \\
&\quad\quad\quad\quad \textbf{then } \oplus_{terms}(rest(a), rest(b)) \\
&\quad\quad\quad\quad \textbf{else } [term(c\_coef, ap)] \ \mathrel{\texttt{||}} \ \oplus_{terms}(rest(a), rest(b)) \} \\
&\quad\quad\quad \textbf{else } \oplus_{terms}(b, a) \} \\
&\quad ) \ \blacksquare
\end{aligned}
```


</div>

**Example.** The result of evaluating 

<div class="math-left">

```math
\begin{aligned}
&ax \mathrel{:=} poly([term(Q(-2,1), 0), term(Q(1,1), 3)]) \\
&bx \mathrel{:=} poly([term(Q(-3,1), 0), term(Q(2,1), 3)]) \\
&fx \mathrel{:=} poly([k_{Z_{Qx}}(-2, 0), k_{Z_{Qx}}(1,3)]) \\
&gx \mathrel{:=} poly([k_{Z_{Qx}}(-3, 0), k_{Z_{Qx}}(2,3)]) \\
&\text{pr}\{\text{"Q: ("},\ ax,\ \text{") + ("},\ bx,\ \text{") = "},\ \oplus_{poly}(ax, bx)\} \\
&\text{pr}\{\text{"QZ: ("},\ fx,\ \text{") + ("},\ gx,\ \text{") = "},\ \oplus_{poly}(fx, gx)\}
\end{aligned}
```


</div>

is

$`Q\text{: }(-2)q + 1q \cdot X^3) + ((-3)q + 2q \cdot X^3) = (-5)q + 3q \cdot X^3`$  
$`QZ\text{: }((-2z)q + 1zq \cdot X^3) + ((-3z)q + 2zq \cdot X^3) = (-5z)q + 3zq \cdot X^3`$

<div class="math-left">

```math
\begin{aligned}
&-_{poly}(x) \Leftarrow \\
&\quad \textbf{local } c \\
&\quad c \mathrel{:=} [] \\
&\quad \textbf{every } t \mathrel{:=} \texttt{!}x.terms \textbf{ do } c \mathrel{\texttt{|||}}\mathrel{:=} \ [-_{term}(t)] \\
&\quad \Uparrow poly(c) \ \blacksquare \\
&\\
&-_{term}(t) \Leftarrow \Uparrow term(-(t.coef), t.power) \ \blacksquare
\end{aligned}
```


</div>

**Example.** The result of evaluating

<div class="math-left">

```math
\begin{aligned}
&ax \mathrel{:=} poly([term(Q(-2,1), 0), term(Q(1,1), 3)]) \\
&fx \mathrel{:=} poly([k_{Z_{Qx}}(-2, 0), k_{Z_{Qx}}(1,3)]) \\
&\text{pr}\{\text{"Q:  - ("},\ ax,\ \text{") = "},\ -_{poly}(ax)\} \\
&\text{pr}\{\text{"QZ: - ("},\ fx,\ \text{") = "},\ -_{poly}(fx)\}
\end{aligned}
```


</div>

is

$`Q\text{:  - }((-2)q + 1q \cdot X^3) = 2q + (-1)q \cdot X^3`$  
$`QZ\text{: - }((-2z)q + 1zq \cdot X^3) = 2zq + (-1z)q \cdot X^3`$

<div class="math-left">

```math
\begin{aligned}
&\otimes_{poly}(a, b) \Leftarrow \Uparrow \otimes_{poly\_terms}(a, b.terms) \ \blacksquare \\
&\\
&\otimes_{poly\_terms}(a, b\_terms) \Leftarrow \\
&\quad \Uparrow (\textbf{if } \texttt{*}b\_terms = 0 \textbf{ then } 0(a) \\
&\quad\quad \textbf{else } \oplus_{poly}(\otimes_{poly\_term}(a, b\_terms[1]), \\
&\quad\quad\quad \otimes_{poly\_terms}(a, rest(b\_terms)))) \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&\otimes_{poly\_term}(a, b\_term) \Leftarrow \\
&\quad \Uparrow (\textbf{if } \texttt{*}a.terms < 2 \\
&\quad\quad \textbf{then } poly([\otimes_{term\_term}(a.terms[1], b\_term)]) \\
&\quad\quad \textbf{else } \oplus_{poly}(poly([\otimes_{term\_term}(a.terms[1], b\_term)]), \\
&\quad\quad\quad \otimes_{poly\_term}(poly(rest(a.terms)), b\_term))) \ \blacksquare \\
&\\
&\otimes_{term\_term}(a\_term, b\_term) \Leftarrow \\
&\quad \Uparrow term(\otimes(a\_term.coef, b\_term.coef), a\_term.power + b\_term.power) \ \blacksquare
\end{aligned}
```


</div>

**Example.** The result of evaluating

<div class="math-left">

```math
\begin{aligned}
&ax \mathrel{:=} poly([term(Q(-2,1), 0), term(Q(1,1), 3)]) \\
&bx \mathrel{:=} poly([term(Q(-3,1), 0), term(Q(2,1), 3)]) \\
&fx \mathrel{:=} poly([k_{Z_{Qx}}(-2, 0), k_{Z_{Qx}}(1,3)]) \\
&gx \mathrel{:=} poly([k_{Z_{Qx}}(-3, 0), k_{Z_{Qx}}(2,3)]) \\
&\text{pr}\{\text{"Q:    ("},\ ax,\ \text{") * ("},\ bx,\ \text{") = "},\ \otimes_{poly}(ax, bx)\} \\
&\text{pr}\{\text{"QZ:   ("},\ fx,\ \text{") * ("},\ gx,\ \text{") = "},\ \otimes_{poly}(fx, gx)\}
\end{aligned}
```


</div>

is

$`Q\text{:    }((-2)q + 1q \cdot X^3) * ((-3)q + 2q \cdot X^3) = 6q + (-7)q \cdot X^3 + 2q \cdot X^6`$  
$`QZ\text{:   }((-2z)q + 1zq \cdot X^3) * ((-3z)q + 2zq \cdot X^3) = 6zq + (-7z)q \cdot X^3 + 2zq \cdot X^6`$

<div class="math-left">

```math
\begin{aligned}
&\mathbin{⨸}_{poly}(a, b) \Leftarrow \\
&\quad \textbf{local } n,\ m,\ r,\ q,\ quotient \\
&\quad n \mathrel{:=} deg_{poly}(b) \\
&\quad r \mathrel{:=} copy(a) \\
&\quad quotient \mathrel{:=} 0_{poly}(r) \\
&\quad \textbf{repeat } \{ \\
&\quad\quad m \mathrel{:=} deg_{poly}(r) \\
&\quad\quad \textbf{if } <_{degree}(m, n) \\
&\quad\quad \textbf{then } \Uparrow quotient \\
&\quad\quad \textbf{else } \{ q \mathrel{:=} poly([term(\mathbin{⨸}(lead\_coef(r), lead\_coef(b)), m - n)]) \\
&\quad\quad\quad \textbf{if } m = 0 \\
&\quad\quad\quad \textbf{then } \Uparrow \oplus_{poly}(quotient, q) \\
&\quad\quad\quad \textbf{else } \{ subtrahend \mathrel{:=} -_{poly}(\otimes_{poly}(q, b)) \\
&\quad\quad\quad\quad r \mathrel{:=} \oplus_{poly}(r, subtrahend) \\
&\quad\quad\quad\quad quotient \mathrel{:=} \oplus_{poly}(quotient, q) \} \} \} \ \blacksquare
\end{aligned}
```


</div>

**Example.** The result of evaluating

<div class="math-left">

```math
\begin{aligned}
&ax \mathrel{:=} poly\_of(1);\ bx \mathrel{:=} poly\_of(3) \\
&\text{pr}\{\text{"integers: "},\ ax,\ \text{"/"},\ bx,\ \text{" = "},\ \mathbin{⨸}_{poly}(ax, bx)\} \\
&ax \mathrel{:=} poly([term(Q(5,9), 0)]) \\
&bx \mathrel{:=} poly([term(Q(-2,1), 0), term(Q(3,2), 1)]) \\
&fx \mathrel{:=} poly([term(Q(k_Z(5), k_Z(9)), 0)]) \\
&gx \mathrel{:=} poly([term(Q(k_Z(-2), k_Z(1)), 0), term(Q(k_Z(3), k_Z(2)), 1)]) \\
&\text{pr}\{\text{"Q: ("},\ ax,\ \text{") / ("},\ bx,\ \text{") = "},\ \mathbin{⨸}_{poly}(ax, bx)\} \\
&\text{pr}\{\text{"QZ: ("},\ gx,\ \text{") / ("},\ fx,\ \text{") = "},\ \mathbin{⨸}_{poly}(gx, fx)\} \\
&ax \mathrel{:=} poly([term(Q(k_Z(166), k_Z(243)), 0), term(Q(k_Z(-275), k_Z(243)), 1)]) \\
&bx \mathrel{:=} poly([term(Q(k_Z(115668), k_Z(75625)), 0)]) \\
&\text{pr}\{\text{"QZ[x]: ("},\ ax,\ \text{"/ "},\ bx,\ \text{") = "},\ \mathbin{⨸}(ax, bx)\}
\end{aligned}
```


</div>

is

$`\text{integers: }1/3 = 0`$  
$`Q\text{: }((5/9)q) / ((-2)q + (3/2)q \cdot X) = 0q`$  
$`QZ\text{: }((-2z)q + (3z/2z)q \cdot X) / ((5z/9z)q) = ((-18z)/5z)q + (27z/10z)q \cdot X`$  
$`QZ[x]\text{: }((166z/243z)q + ((-275z)/243z)q \cdot X) / ((115668z/75625z)q) = (6276875z/14053662z)q + ((-20796875z)/28107324z)q \cdot X`$

<div class="math-left">

```math
\begin{aligned}
&mod_{poly}(a, b) \Leftarrow \Uparrow \ominus(a, \otimes(b, \mathbin{⨸}(a, b))) \ \blacksquare
\end{aligned}
```


</div>

Evaluate $`f(x)`$ at $`a`$, that is evaluate $`f(a)`$:

<div class="math-left">

```math
\begin{aligned}
&eval_{poly}(fx, a) \Leftarrow \\
&\quad \textbf{local } r \\
&\quad r \mathrel{:=} 0(a) \\
&\quad \textbf{every } x \mathrel{:=} \texttt{!}fx.terms \textbf{ do } r \mathrel{:=} \oplus(r, eval_{term}(x, a)) \\
&\quad \Uparrow r \ \blacksquare
\end{aligned}
```


</div>

Evaluate $`cx^p`$ at $`x=a`$:

<div class="math-left">

```math
\begin{aligned}
&eval_{term}(t, a) \Leftarrow \Uparrow \otimes(t.coef, exp(a, t.power)) \ \blacksquare
\end{aligned}
```


</div>

Degrees of polynomials are values which may be integers, or the string `"- infinity"`. Accordingly, special subtraction and addition procedures are required.

<div class="math-left">

```math
\begin{aligned}
&deg_{poly}(x) \Leftarrow \textbf{if } {=}_{poly}(x, 0_{poly}(x)) \textbf{ then } \Uparrow \text{\text{-} infinity} \textbf{ else } \Uparrow x.\mathrm{terms}[\texttt{*}x.\mathrm{terms}].\mathrm{power} \ \blacksquare
\end{aligned}
```

</div>

<div class="math-left">

```math
\begin{aligned}
&{-}_{deg}(a, b) \Leftarrow \Uparrow (\textbf{if } \text{type}(a) \mathrel{==} \text{"string"} \textbf{ then } b \textbf{ else if } \text{type}(b) \mathrel{==} \text{"string"} \textbf{ then } a \textbf{ else } a - b) \ \blacksquare
\end{aligned}
```

</div>

<div class="math-left">

```math
\begin{aligned}
&\oplus_{deg}(a, b) \Leftarrow \Uparrow (\textbf{if } \text{type}(a) \mathrel{==} \text{"string"} \textbf{ then } b \textbf{ else if } \text{type}(b) \mathrel{==} \text{"string"} \textbf{ then } a \textbf{ else } a + b) \ \blacksquare
\end{aligned}
```

</div>

A normal-form polynomial is one whose terms are in normal form (and in ascending order of power).

<div class="math-left">

```math
\begin{aligned}
&normalize_{poly}(x) \Leftarrow \\
&\quad \textbf{local } ts \\
&\quad ts \mathrel{:=} [] \\
&\quad \textbf{every } t \mathrel{:=} \texttt{!}x.terms \textbf{ do } ts \mathrel{\texttt{|||}}\mathrel{:=} \ [term(normalize(t.coef), t.power)] \\
&\quad \Uparrow poly(ts) \ \blacksquare
\end{aligned}
```


</div>

**Predicates.**

<div class="math-left">

```math
\begin{aligned}
&{<}_{degree}(a, b) \Leftarrow \\
&\quad \textbf{if } \text{type}(a) \mathrel{==} \text{"string"} \\
&\quad \textbf{then } \Uparrow not(\text{type}(b) \mathrel{==} \text{"string"}) \\
&\quad \textbf{else } \Uparrow a < b \ \blacksquare
\end{aligned}
```

```math
\begin{aligned}
&{=}_{poly}(a, b) \Leftarrow \Uparrow {=}_{terms}(a.terms, b.terms) \ \blacksquare
\end{aligned}
```

```math
\begin{aligned}
&{=}_{terms}(a, b) \Leftarrow \\
&\quad \textbf{if } \texttt{*}a \neq \texttt{*}b \textbf{ then } \bot \\
&\quad \textbf{if } \texttt{*}a = 0 \textbf{ then } \Uparrow \\
&\quad \textbf{if } {=}_{term}(a[1], b[1]) \textbf{ then } \Uparrow {=}_{terms}(rest(a), rest(b)) \ \blacksquare
\end{aligned}
```

```math
\begin{aligned}
&{=}_{term}(a, b) \Leftarrow \Uparrow (=(a.coef, b.coef) \ \&\ =(a.power, b.power)) \ \blacksquare
\end{aligned}
```

```math
\begin{aligned}
&unit_{poly}(x) \Leftarrow \Uparrow ((\texttt{*}x.terms = 1) \ \&\ (x.terms[1].power = 0) \ \&\ unit(x.terms[1].coef)) \ \blacksquare
\end{aligned}
```


</div>

**Commands.**

<div class="math-left">

```math
\begin{aligned}
&print_{poly}(x) \Leftarrow \\
&\quad print_{term}(x.terms[1]) \\
&\quad \textbf{every } t \mathrel{:=} \texttt{!}rest(x.terms) \textbf{ do } \{ writes(\text{"+ "});\ print_{term}(t) \} \ \blacksquare \\
&\\
&print_{term}(x) \Leftarrow \\
&\quad print(x.coef) \\
&\quad \textbf{if } x.power = 1 \textbf{ then } writes(\text{"\texttt{*}X"}) \\
&\quad \textbf{else if } x.power > 1 \textbf{ then } prs\{\text{"\texttt{*}X\^{}"},\ x.power\} \ \blacksquare
\end{aligned}
```


</div>


#### 2.3.4. Truncated Power Series domain $`T(D[[x]])_{n}`$

<p align="center"><strong>Truncated Power Series Domain Arithmetic Facilities</strong></p>

| | |
|:--|:--|
| **Data structures** | $`tpower`$ |
| **Constants** | $`0_{tpower}`$, $`1_{tpower}`$ |
| **Operators** | $`\oplus_{tpower}`$, $`-_{tpower}`$, $`\otimes_{tpower}`$, $`\mathbin{⨸}_{tpower}`$, $`normalize_{tpower}`$ |
| **Predicates** | $`=_{tpower}`$, $`unit_{tpower}`$ |
| **Commands** | $`print_{tpower}`$ |

**Data structures.**

<div class="math-left">

```math
\begin{aligned}
&\textbf{record } tpower\ (Poly, N)
\end{aligned}
```


</div>

**Constants.**

The zero of the base domain of a coefficient of the polynomial:

<div class="math-left">

```math
\begin{aligned}
&0_{tpower}(x) \Leftarrow \Uparrow tpower(0_{poly}(x.Poly), x.N) \ \blacksquare
\end{aligned}
```


</div>

The one of the base domain of a coefficient of the polynomial:

<div class="math-left">

```math
\begin{aligned}
&1_{tpower}(x) \Leftarrow \Uparrow tpower(1_{poly}(x.Poly), x.N) \ \blacksquare
\end{aligned}
```


</div>

**Operators.**

<div class="math-left">

```math
\begin{aligned}
&\oplus_{tpower}(a, b) \Leftarrow \Uparrow tpower(\oplus_{poly}(a.Poly, b.Poly), a.N) \ \blacksquare \\
&\\
&-_{tpower}(x) \Leftarrow \Uparrow tpower(-_{poly}(x.Poly), x.N) \ \blacksquare \\
&\\
&truncate(p, n) \Leftarrow \Uparrow poly(p.terms[1:n+1]) \ \blacksquare \\
&\\
&\otimes_{tpower}(a, b) \Leftarrow \Uparrow tpower(truncate(\otimes_{poly}(a.Poly, b.Poly), a.N), a.N) \ \blacksquare \\
&\\
&\mathbin{⨸}_{tpower}(a, b) \Leftarrow \Uparrow tpower(truncate(\mathbin{⨸}_{poly}(a.Poly, b.Poly), a.N), a.N) \ \blacksquare \\
&\\
&normalize_{tpower}(x) \Leftarrow \Uparrow tpower(normalize_{poly}(x.Poly), x.N) \ \blacksquare
\end{aligned}
```


</div>

**Predicates.**

<div class="math-left">

```math
\begin{aligned}
&=_{tpower}(a, b) \Leftarrow \Uparrow (a.N = b.N) \ \&\ =_{poly}(a.Poly, b.Poly) \ \blacksquare \\
&\\
&unit_{tpower}(x) \Leftarrow \Uparrow unit_{poly}(x.Poly) \ \blacksquare
\end{aligned}
```


</div>

**Commands.**

<div class="math-left">

```math
\begin{aligned}
&print_{tpower}(x) \Leftarrow print_{poly}(x.Poly) \ \blacksquare
\end{aligned}
```


</div>


## 3. Algorithms for various problems over Euclidean domains

We provide algorithms for a number of application areas:

- GCD, linear congruences and Diophantine equations.
- Polynomial remainder sequences.
- Power series and polynomial inversion and interpolation.

In addition, we provide a simple timer facility.


### 3.1. GCD, Linear Congruences and Diophantine Equations

We provide algorithms for the following applications:

- Euclid's algorithm for greatest common divisor, in simple and extended versions.
- Inverse of $`a \bmod m`$.
- The Chinese Remainder for 1, 2, or $`N`$ congruences.
- The solutions to the Diophantine equation $`ax + by = c`$.


#### 3.1.1. Greatest Common Divisor

We have two versions of Euclid's Algorithm over a Euclidean domain $`D`$, from Lipson, p. 226 and p. 209.

**GCD**$`(a, b, D)`$  
Input: $`a, b \in D`$, not both zero.  
Output: a gcd of $`a`$, $`b`$.

<div class="math-left">

```math
\begin{aligned}
&GCD(a, b) \Leftarrow \\
&\quad \Uparrow (\textbf{if } =(b, 0(b)) \textbf{ then } normalize(a) \\
&\quad\quad \textbf{else } GCD(b, mod(a, b))) \ \blacksquare
\end{aligned}
```


</div>

The following is a table of expressions and their gcd's, as computed via GCD:

<p align="center"><strong>Greatest Common Divisors</strong></p>

| Domain | $`A`$ | $`B`$ | GCD |
|:--|:--|:--|:--|
| $`Z`$ | $`121903z`$ | $`5335z`$ | $`1z`$ |
| $`Z`$ | $`-18z`$ | $`5z`$ | $`1z`$ |
| $`Z`$ | $`228z`$ | $`612z`$ | $`12z`$ |
| $`Q[x]`$ | $`(-2)q + 1q \cdot X^3`$ | $`(-3)q + 2q \cdot X^2`$ | $`(5/9)q`$ |
| $`Z_{5}`$ | $`((-2) \bmod 5)`$ | $`((-3) \bmod 5)`$ | $`(2 \bmod 5)`$ |
| $`Z_{5}[x]`$ | $`((-2) \bmod 5) + (1 \bmod 5) \cdot X^3`$ | $`((-3) \bmod 5) + (2 \bmod 5) \cdot X^2`$ | $`(3 \bmod 5) + (4 \bmod 5) \cdot X`$ |
| $`QZ[x]`$ | $`(166z/243z)q + ((-275z)/243z)q \cdot X`$ | $`(115668z/75625z)q`$ | $`(115668z/75625z)q`$ |
| $`QZ[x]`$ | $`(-2z)q + 1zq \cdot X^3`$ | $`(-3z)q + 2zq \cdot X^2`$ | $`(5z/9z)q`$ |

**EUCLID**$`(a, b)`$  
Input: $`a, b \in D`$, not both zero.  
Output: $`g, s, t`$ such that $`g`$ is a gcd of $`a`$, $`b`$ and $`g = sa + tb`$.

<div class="math-left">

```math
\begin{aligned}
&EUCLID(A, B) \Leftarrow \\
&\quad \textbf{local } q,\ a,\ s,\ t \\
&\quad a \mathrel{:=} [copy(A), copy(B)] \\
&\quad s \mathrel{:=} [1(A), 0(A)] \\
&\quad t \mathrel{:=} [0(A), 1(A)] \\
&\quad \textbf{while } not(=(a[2], 0(A))) \textbf{ do } \{ \\
&\quad\quad q \mathrel{:=} \mathbin{⨸}(a[1], a[2]) \\
&\quad\quad a \mathrel{:=} [a[2], \ominus(a[1], \otimes(a[2], q))] \\
&\quad\quad s \mathrel{:=} [s[2], \ominus(s[1], \otimes(s[2], q))] \\
&\quad\quad t \mathrel{:=} [t[2], \ominus(t[1], \otimes(t[2], q))] \} \\
&\quad \Uparrow [normalize(a[1]), normalize(s[1]), normalize(t[1])] \ \blacksquare
\end{aligned}
```


</div>

The following is a table of expressions and their extended *gcd*'s, as computed via EUCLID:

<p align="center"><strong>Extended Greatest Common Divisors</strong></p>

| $`A`$, $`B`$ | GCD, $`s`$, $`t`$ |
|:--|:--|
| $`2`$, $`4`$ | $`2`$, $`1`$, $`0`$ |
| $`228`$, $`612`$ | $`12`$, $`(-8)`$, $`3`$ |
| $`59`$, $`24`$ | $`1`$, $`11`$, $`(-27)`$ |
| $`(-2)q + 1q \cdot X^3`$, $`(-3)q + 2q \cdot X^2`$ | $`(5/9)q`$, $`(-16/9)q + (-4/3)q \cdot X`$, $`1q + (8/9)q \cdot X + (2/3)q \cdot X^2`$ |
| $`((-2) \bmod 5) + (1 \bmod 5) \cdot X^3`$, $`((-3) \bmod 5) + (2 \bmod 5) \cdot X^2`$ | $`(3 \bmod 5) + (4 \bmod 5) \cdot X`$, $`(1 \bmod 5)`$, $`(2 \bmod 5) \cdot X`$ |


#### 3.1.2. Modular Inverse

Our modular inverse algorithm is that of Lipson, p. 214.

**INVERSE**$`(a, m)`$: Computation of $`a^{-1} \bmod m`$  
Input: $`a, m \in D`$, where $`D`$ is a Euclidean domain.  
Output: If $`(m, a) = 1`$, then $`a^{-1} \bmod m`$; otherwise error.

<div class="math-left">

```math
\begin{aligned}
&INVERSE(a, m) \Leftarrow \\
&\quad \textbf{local } gst \\
&\quad gst \mathrel{:=} EUCLID(m, a) \\
&\quad \textbf{if } unit(gst[1]) \textbf{ then } \Uparrow mod(\mathbin{⨸}(gst[3], gst[1]), m) \\
&\quad \textbf{else } pr\{\text{"ERROR: "},\ a,\ \text{"\^{}-1 "},\ \text{" mod "},\ m,\ \text{" does not exist"}\} \ \blacksquare
\end{aligned}
```


</div>

A table of modular inverses as computed by INVERSE is as follows:

| $`x`$ | modulus | $`x^{-1}`$ |
|:--|:--|:--|
| $`30`$ | $`197`$ | $`46`$ |
| $`16`$ | $`21`$ | $`4`$ |
| $`18`$ | $`21`$ | ERROR |
| $`24`$ | $`59`$ | $`32`$ |
| $`(1 \bmod 2) + (1 \bmod 2) \cdot X^2`$ | $`(1 \bmod 2) + (1 \bmod 2) \cdot X^2 + (1 \bmod 2) \cdot X^5`$ | $`(1 \bmod 2) + (1 \bmod 2) \cdot X + (1 \bmod 2) \cdot X^2 + (1 \bmod 2) \cdot X^4`$ |
| $`(-3)q + 2q \cdot X^2`$ | $`(-2)q + 1q \cdot X^3`$ | $`(9/5)q + (8/5)q \cdot X + (6/5)q \cdot X^2`$ |


#### 3.1.3. Chinese Remainders and Single-Variable Linear Congruential Systems

We provide three algorithms, **CRA1** for solving equations of the form $`ax \equiv b \pmod m`$, and **CRA2** and **CRA** for solving systems of two or more congruences of the form $`X \equiv a \pmod m`$.

**CRA1**$`(a, b, m)`$: Solution of a single linear congruence relation.  
Input: $`a, b, m`$ such that $`ax \equiv b \pmod m`$.  
Output: a particular solution $`x_{1}`$.

Niven and Zuckerman [Niven80a], in their section 2.3 note that, given a congruence $`ax \equiv b \pmod m`$, we can reduce it to $`my \equiv -b \pmod a`$. If $`y_{0}`$ is a solution of the reduced congruence, then

$$x_0 = \frac{my_0 + b}{a}$$

is a solution for the original congruence. They apply the reduction until the congruence is solvable "by inspection". This we do not do. They also have some tricks for size reduction (on p. 43) we will not apply (due to laziness). Our "by inspection" termination condition will be to perform the reduction until $`a \bmod m = 1`$ or $`b = 0`$. Then we return $`b \bmod a`$, in a recursive setting which builds up the original $`x_{1}`$.

<div class="math-left">

```math
\begin{aligned}
&CRA1(aa, bb, m) \Leftarrow \\
&\quad \textbf{local } a,\ b,\ g \\
&\quad g \mathrel{:=} GCD(aa, m) \\
&\quad \textbf{if } not\ |(g, bb) \textbf{ then } pr\{\text{"ERROR: no solution to linear congruence"}\} \\
&\quad \textbf{else } \{ a \mathrel{:=} mod(aa, m);\ b \mathrel{:=} mod(bb, m) \\
&\quad\quad \textbf{if } =(a, 1(a)) \textbf{ then } \Uparrow b \\
&\quad\quad \textbf{else if } =(b, 0(b)) \textbf{ then } \Uparrow 0(b) \\
&\quad\quad \textbf{else if } =(a, b) \textbf{ then } \Uparrow 1(b) \\
&\quad\quad \textbf{else } \Uparrow \mathbin{⨸}(\oplus(\otimes(m, CRA1(m, -(b), a)), b), a) \} \ \blacksquare
\end{aligned}
```


</div>



**Example.** The following results were obtained from executing CRA (the examples are from Niven and Zuckerman [Niven80a], Sect. 2.3):

- CRA(7, 1432, 5317): $`x`$ such that $`7x \equiv 1432 \bmod 5317`$ is 4762.
- CRA(863, 880, 2151): $`x`$ such that $`863x \equiv 880 \bmod 2151`$ is 173.
- CRA(589, 509, 817): There is no $`x`$ such that $`589x \equiv 509 \bmod 817`$.

CRA2 and CRA are from Lipson, p. 254 and p. 257.

**CRA2**$`(r, m, s, n)`$: Two-congruence Chinese Remainder Algorithm for $`Z`$  
Input: $`r, m, s, n \in Z`$, where $`m`$, $`n`$ are relatively prime.  
Output: $`U \in Z`$ such that $`U \equiv r \pmod m`$ and $`U \equiv s \pmod n`$.

<div class="math-left">

```math
\begin{aligned}
&CRA2(r, m, s, n) \Leftarrow \\
&\quad \textbf{local } c,\ \sigma,\ U \\
&\quad c \mathrel{:=} INVERSE(m, n) \\
&\quad \sigma \mathrel{:=} mod(\otimes(\ominus(s, r), c), n) \\
&\quad U \mathrel{:=} \oplus(r, \otimes(\sigma, m)) \\
&\quad \Uparrow U \ \blacksquare
\end{aligned}
```


</div>

**Example.** The $`x`$ such that $`x \equiv 6 \pmod 7`$ and $`x \equiv 3 \pmod 9`$ is 48, as obtained by evaluating CRA2(6, 7, 3, 9).

**CRA**$`(rm\_list)`$: $`N`$-congruence Chinese Remainder Algorithm for $`Z`$  
Input: $`[[r_{k}, m_{k}]] \in Z`$, where the $`m_{k}`$ are relatively prime.  
Output: $`U \in Z`$ such that $`U \equiv r_{i} \pmod{m_i}`$.

<div class="math-left">

```math
\begin{aligned}
&CRA(rm\_list) \Leftarrow \\
&\quad \textbf{local } rms,\ rm,\ M,\ U,\ c,\ \sigma \\
&\quad rms \mathrel{:=} copy(rm\_list) \\
&\quad rm \mathrel{:=} pop(rms);\ r \mathrel{:=} rm[1];\ m \mathrel{:=} rm[2] \\
&\quad M \mathrel{:=} 1(m) \\
&\quad U \mathrel{:=} mod(r, m) \\
&\quad \textbf{every } k \mathrel{:=} 1 \textbf{ to } \texttt{*}rms \textbf{ do } \{ \\
&\quad\quad M \mathrel{:=} \otimes(M, m) \\
&\quad\quad rm \mathrel{:=} pop(rms);\ r \mathrel{:=} rm[1];\ m \mathrel{:=} rm[2] \\
&\quad\quad c \mathrel{:=} INVERSE(M, m) \\
&\quad\quad \sigma \mathrel{:=} mod(\otimes(\ominus(mod(U, m), r), c), m) \\
&\quad\quad U \mathrel{:=} \oplus(U, \otimes(\sigma, M)) \} \\
&\quad \Uparrow U \ \blacksquare
\end{aligned}
```


</div>

**Example.** The problem is to find $`u(x)`$ in $`Z[x]`$ such that

$`u(x) \bmod 3 = x`$,  
$`u(x) \bmod 7 = 1`$,  
$`u(x) \bmod 4 = 2x + 3`$, and  
$`u(x) \bmod 5 = 3x + 3`$.

Let $`u(x) = ax + b`$. Then

<div class="math-left">

```math
\begin{array}{ll}
a \bmod 3 = 1 & b \bmod 3 = 0 \\
a \bmod 7 = 0 & b \bmod 7 = 1 \\
a \bmod 4 = 2 & b \bmod 4 = 3 \\
a \bmod 5 = 3 & b \bmod 5 = 3
\end{array}
```


</div>

We can solve for $`a`$ and $`b`$ individually using the $`n`$-congruence CRA algorithm, and we are done. Executing the following code:

<div class="math-left">

```math
\begin{aligned}
&a\_congruences \mathrel{:=} [[1, 3], [0, 7], [2, 4], [3, 5]] \\
&b\_congruences \mathrel{:=} [[0, 3], [1, 7], [3, 4], [3, 5]] \\
&a \mathrel{:=} CRA(a\_congruences) \\
&b \mathrel{:=} CRA(b\_congruences) \\
&ux \mathrel{:=} poly([term(b, 0), term(a, 1)]) \\
&\text{pr}\{\text{"u(x) = "},\ ux\}
\end{aligned}
```


</div>

we discover (final term due to Yap) that

$$u(x) = 183 + 238 \cdot X + 3 \cdot 7 \cdot 4 \cdot 5 \sum_{i=0}^{\infty} t_i x^i.$$

**Example.** Another example, from Lipson, p. 258, is to compute $`u`$ such that

$`u \equiv 1 \pmod 3`$,  
$`u \equiv 3 \pmod 5`$,  
$`u \equiv 0 \pmod 7`$,  
$`u \equiv 10 \pmod{11}`$.

Executing the following code

<div class="math-left">

```math
\begin{aligned}
&\text{pr}\{CRA([[1, 3], [3, 5], [0, 7], [10, 11]])\}
\end{aligned}
```


</div>

yields a value of 868 for $`U`$.


#### 3.1.4. Linear Diophantine Equations in Two Variables

According to Niven, sect. 5.2, $`ax + by = c`$ is solvable iff $`g \mid c`$ where $`g = \gcd(a, b)`$. If $`g \mid c`$ then all solutions are of the form

$$x = x_1 + \frac{b}{g} t, \quad y = y_1 - \frac{a}{g} t$$

where $`t`$ is an arbitrary integer and $`x = x_{1}`$, $`y = y_{1}`$ is any particular solution of the equation. Particular solutions are obtained by solving one of the linear congruences

$$ax \equiv c \pmod{|b|} \quad \text{or} \quad by \equiv c \pmod{|a|}$$

for $`x_{1}`$ or $`y_{1}`$, then substituting $`y_{1}`$ or $`x_{1}`$ into $`ax + by = c`$ to obtain a particular $`y_{1}`$ or $`x_{1}`$. For computational convenience, if $`|b| \le |a|`$, we solve the first congruence, otherwise we solve the second.

**DIOPHANTINE**(a, b, c) solves linear Diophantine equations in 2 variables.  
Input: $`a, b, c`$ such that $`ax + by = c`$.  
Output: $`g`$, $`x_{1}`$, $`y_{1}`$, described above.

<div class="math-left">

```math
\begin{aligned}
&DIOPHANTINE(a, b, c) \Leftarrow \\
&\quad \textbf{local } gst,\ g,\ x_1,\ y_1 \\
&\quad gst \mathrel{:=} EUCLID(a, b) \\
&\quad g \mathrel{:=} gst[1];\ t \mathrel{:=} gst[3] \\
&\quad \textbf{if } not\ |(g, c) \textbf{ then } pr\{\text{"ERROR: Diophantine solution nonexistent"}\} \\
&\quad \textbf{else } \{ \textbf{if } <(abs(b), abs(a)) \\
&\quad\quad \textbf{then } \{ x_1 \mathrel{:=} CRA1(a, c, abs(b)) \\
&\quad\quad\quad y_1 \mathrel{:=} \mathbin{⨸}(\ominus(c, \otimes(a, x_1)), b) \} \\
&\quad\quad \textbf{else } \{ y_1 \mathrel{:=} CRA1(b, c, abs(a)) \\
&\quad\quad\quad x_1 \mathrel{:=} \mathbin{⨸}(\ominus(c, \otimes(b, y_1)), a) \} \\
&\quad\quad \Uparrow [g, x_1, y_1] \} \ \blacksquare
\end{aligned}
```


</div>

**Example.** By evaluating DIOPHANTINE(84, 54, -24), we find that all integer solutions $`(x, y)`$ of the equation $`84x + 54y = -24`$ are of the form $`x = 1 + 9t`$, $`y = (-2) - 14t`$.

**Example.** By evaluating DIOPHANTINE(999, -49, 5000), we find that all integer solutions $`(x, y)`$ of the equation $`999x + (-49)y = 5000`$ are of the form $`x = 13 + 49t`$, $`y = 163 - (-999)t`$.

**Example.** By evaluating DIOPHANTINE(247, 589, 817), we find that all integer solutions $`(x, y)`$ of the equation $`247x + 589y = 817`$ are of the form $`x = (-11) + 31t`$, $`y = 6 - 13t`$.


### 3.2 Polynomial remainder sequences 

Polynomial remainder sequences are studied as a method of finding variants of the greatest common divisor for elements of integral domains. Variation in the definition is required because integral domains do not support long division. It is also desirable to compute values which share properties of the greatest common divisor (which might then be reclaimed by homomorphic image methods; see Lipson, ch. 8), such that the computation does not suffer the large coefficient growth of Euclid's algorithm on even moderate-sized polynomials. Yap [Yap85a] discusses the issue, presenting an example of Knuth exhibiting the coefficient growth problem. Polynomial remainder sequences are discussed in greater depth in the paper by Loos [Loosa]. We have implemented three variants of polynomial remainder sequence:

- mod-based PRS.
- prem, a pseudo-remainder for division over integral domains, and a prem-based PRS, as defined in Yap [Yap85a].
- Subresultant PRS, as defined in Yap [Yap85a] and based on an algorithm of Collins, as presented by Brown.

#### 3.2.1 MOD-based PRS

The simplest polynomial remainder sequence is simply that of Euclid's algorithm. That is, we define MOD_RS(a, b) to be the PRS of mod(a, b).

<div class="math-left">

```math
\begin{aligned}
&MOD\_RS(a, b) \Leftarrow \Uparrow [a] \mathrel{\texttt{|||}}\mathrel{:=} \ (\textbf{if } =(b, 0(b)) \textbf{ then } [b] \textbf{ else } MOD\_RS(b, mod(a, b))) \ \blacksquare
\end{aligned}
```


</div>

**Example.** In $`QZ[x]`$, the remainder sequence of

$`a(x) = x^5 + 2x^4 + 3x^2 - x + 2`$  
$`b(x) = 3x^3 - x + 2`$

as encoded in ICON by

<div class="math-left">

```math
\begin{aligned}
&settime() \\
&ax \mathrel{:=} poly([k_{Z_{Qx}}(2, 0), k_{Z_{Qx}}(-1, 1), k_{Z_{Qx}}(3, 2), k_{Z_{Qx}}(2, 4), k_{Z_{Qx}}(1, 5)]) \\
&bx \mathrel{:=} poly([k_{Z_{Qx}}(2, 0), k_{Z_{Qx}}(-1, 1), k_{Z_{Qx}}(3, 3)]) \\
&\text{pr}\{\text{"QZ[x]: MOD\_RS("},\ ax,\ \text{", "},\ bx,\ \text{") = "},\ MOD\_RS(ax, bx)\} \\
&showtime() \\
\end{aligned}
```


</div>

is

$`QZ[x]\text{: MOD\_RS}(2zq + (-1z)q \cdot X + 3zq \cdot X^2 + 2zq \cdot X^4 + 1zq \cdot X^5,\ 2zq + (-1z)q \cdot X + 3zq \cdot X^3)`$  
$`= [2zq + (-1z)q \cdot X + 3zq \cdot X^2 + 2zq \cdot X^4 + 1zq \cdot X^5,\ 2zq + (-1z)q \cdot X + 3zq \cdot X^3,\ (16z/9z)q + ((-20z)/9z)q \cdot X + 3zq \cdot X^2,\ (166z/243z)q + ((-275z)/243z)q \cdot X,\ (115668z/75625z)q,\ 0zq]`$

[221033 msecs]

#### 3.2.2 Pseudo-remainder for division over integral domains

PREM(px, qx): Pseudo-remainder of $`px/qx`$ in $`I[x]`$, where $`I[x]`$ is an integral domain.

**Method:**

1. Let $`d = \deg(p) - \deg(q)`$
2. Let $`b`$ = lead coefficient of $`q(x)`$
3. Return $`\text{rem}(b^{d+1} \cdot px, qx)`$

<div class="math-left">

```math
\begin{aligned}
&PREM(px, qx) \Leftarrow \\
&\quad \textbf{local } d,\ b \\
&\quad d \mathrel{:=} -_{deg}(deg_{poly}(px), deg_{poly}(qx)) \\
&\quad b \mathrel{:=} poly\_of(lead\_coef(qx)) \\
&\quad \Uparrow rem(\otimes_{poly}(exp(b, d + 1), px), qx) \ \blacksquare
\end{aligned}
```


</div>

**Example.** The following table lists values and their pseudo-remainders. 


Algorithm! for Tarions problems over Enclidean domains Domain prem(p, q) QZlx] 2DO5427Uz+1785a34z*X StSX2Simi6tST3l82S2MOz -S8S12S9Z798467382S246000000000000Z QZlx] 21z+(.9z)*X+(.4i)’r2+5z*X‘4+3z*X‘6 (-39S35z)+3Q375zTC+15795z*X:2 QZlxl 22q+(-lz)q’X+3zq*X^+22q’X’4+lxq*X‘6 2xq+(-li)q*X+3zq*y3 198zq+(-225z)q*X+306zq’X^ QZlx] 198zq+(-2252)q*X+306zq*X3 iauj+369zq*X iniegen[x] 

#### 3.2.3 PREM-based PRS

E_PRS(a, b): Euclidean polynomial remainder sequence.  
I.e., a trace of the steps of Euclid's algorithm modified to use PREM.

<div class="math-left">

```math
\begin{aligned}
&E\_PRS(a, b) \Leftarrow \Uparrow [a] \mathrel{\texttt{|||}}\mathrel{:=} \ (\textbf{if } =(b, 0(b)) \textbf{ then } [b] \textbf{ else } E\_PRS(b, PREM(a, b))) \ \blacksquare
\end{aligned}
```


</div>

#### 3.2.4 Subresultant PRS

The following algorithm is the Collins-Brown subresultant PRS algorithm, as presented in Yap [Yap85a].

**S_PRS**: Subresultant polynomial remainder sequence.  
Input: polynomials $`p_{0}, p_{1} \in I[x]`$ for some integral domain $`I`$.  
Output: Subresultant PRS $`(p_{0}, p_{1}, \ldots, p_{k})`$ such that $`p_{k+1} = 0`$.

Let $`\delta_{i} = \deg(p_{i}) - \deg(p_{i+1})`$. Let $`c_{i} = \text{lead}(p_{i})`$.

Let $`(R_{1}, R_{2}, \ldots, R_{k})`$ be a sequence of length $`k`$ defined by

$$R_1 = c_1^{\delta_0}$$
$$R_i = c_i^{\delta_{i-1}} R_{i-1}^{1-\delta_{i-1}}, \quad i = 2, \ldots, k$$

Let $`(\beta_{2}, \beta_{3}, \ldots, \beta_{k})`$ be a sequence of length $`k-1`$ defined by

$$\beta_2 = (-1)^{\delta_0 + 1}$$
$$\beta_i = (-1)^{1 + \delta_{i-2}} c_{i-2} (R_{i-2})^{\delta_{i-2}}, \quad i = 3, \ldots, k$$

Then we wish to compute the sequence $`(p_{0}, p_{1}, \ldots, p_{k})`$ of length $`k+1`$ such that $`p_{0}`$ and $`p_{1}`$ are the given polynomials, and

$$p_i = \frac{\text{PREM}(p_{i-2}, p_{i-1})}{\beta_i}, \quad i = 2, \ldots, k$$



<div class="math-left">

```math
\begin{aligned}
&S\_PRS(p_0, p_1) \Leftarrow \\
&\quad \textbf{local } \delta_0,\ \beta_2,\ p_2,\ x,\ P,\ R_1, \\
&\quad\quad \delta_{i-2},\ c_{i-2},\ R_{i-2},\ p_{i-2},\ p_{i-1},\ \beta_i,\ p_i,\ l,\ z \\
&\quad \delta_0 \mathrel{:=} \delta_i(p_0, p_1) \\
&\quad c_0 \mathrel{:=} c_i(p_0) \\
&\quad \beta_2 \mathrel{:=} poly\_of(exp(-(1(c_0)), \delta_0 + 1)) \\
&\quad p_2 \mathrel{:=} P_i(p_0, p_1, \beta_2);\ z \mathrel{:=} 0(p_2) \\
&\quad \textbf{if } =(p_2, z) \textbf{ then } \Uparrow [p_0, p_1] \\
&\quad P \mathrel{:=} [p_0, p_1, p_2] \\
&\quad R_1 \mathrel{:=} exp(c_i(p_1), \delta_0) \\
&\quad \delta_{i-2} \mathrel{:=} \delta_i(p_1, p_2) \\
&\quad c_{i-2} \mathrel{:=} c_i(p_1) \\
&\quad R_{i-2} \mathrel{:=} R_1 \\
&\quad p_{i-2} \mathrel{:=} p_1 \\
&\quad p_{i-1} \mathrel{:=} p_2 \\
&\quad l \mathrel{:=} 3 \\
&\quad \textbf{repeat } \{ \\
&\quad\quad \beta_i \mathrel{:=} \beta_i(\delta_{i-2}, c_{i-2}, R_{i-2}) \\
&\quad\quad p_i \mathrel{:=} P_i(p_{i-2}, p_{i-1}, \beta_i) \\
&\quad\quad \textbf{if } =(p_i, z) \textbf{ then } \Uparrow P \\
&\quad\quad \textbf{else } P \mathrel{\texttt{|||}}\mathrel{:=} \ [p_i] \\
&\quad\quad p_{i-2} \mathrel{:=} p_{i-1} \\
&\quad\quad p_{i-1} \mathrel{:=} p_i \\
&\quad\quad c_{i-2} \mathrel{:=} c_i(p_{i-2}) \\
&\quad\quad R_{i-2} \mathrel{:=} R_i(c_{i-2}, \delta_{i-2}, R_{i-2}) \\
&\quad\quad \delta_{i-2} \mathrel{:=} \delta_i(p_{i-2}, p_{i-1}) \} \ \blacksquare \\
&\\
&\delta_i(p_i, p_{i+1}) \Leftarrow \Uparrow -_{deg}(deg_{poly}(p_i), deg_{poly}(p_{i+1})) \ \blacksquare \\
&\\
&c_i(p_i) \Leftarrow \Uparrow lead\_coef(p_i) \ \blacksquare \\
&\\
&R_i(c_i, \delta_{i-1}, R_{i-1}) \Leftarrow \\
&\quad \Uparrow \otimes(exp(c_i, \delta_{i-1}), exp(R_{i-1}, -_{deg}(\delta_{i-1}, 1))) \ \blacksquare \\
&\\
&\beta_i(\delta_{i-2}, c_{i-2}, R_{i-2}) \Leftarrow \\
&\quad \Uparrow poly\_of(\otimes(\otimes(exp(-(1(c_{i-2})), 1 + \delta_{i-2}), exp(R_{i-2}, \delta_{i-2})))) \ \blacksquare \\
&\\
&P_i(p_{i-2}, p_{i-1}, \beta_i) \Leftarrow \Uparrow \mathbin{⨸}(PREM(p_{i-2}, p_{i-1}), \beta_i) \ \blacksquare
\end{aligned}
```


</div>

## 3.3 Power series and polynomial inversion and interpolation

Under this heading we provide the following facilities:

- Newton's method for construction of polynomials by interpolation.
- Fast Fourier Transform (FFT) and Interpolation (FFI).
- Newton's method for truncated power series inversion.

#### 3.3.1 Newton's method for construction of polynomials by interpolation

**NIA**(ab_list): Newton's Interpolation Algorithm (CRA for $`F[x]`$)  
Input: $`[[a_{k}, b_{k}]]`$ such that $`U(a_{k}) = b_{k}`$, $`U(x) \in F[x]`$  
Output: $`U(x)`$

<div class="math-left">

```math
\begin{aligned}
&NIA(ab\_list) \Leftarrow \\
&\quad \textbf{local } ab\_s,\ ab,\ a,\ b,\ Ux,\ Mx,\ c,\ \sigma \\
&\quad ab\_s \mathrel{:=} copy(ab\_list) \\
&\quad ab \mathrel{:=} pop(ab\_s);\ a \mathrel{:=} ab[1];\ b \mathrel{:=} ab[2] \\
&\quad Ux \mathrel{:=} poly\_of(b) \\
&\quad Mx \mathrel{:=} 1(Ux) \\
&\quad \textbf{every } k \mathrel{:=} 1 \textbf{ to } \texttt{*}ab\_s \textbf{ do } \{ \\
&\quad\quad Mx \mathrel{:=} \otimes(Mx, \ominus(poly([term(1(b), 1)]), poly\_of(a))) \\
&\quad\quad ab \mathrel{:=} pop(ab\_s);\ a \mathrel{:=} ab[1];\ b \mathrel{:=} ab[2] \\
&\quad\quad c \mathrel{:=} \mathbin{⨸}(1(a), eval_{poly}(Mx, a)) \\
&\quad\quad \sigma \mathrel{:=} \mathbin{⨸}(\ominus(poly\_of(b), poly\_of(eval_{poly}(Ux, a))), poly\_of(c)) \\
&\quad\quad Ux \mathrel{:=} \oplus(Ux, \otimes(\sigma, Mx)) \} \\
&\quad \Uparrow Ux \ \blacksquare
\end{aligned}
```


</div>

### 3.3.2 Fast Fourier Transform (FFT) and Interpolation (FFI)

**FFT**$`(N, a(x), \omega, A)`$: Fast Fourier Transform  
Input: integer $`N = 2^m`$, polynomial $`a(x) = \mathrm{sum}(i=0, N-1, a_{i} \cdot x^i)`$, primitive $`N`$th root of unity $`\omega`$  
Output: array $`A = (A_{0}, \ldots, A_{N-1})`$ where $`A_{k} = a(\omega^k)`$

<div class="math-left">

```math
\begin{aligned}
&FFT(N, ax, \omega) \Leftarrow \\
&\quad \textbf{local } A,\ n,\ bx,\ cx,\ \omega^2,\ B,\ C,\ \omega^k \\
&\quad A \mathrel{:=} list(N, []) \\
&\quad \textbf{if } N = 1 \ \texttt{*} \text{basis} \\
&\quad \textbf{then } A[1] \mathrel{:=} 0th_{coef}(ax) \\
&\quad \textbf{else } \{ n \mathrel{:=} N/2 \ \texttt{*} \text{binary split} \\
&\quad\quad bx \mathrel{:=} poly\_of\_even\_powered\_terms(ax) \\
&\quad\quad cx \mathrel{:=} poly\_of\_odd\_powered\_terms(ax) \\
&\quad\quad \omega^2 \mathrel{:=} exp(\omega, 2) \\
&\quad\quad B \mathrel{:=} FFT(n, bx, \omega^2) \ \texttt{*} \text{recursive calls} \\
&\quad\quad C \mathrel{:=} FFT(n, cx, \omega^2) \\
&\quad\quad \textbf{every } k \mathrel{:=} 1 \textbf{ to } n \textbf{ do } \{ \\
&\quad\quad\quad \omega^k \mathrel{:=} exp(\omega, k-1) \\
&\quad\quad\quad A[k] \mathrel{:=} \oplus(B[k], \otimes(\omega^k, C[k])) \\
&\quad\quad\quad A[k+n] \mathrel{:=} \ominus(B[k], \otimes(\omega^k, C[k])) \} \} \\
&\quad \Uparrow A \ \blacksquare
\end{aligned}
```


</div>

Even powered terms.

<div class="math-left">

```math
\begin{aligned}
&poly\_of\_even\_powered\_terms(ax) \Leftarrow \\
&\quad \textbf{local } r \\
&\quad r \mathrel{:=} [] \\
&\quad \textbf{every } t \mathrel{:=} \texttt{!}ax.terms \\
&\quad \textbf{do if } mod_{integer}(t.power, 2) = 0 \textbf{ then } r \mathrel{\texttt{|||}}\mathrel{:=} \ [term(t.coef, t.power/2)] \\
&\quad \Uparrow poly(r) \ \blacksquare
\end{aligned}
```


</div>

Odd powered terms.

<div class="math-left">

```math
\begin{aligned}
&poly\_of\_odd\_powered\_terms(ax) \Leftarrow \\
&\quad \textbf{local } r \\
&\quad r \mathrel{:=} [] \\
&\quad \textbf{every } t \mathrel{:=} \texttt{!}ax.terms \\
&\quad \textbf{do if } mod_{integer}(t.power, 2) = 1 \textbf{ then } r \mathrel{\texttt{|||}}\mathrel{:=} \ [term(t.coef, (t.power - 1)/2)] \\
&\quad \textbf{if } \texttt{*}r > 0 \textbf{ then } \Uparrow poly(r) \textbf{ else } \Uparrow 0(ax.terms[1]) \ \blacksquare
\end{aligned}
```


</div>

**FFI**$`(N, B, \omega)`$: Fast Fourier Interpolation  
Input: integer $`N = 2^m`$, sample values $`B = (b_{0}, \ldots, b_{N-1})`$, primitive $`N`$th root of unity $`\omega`$  
Output: $`a(x) = \mathrm{sum}(i=0, N-1, a_{i} x^i)`$ where $`a(\omega^k) = b_{k}`$, $`k=0..N-1`$

<div class="math-left">

```math
\begin{aligned}
&FFI(N, B, \omega) \Leftarrow \\
&\quad \textbf{local } bx,\ C,\ ax \\
&\quad bx \mathrel{:=} polynomialize(B) \\
&\quad C \mathrel{:=} FFT(N, bx, \mathbin{⨸}(1(\omega), \omega)) \\
&\quad ax \mathrel{:=} polynomialize(\otimes_{vector\ scalar}(C, \mathbin{⨸}(1(N), N))) \\
&\quad \Uparrow ax \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&polynomialize(B) \Leftarrow \\
&\quad \textbf{local } r,\ i \\
&\quad r \mathrel{:=} [];\ i \mathrel{:=} 0 \\
&\quad \textbf{every } b \mathrel{:=} \texttt{!}B \textbf{ do } \{ \\
&\quad\quad \textbf{if } not(=(b, 0(b))) \textbf{ then } r \mathrel{\texttt{|||}}\mathrel{:=} \ [term(b, i)] \\
&\quad\quad i \mathrel{+{:=}} 1 \} \\
&\quad \Uparrow poly(r) \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&\otimes_{vector\ scalar}(V, x) \Leftarrow \\
&\quad \textbf{local } R,\ i \\
&\quad R \mathrel{:=} list(\texttt{*}V);\ i \mathrel{:=} 1 \\
&\quad \textbf{every } v \mathrel{:=} \texttt{!}V \textbf{ do } \{ R[i] \mathrel{:=} \otimes(V[i], x);\ i \mathrel{+{:=}} 1 \} \\
&\quad \Uparrow R \ \blacksquare
\end{aligned}
```


</div>

#### 3.3.3 Newton’s method for truncated power series inversion

**NPSI**(): Newton's Power Series Inversion Method  
Input: $`a(t) \bmod t^{2^n} = \mathrm{sum}(i=0, 2^n-1, a_{i} t^i)`$, $`a_{0} \neq 0`$  
Output: $`x^{(n)}(t) = a(t)^{-1} \bmod t^{2^n}`$

<div class="math-left">

```math
\begin{aligned}
&NPSI(at) \Leftarrow \\
&\quad \textbf{local } ax,\ xt,\ n \\
&\quad ax \mathrel{:=} at.Poly \\
&\quad xt \mathrel{:=} poly\_of(0th_{coef}(ax)) \\
&\quad n \mathrel{:=} log2(\texttt{*}ax.terms) \\
&\quad \textbf{every } k \mathrel{:=} 0 \textbf{ to } n-1 \\
&\quad \textbf{do } xt \mathrel{:=} \oplus(\oplus(xt, xt), \\
&\quad\quad\quad\quad -(\otimes_{poly}(truncate(ax, 2^{k+1}), \otimes(xt, xt)))) \\
&\quad \Uparrow tpower(truncate(xt, at.N), at.N) \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&log2(x) \Leftarrow \\
&\quad \textbf{local } l \\
&\quad l \mathrel{:=} 0 \\
&\quad \textbf{while } x > 1 \textbf{ do } \{ x \mathrel{:=} x/2;\ l \mathrel{:=} l + 1 \} \\
&\quad \Uparrow l \ \blacksquare
\end{aligned}
```


</div>

### 3.4 A simple timer

A call to `settime()` initializes the timer.

A call to `showtime()` prints the elapsed time since `settime()` was invoked.

<div class="math-left">

```math
\begin{aligned}
&\textbf{global } timer \\
&showtime() \Leftarrow pr\{\text{"["}, \&time - timer, \text{" msecs]"}\} \ \blacksquare \\
&settime() \Leftarrow timer \mathrel{:=} \&time \ \blacksquare
\end{aligned}
```


</div>

## Appendix. ICON Pretty Printer and Documentation Delaminator

The following documentation filter is inspired by Knuth's *TeX* (specifically the *LaTeX* variant [Lampo83a, Knuth82a].

Blocks of comments are compiled as paragraphs. Paragraphs are demarcated by blank comment lines. Paragraphs are typeset with `.lp`. Code is set off with `.nf`, and `.fi`. We strip any leading white space from comment lines before further processing.

<div class="math-left">

```math
\begin{aligned}
&\textbf{global } command\_line,\ last\_line,\ cur\_files,\ read\_now,\ words \\
&\\
&main(x) \Leftarrow \\
&\quad \textbf{local } fn \\
&\quad words \mathrel{:=} table("") \\
&\quad words[\text{"↑"}] \mathrel{:=} \text{"↑"} \\
&\quad words[\text{"■"}] \mathrel{:=} \text{"■"} \\
&\quad words[\text{"±"}] \mathrel{:=} \text{"±"} \\
&\quad command\_line \mathrel{:=} x \\
&\quad \textbf{if } \texttt{*}command\_line > 0 \\
&\quad \textbf{then } \{ fn \mathrel{:=} command\_line[1] \\
&\quad\quad load\_user\_keywords(fn \ \mathrel{\texttt{||}} \ \text{".keys"}) \\
&\quad\quad cur\_files \mathrel{:=} [read\_now \mathrel{:=} open(fn \ \mathrel{\texttt{||}} \ \text{".icn"}, \text{"r"})] \} \\
&\quad \textbf{else } cur\_files \mathrel{:=} [read\_now \mathrel{:=} \&input] \\
&\quad last\_line \mathrel{:=} \&null \\
&\quad write(\text{".so /usr2/ericson/euclid/lpp/std.me"}) \\
&\quad process() \ \blacksquare \\
&\\
&get\_line() \Leftarrow \\
&\quad \textbf{local } x \\
&\quad x \mathrel{:=} \&null \\
&\quad \textbf{if } last\_line \textbf{ then } \{ x \mathrel{:=} last\_line;\ last\_line \mathrel{:=} \&null;\ \Uparrow x \} \\
&\quad \textbf{else if } x \mathrel{:=} read(read\_now) \textbf{ then } \Uparrow x \ \blacksquare
\end{aligned}
```


</div>

Reads lines until encountering end of file or `##end` or `##end command`.

<div class="math-left">

```math
\begin{aligned}
&process(command) \Leftarrow \\
&\quad \textbf{local } line \\
&\quad \textbf{while } line \mathrel{:=} get\_line() \textbf{ do if } not\ process\_line(line, command) \textbf{ then break} \ \blacksquare \\
&\\
&process\_line(line, command) \Leftarrow \\
&\quad \textbf{if } line[1:3] \mathrel{==} \texttt{"\#\#"} \\
&\quad \textbf{then } \{ \textbf{if } line[3:6] \mathrel{==} \text{"■"} \\
&\quad\quad \textbf{then } \{ end\_command(command, line[7:\texttt{*}line + 1]);\ \bot \} \\
&\quad\quad \textbf{else } do\_command(line[3:\texttt{*}line + 1]) \} \\
&\quad \textbf{else if } line[1] \mathrel{==} \texttt{"\#"} \textbf{ then } write\_line(line[2:\texttt{*}line + 1]) \\
&\quad \textbf{else } pretty\_print(line, command) \\
&\Uparrow \ \blacksquare \\
&\\
&end\_command(command, line) \Leftarrow \\
&\quad \textbf{if } command \mathrel{\sim}== line \textbf{ then } write(\&errout, \text{"ERROR: Mismatched END, wanted "}, command, \text{", got "}, line) \ \blacksquare
\end{aligned}
```


</div>

If command is non-null then `##■end` command should match command.

For interpreting `##` commands

<div class="math-left">

```math
\begin{aligned}
&do\_command(line) \Leftarrow \\
&\quad \textbf{local } command,\ args \\
&\quad x \mathrel{:=} (upto(\mathord{\sim}\&lcase, line) \ | \ (\texttt{*}line + 1)) \\
&\quad command \mathrel{:=} line[1:x] \\
&\quad args \mathrel{:=} line[x + 1:\texttt{*}line + 1] \\
&\quad \textbf{if } not(y \mathrel{:=} proc(\text{"do\_"} \ \mathrel{\texttt{||}} \ command, 2)) \\
&\quad \textbf{then } write(\&errout, \text{"ERROR: Unknown command: "}, command) \\
&\quad \textbf{else } y(args) \ \blacksquare
\end{aligned}
```


</div>

`##list` and `##end list`.

<div class="math-left">

```math
\begin{aligned}
&do\_list(args) \Leftarrow \\
&\quad \textbf{local } line \\
&\quad write(\text{".(l I F"}) \\
&\quad \textbf{while } line \mathrel{:=} get\_line() \\
&\quad \textbf{do if } line[1:3] \mathrel{==} \texttt{"\#\#"} \\
&\quad\quad \textbf{then } \{ \textbf{if } line[3:6] \mathrel{==} \text{"■"} \\
&\quad\quad\quad \textbf{then } \{ write(\text{".)l"});\ end\_command(command, line[7:\texttt{*}line + 1]);\ \bot \} \\
&\quad\quad\quad \textbf{else } do\_command(line[3:\texttt{*}line + 1]) \} \\
&\quad\quad \textbf{else if } line[1] \mathrel{==} \texttt{"\#"} \\
&\quad\quad \textbf{then } \{ line \mathrel{:=} line[2:\texttt{*}line + 1] \\
&\quad\quad\quad\quad \textbf{repeat if } upto(\text{' '}, line[1]) \\
&\quad\quad\quad\quad \textbf{then } line \mathrel{:=} line[2:\texttt{*}line + 1] \textbf{ else break} \\
&\quad\quad\quad\quad \textbf{if } \texttt{*}line > 0 \textbf{ then } write(\text{"● "}, line) \textbf{ else } write() \} \\
&\quad\quad \textbf{else } pretty\_print(line, command) \\
&\quad write(\text{".)l"}) \ \blacksquare
\end{aligned}
```


</div>

`##section <I> <title>` and `##end section <I>`.

Section nestings are relative to the file, from 1 on up. An `##include` file's nestings are relative to the current level of the including file plus previous cumulative nesting. I.e., if cumulative nesting is 3, and nesting in the including file is 2, then 1 in the included file translates to 6 in the final output.

<div class="math-left">

```math
\begin{aligned}
&do\_section(args) \Leftarrow \\
&\quad x \mathrel{:=} (upto(\mathord{\sim}(\text{'0123456789'}), args) \ | \ (\texttt{*}args + 1)) \\
&\quad level \mathrel{:=} args[1:x] + 0 \\
&\quad title \mathrel{:=} args[x + 1:\texttt{*}args + 1] \\
&\quad write(\text{".sh "}, level, \text{" "}, title) \\
&\quad write(\text{".sp 2v0lp"}) \\
&\quad process(\text{"section "} \ \mathrel{\texttt{||}} \ level) \ \blacksquare
\end{aligned}
```


</div>

`##skip` and `##end skip`.

Deletes *everything* between skip and end skip.

<div class="math-left">

```math
\begin{aligned}
&do\_skip(x) \Leftarrow \\
&\quad \textbf{local } line \\
&\quad \textbf{while } line \mathrel{:=} get\_line() \\
&\quad \textbf{do if } line[1:3] \mathrel{==} \texttt{"\#\#"} \\
&\quad\quad \textbf{then if } line[3:6] \mathrel{==} \text{"■"} \\
&\quad\quad\quad \textbf{then } \{ end\_command(command, line[7:\texttt{*}line + 1]);\ break \} \ \blacksquare
\end{aligned}
```


</div>

`##include <file>`.

Includes file. Home directory for includes within included file is home directory of file relative to current home directory. I.e., if you include foo/bar (`.icn` is assumed), and foo/bar includes dot/zot, then we look for foo/dot/zot. If `-I` switch is present, don't bother doing includes.

<div class="math-left">

```math
\begin{aligned}
&do\_include(arg) \Leftarrow \\
&\quad \textbf{local } new\_file \\
&\quad cur\_file \mathrel{:=} arg \\
&\quad new\_file \mathrel{:=} open(cur\_file \ \mathrel{\texttt{||}} \ \text{".icn"}, \text{"r"}) \\
&\quad \textbf{if } /new\_file \textbf{ then } write(\text{"ERROR: couldn't open "}, cur\_file, \text{".icn"}) \\
&\quad \textbf{else } \{ read\_now \mathrel{:=} new\_file \\
&\quad\quad push(cur\_files, read\_now) \\
&\quad\quad load\_user\_keywords(cur\_file \ \mathrel{\texttt{||}} \ \text{".keys"}) \\
&\quad\quad process(\text{"include"}) \ \texttt{*} \text{ until ■ of file} \\
&\quad\quad close(pop(cur\_files)) \\
&\quad\quad read\_now \mathrel{:=} cur\_files[1] \} \ \blacksquare
\end{aligned}
```


</div>

`##example` and `##end example`.
Example paragraphs are left-justified and preceded by an appropriately numbered boldfaced "Example" keyword.

<div class="math-left">

```math
\begin{aligned}
&do\_example(arg) \Leftarrow \\
&\quad writes(\text{"\textbackslash fB Example.\textbackslash fR "}) \\
&\quad process(\text{"example"}) \ \blacksquare
\end{aligned}
```


</div>

`##code` and `##end code`.

Code is unjustified and Helveticized. Uncommented lines are processed as code. Commented lines bracketed by `##code` are treated similarly; the purpose is to present code examples in the file that are not to be seen by the ICON compiler.

<div class="math-left">

```math
\begin{aligned}
&do\_code(arg) \Leftarrow \\
&\quad \textbf{local } line \\
&\quad write(\text{".nf0fH"}) \\
&\quad \textbf{while } line \mathrel{:=} get\_line() \\
&\quad \textbf{do if } line[1:6] \mathrel{==} \texttt{"\#\#■"} \textbf{ then break} \\
&\quad\quad \textbf{else } pretty\_print\_line(line[2:\texttt{*}line + 1]) \\
&\quad write(\text{".fi0fR"}) \ \blacksquare
\end{aligned}
```


</div>

`##equations` and `##end equations`.

Typeset with TBL, one `.EQ` and `.EN.` per line, except that if the line is terminated by `\,`, continue equation on the next line.

<div class="math-left">

```math
\begin{aligned}
&do\_equations(arg) \Leftarrow \\
&\quad write(\text{".EQ"}) \\
&\quad process(\text{"equations"}) \\
&\quad write(\text{".EN"}) \ \blacksquare
\end{aligned}
```


</div>

`##quote` and `##end quote`.

These are typeset with `.(q` and `.)q`.

<div class="math-left">

```math
\begin{aligned}
&do\_quote(arg) \Leftarrow \\
&\quad write(\text{".(q"}) \\
&\quad process(\text{"quote"}) \\
&\quad write(\text{".)q"}) \ \blacksquare
\end{aligned}
```


</div>

`##table` and `##end table`.

Outputs `.TS` and `.TE` commands. Body is straight TBL.

<div class="math-left">

```math
\begin{aligned}
&do\_table(args) \Leftarrow \\
&\quad write(\text{".sp 4v0(c0TS"}) \\
&\quad process(\text{"table"}) \\
&\quad write(\text{".TE0)c0"}) \ \blacksquare
\end{aligned}
```


</div>

For printing documentation lines. If the text following the `#` is white space, output a `.lp`

<div class="math-left">

```math
\begin{aligned}
&write\_line(line) \Leftarrow \\
&\quad \textbf{repeat if } upto(\text{' '}, line[1]) \textbf{ then } line \mathrel{:=} line[2:\texttt{*}line + 1] \textbf{ else break} \\
&\quad \textbf{if } \texttt{*}line = 0 \textbf{ then } write(\text{".lp"}) \textbf{ else } write(line) \ \blacksquare
\end{aligned}
```


</div>

For printing list lines.

<div class="math-left">

```math
\begin{aligned}
&plain\_write\_line(line) \Leftarrow \\
&\quad \textbf{repeat if } upto(\text{' '}, line[1]) \textbf{ then } line \mathrel{:=} line[2:\texttt{*}line + 1] \textbf{ else break} \\
&\quad write(line) \ \blacksquare
\end{aligned}
```


</div>

`pretty_print(line)`: For printing code. Output a `.nf`. Pretty print lines until end-of-file or comment. Output a `.fi`. Write-line, the comment if there was one.

<div class="math-left">

```math
\begin{aligned}
&pretty\_print(l, command) \Leftarrow \\
&\quad \textbf{local } line \\
&\quad write(\text{".nf0fH "}) \\
&\quad pretty\_print\_line(l) \\
&\quad \textbf{while } line \mathrel{:=} get\_line() \\
&\quad \textbf{do if } line[1:2] \mathrel{==} \texttt{"\#"} \\
&\quad\quad \textbf{then } \{ write(\text{".fi0fR "}) \\
&\quad\quad\quad\quad write(\text{".lp"});\ last\_line \mathrel{:=} line;\ \bot \} \\
&\quad\quad \textbf{else } pretty\_print\_line(line) \\
&\quad write(\text{".fi0fR "}) \ \blacksquare
\end{aligned}
```


</div>

Pretty-print does special formatting in the following cases: 

* Procedure definitions 
* Control structures 
* Reserved words 
* User keywords

If the `-U<filename>` option is present, then keywords are read into the words table, with troff equivalents.

<div class="math-left">

```math
\begin{aligned}
&pretty\_print\_line(line) \Leftarrow \\
&\quad \textbf{local } first,\ last,\ key,\ x,\ y \\
&\quad \{ x \mathrel{:=} (upto((\&lcase \mathrel{+{+}} \&ucase \mathrel{+{+}} \text{'\_0123456789'}), line) \ | \ (\texttt{*}line + 1)) \\
&\quad\quad \textbf{if } x = \texttt{*}line + 1 \textbf{ then } \{ writes(line);\ break \} \\
&\quad\quad y \mathrel{:=} (upto(\mathord{\sim}(\&lcase \mathrel{+{+}} \&ucase \mathrel{+{+}} \text{'\_0123456789'}), line) \ | \ (\texttt{*}line + 1)) \\
&\quad\quad key \mathrel{:=} (line[1:y] \ | \ \text{""}) \\
&\quad\quad first \mathrel{:=} (line[1:x] \ | \ \text{""}) \\
&\quad\quad line \mathrel{:=} (line[x:\texttt{*}line + 1] \ | \ \text{""}) \\
&\quad\quad \textbf{while } \texttt{*}line > 0 \textbf{ do } \{ \\
&\quad\quad\quad \textbf{if } words[key] \mathrel{\sim}= \text{""} \textbf{ then } key \mathrel{:=} words[key] \\
&\quad\quad\quad last \mathrel{:=} line[y:\texttt{*}line + 1] \\
&\quad\quad\quad writes(first, key) \\
&\quad\quad\quad line \mathrel{:=} last \} \\
&\quad\quad write() \} \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&load\_user\_keywords(fname) \Leftarrow \\
&\quad \textbf{local } w,\ a,\ x \\
&\quad \textbf{if } not(w \mathrel{:=} open(fname, \text{'r'})) \textbf{ then } \bot \\
&\quad \textbf{while } x \mathrel{:=} read(w) \\
&\quad \textbf{do } \{ a \mathrel{:=} upto(\text{':'}, x) \\
&\quad\quad words[x[1:a]] \mathrel{:=} x[a + 1:\texttt{*}x + 1] \} \\
&\quad close(w) \\
&\quad \Uparrow \ \blacksquare
\end{aligned}
```


</div>

Procedure definitions. Instead of the obvious

```
procedure F (a, b, c)
code
end
```

we use the logical-looking

<div class="math-left">

```math
\begin{aligned}
&F (a, b, c) \Leftarrow code \ \blacksquare
\end{aligned}
```


</div>

<div class="math-left">

```math
\begin{aligned}
&\textbf{if } z \mathrel{==} \text{"■"} \textbf{ then } pretty\_print\_line(line \ \mathrel{\texttt{||}} \ y \ \mathrel{\texttt{||}} \ \text{" ■"}) \\
&\textbf{else } \{ pretty\_print\_line(line) \\
&\quad\quad \textbf{if } y \mathrel{==} \text{"■"} \textbf{ then } pretty\_print\_line(line \ \mathrel{\texttt{||}} \ \text{" ⊥ ■"}) \\
&\quad\quad \textbf{else } \{ z \mathrel{:=} get\_line() \\
&\quad\quad\quad\quad \textbf{local } y \\
&\quad\quad\quad\quad y \mathrel{:=} get\_line() \\
&\quad\quad\quad\quad pretty\_print\_line(y);\ pretty\_print\_line(z) \} \}
\end{aligned}
```


</div>

**Control Structures: return, fail and every.**

Instead of `return x` we use *uparrow* $`x`$, and for return we use ↑. Instead of `fail` we use ⊥.

For `every i := 1 to j do C` we use `every i in 1, 2..j do C`

`every i := j to 1 by -1 do C` and `every x := !Y do C` we use `every i in j, j-1 .. 1 do C` and `every x in Y do C`


## References

**Balza84a.** Stepehn R. Balzac, James H. Davenport, Patrizia Gianni, Richard D. Jenks, Victor S. Miller, Scott C. Morrison, Michael Rothstein, Christine J. Sundaresan, Robert S. Sutor, and Barry M. Trager, *Scratchpad II: An experimental computer algebra system*, Mathematical Sciences Department, IBM Thomas J. Watson Research Center, Yorktown Heights, NY 10598, May, 1984.

**Dewar81a.** Robert B.K. Dewar, Ed Schonberg, and Jacob T. Schwartz, *Higher level programming: Introduction to the use of the set-theoretic programming language SETL*, Courant Institute, N.Y.U., Summer, 1981.

**Grisw83a.** Ralph E. Griswold, "An overview of the Icon programming language (revised, September, 1985)," TR 83-3a, Dept. of Computer Science, University of Arizona, May, 1983.

**Grisw83b.** Ralph E. Griswold and Madge T. Griswold, *The Icon Programming Language*, Prentice-Hall, Inc., Englewood Cliffs, New Jersey, 1983.

**Grisw85a.** Ralph E. Griswold and William H. Mitchell, *Version 5.10 of Icon*, TR 85-15, Dept. of Computer Science, University of Arizona, August, 1985.

**Ingal78a.** D.H.H. Ingalls, "The SMALLTALK-76 programming system design and implementation," in *Fifth Annual ACM Symposium on Principles of Programming Languages*, pp. 9–16, 1978.

**Knuth73a.** Knuth, *The art of computer programming*, 1973.

**Knuth82a.** Knuth, Donald, "Web documentation system," *UNIX TeX Distribution Tape*, U. of Washington, 1982.

**Kruch83a.** Philippe Kruchten and Edmond Schonberg, *The Ada/Ed system: a large-scale experiment in software prototyping using SETL*, Computer Science Department, Courant Institute, New York University, 251 Mercer St., NY, NY, 10012, 1983.

**Lampo83a.** Lamport, Leslie, *The LaTeX Document Preparation System*, 1983.

**Lipso81a.** John D. Lipson, *Elements of Algebra and Algebraic Computing*, Benjamin/Cummings, 1981.

**Loosa.** Loos, Polynomial remainder sequences. *Computer Algebra* (ed. Buchberger).

**NYU 84a.** NYU Ada Project, *AdaSem: Static Semantics for Ada*, Ada Project, Courant Institute, New York University, 251 Mercer St., New York, NY, 10012, June, 1984.

**Niven80a.** Ivan Niven and H.S. Zuckerman, *An introduction to the theory of numbers*, 4th ed., John Wiley & Sons, 1980.

**Yap85a.** Yap, Chee, Polynomial remainder sequences and theory of subresultants. Unpublished lecture notes, NYU Courant Institute, Fall, 1985.

**Yap86a.** Chee Yap, Root Isolation, Unpublished lecture notes, N.Y.U., 1986.

**Zippe86a.** Richard E. Zippel, Algebraic Manipulation, Unpublished lecture notes, M.I.T., 1986.
