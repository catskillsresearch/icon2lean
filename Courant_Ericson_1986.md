# An ICON Package for Experimenting with Euclidean Domains

**Author:** Lars Warren Ericson  
**Institution:** Courant Institute of Mathematical Sciences, New York University  
**Report:** NYU Computer Science Technical Report #232  
**Date:** August 1986

> Transcription of the 1986 technical report from PDF. Icon listings use the report's *fancy notation* (see Section 1.3): e.g. `©` for division, `®` for addition, `F (a,b) <= code ■` for procedure definitions, and `))` for `return`. Some OCR artifacts from the scanned source may remain.

## Abstract

For the purpose of understanding the algebraic algorithms over the Euclidean domain presented in the book of Lipson- [LipsoSla], a small package of routines (about 2000 lines of code) was written in ICON, a software prototyping language developed at the U. of Arizona [Grisw83a,Grisw83b]. This package allows the ICON user to write algorithms which apply to any object of a Euclidean domain, and supplies a paradigm for implementing new Euclidean domains. The package implements those Euclidean domains found in Lipson’s book. It turns out that the most difficult part of such a package is the implementation of div and mod for an arbitrary domain. This led the author to exploit a feature of Icon Version 5.10 [Grisw85a] (function call by string image of name) in order to implement a "by-hand" version of the sort of call by inheritance seen in Smalltalk [Ingal78a] and Scratchpad II [Balza84a]. The package may be of use to algebraic algorithm prototypers in the ICON community, or as an adjunct to a course on computer algebra.

---


## 1. Introduction


### 1.1. Programming with Euclidean domains

John Lipson’s book. Elements of Algebra and Algebraic Computing, presents a number of interesting symbolic algebraic algorithms, in a style which seems implementable. The only non-trivial implementation detail for the algorithms pfesepted by Lipson is that they assume div and mod operations which are defined on every. Euclidean domain (and, by implication, representations and definitions of these operations for every Euclidean domain). For example, consider his presentation of the FFT algorithm (p. 298);

```icon
procedure FFT(?/,a(x),(«),A);
if N = 1
then
{ Basis. } Ao := o q
else
begin
{ Binary split. }
{ Recursive calls. }
{ Combine. }
```

for k := 0 until zi - 1 do

```icon
begin
Afc ;= Bjq + (ji^^Ck',
Bk - (li’^'SlCk',
end
end
```

The purpose of the package of routines described in this paper is to allow an ICON user to implement an algorithm such as FFT, at about the same level of description as above. By comparison, see Section 3.3.2, which contains our ICON version of the same procedure. In order to support a high level of description, it must be possible to describe the implementation of particular Euclidean domains, and to describe algorithms which apply generically to all Euclidean domain instances. We do this by deciding which functions are expected of all Euclidean domain implementations (say, div, mod, + and -), and then implementing a "dispatch" version of each of these. The "dispatch" div function inspects the type of its argument (say, integer, polynomial, quotient domain element or modular domain element), and then calls the associated div function in the domain implementation (say divjnteger, dlv_poly, dlv_Q or dlv_mod). The ability to test the run-time environment is a feature of ICON. Given a string, say "X", and an integer corresponding to a number of formal parameters, say 3, proc("X', 3) will return a procedure (a first-class value in ICON, assignable to variables) if the identifier X is globally to a procedure which is defined to take 3 arguments. Otherwise proc fails. To test for the procedure Oz, we evaluate procC'times" || "_Z", 2), and in general, for some string value X which corresponds to a procedure name, Y a domain name, and i a number of formal parameters, we evaluate proc(X || Y, i), where || is the ICON string concatenation operator. For example, here is the code for the "generic" division operation:

```icon
© (a, b) 4= ft proc("div_"|ltype(a), 2)(a, b) ■
```

Every implementation of a Euclidean domain must supply certain required procedures. (This notion of "must" corresponds to the idea of a "category" in Scratchpad II.) Optional procedures may be supplied by the domain implementation, but are synthesized if not supplied. The following table lists required, optional and synthesized procedures. Operator abs BASIC PROCEDURES FOR COMPUTING WITH DOMAINS Type Required Optional Synthesized Constant mod ■ i'3C ^r. nohRns'v / normalize exp Predicates unit Commands print pr, prs For a typical domain implementation, which serves as a model for other domain implementations, see for example Section 2.3.1, which describes our implementation of Quotient domains. A typical application is our implementation of Lipson’s algorithm (p. 264) for Newton Interpolation, seen in Section 3.3.3. 1,2. A summary of package facilities for Euclidean domains The domains supported are as follows: EUCLIDEAN DOMAIN CONSTRUCTIONS Primitive domains integer baseg Machine word integers Arbitrary precision unsigned base B integers Signed infinite precision integers Domain constructors 2 modulo poly . tpower Quotient domain Modular domain Polynomial domain Truncated power series domain The following are the representations in ICON we have adopted for objects in the Euclidean domains we support: Domain representation integer integer bases

```icon
record base_b (base, digits)
record Z (sign, mantissa)
record Q (dividend, divisor)
modulo
record modulo (Item, modulus)
poly
record poly (terms)
record term (coef. power)
tpower
record tpower (poly, N)
```

We have implemented the following application algorithms, which may be applied to objects from any Euclidean domain (unless otherwise noted): Application Algorithms ; y,________________ GCD greatest common divisor Jaxm- EUCLID extended GCD MOD_ES polynomial remainder sequence for GCD PREM E_PRS integral domain remainder polynomial remainder sequence for PRl^^ INVERSE inverse of x mod y NIA Newton interpolation algorithm CRA2, CRA Chinese remainder algorithm, for. 2 or more. - - linear congruences EFT Fast Fourier Transform FFI Fast Fourier Interpolation NPSI Newton power series inversion for truncated power series The system as described is comprised of about 2000 lines of commented ICON code. Supposing that the code defined in the following sections is stored in a file, say euclid, then it may be executed in ICON by adding the statement link euclid to the application program, and then running the ICON translator. The author will gladly supply this code (as is) to any interested user. Mail to ARPA:ericson@nyu or UUCP:{floyd,ihnp4}!cmcl2!csdl!ericson for more information, or via U.S. Mail (with a 600 ft mag tape) to the address listed at the beginning of this report. (The offer last until the author gets sick of making tapes.)


### 1.3. Our typographical conventions for displaying ICON code

We have dressed up and compressed the syntax of ICON, to give the algorithms i presented a more compact, functional appearance. Icon variables (simple names for single items, and procedure names) may appear as 1 subscripted quantities. This is purely formal, not actual, subscripting. Also, some | operator symbols are defined which would not be legal identifiers in ICON (because the i characters don’t exist in ASCII). Rather than spelling them out, in this report we use the symbol we would have liked to use. The following are some examples of the original code j and the fancier notation. Note that underscore ("_") is not a meta-character, but an 1 ordinary character that may appear in identifiers in ICON. Original ICON Fancy Notation 0 ne_base_B bases delta_l_m inus_1 ptus_poly ®poly For procedure definitions, instead of the obvious

```icon
procedure F (a, b. c)
code
end
```

we use the logical-looking

```icon
F (a, b, c) 4= code ■
```

For return x we use ))• x, and for return we use 1^. Instead of fall we use ±. All other ICON reserved words are bold-faced.


### 1.4. Afterthoughts

This code is no longer under development, and seems to be primarily of educational value. In the future, code such as this will be supplanted by far more capable systems such as Scratchpad H, as they become widely available and inexpensive. As an exercise, the author believes that the code addresses some of the essential software organization issues in computer algebra system design; If the code is to be applied in an educational setting, it would be well to stress to students several other important areas (these areas could form the basis of semester projects to extend the package): • Algorithm design. For example, efficient polynomial'gr^&^test common divisor, which has seen many attempts to reduce its complexity. Zippel’s notes [Zippe86a] contain a good discussion of this problem. --------- • Multivariate polynomials. This code does not" supply any of the several multivariate polynomial representations. • Explainability. Algorithmic (as opposed to "deductive") systems do not explain themselves. An ideal system would supply a proof its conclusion. • Numeric-Symbolic Interface. The results of some computations, for example, polynomial root-finding[Yap86a], are best expressed as numeric approximation intervals, even though they are defining "symbolic" quantities. More work needs to be done to automate the relationship between approximate versus exact computations.


## 2. Euclidean domains: representation and basic arithmetic


### 2.1. Generic arithmetic for Euclidean domains

Lipson’s book, p. 203, contains a significant proviso; We assume that our (Algol-like) language allows for the manipulation of values from an arbitrary Euclidean domain D with degree function d. In particular we assume that our language provides a Division Algorithm in the form of two operations “div” and “mod” which return, respectively, a preferred quotient and remainder in accordance with the Division Property of a Euclidean domain... The purpose of this package is to partially implement this proviso. The package implements several primitive domains and domain constructors,-which^ are classes of domains composed from other domains. When a procedure like © or mod is applied to an object which is an instance of a Euclidean domain, the type of the object is determined by inspection. This is either the primitive type, in the case of an instance of a primitive domain, or the type of the “outermost” constructor, in the case of an instance of a composite domain. In the case of required and optional procedures, the run-time environment is then tested to determine whether the domain implementation supplies an operation of this type. If the name of the domain is D, and the procedure name is P, then the run-time environment is tested for a procedure named Pd - For example, © applied to a quotient will look up the procedure ®q. Required procedures must be defined by the domain implementation, otherwise the operation fails. Implementation-optional procedures will synthesize their values if a more domain-specific implementation does not exist. Constants. A consequence of the existence of a variety of Euclidean domain instances is that there are a variety of structural representatioaSi^or-O-and L In a given computation, the 0 or 1 used- must be of the type of the domain instance. Hence to obtain the correct 0, we evaluate a 0 function which, given an object of the domain instance, returns the 0 of that domain, and similarly for 1.

```icon
0 (a) <= I) proc("z0ro_"|[type(a),1 )(a) ■
([■ proc("one_"||typ0(a),1 )(a) ■
```

Operators. The following procedures define the basic arithmetic operations for domains. As noted in Table 1, every domain must supply Abs, ®, ® and ©. mod, rem and normalize are optional, and © and exp are synthesized. •JI!.

```icon
Abs (a) <= ff proc("Abs_"||typ0(a),1)(a) ■
©(a, b)<= proc("plus_"|ltype(a). 2)(a, b) ■
\ri. 3 zp j j
© (a, b) <= il-©(a. -(b)) ■
'.anjo mo*';
— (x) .<= -ft-procC'm lnus_"||typa(x), 2)(x) ■
proc{"tlm es_"||type(a), 2)(a, b) ■
© (a. b) <= -fl proc("dlv_"||type(a), 2)(a, b) ■
mod (a. b) <=
if (x := proc("m od_"||type(a), 2)(a, b)) then -ff x
if <(b. 0(b)) then -fj-moJla, —(b))
normalize(
then ©(a, ©(b, ©(©( — (a), b). 1(a))))
else ©(a, — (®(b, ©(a. b)))))
```

Example. The polynomials in the domain of quotients of machine-word integers are denoted within ICON by the record-constructor expressions and variable assignments ax := poly([term(^(-2.1), 0), term (<2(1,1), 3)])

```icon
bx := poly([term (2(-3,1), 0), term (2(2,1), 2)])
nr a printing control structure, causes expressions to be printed out in a pleasing fashion.
```

The ICON expression pr{ax. " mod bx. ■' - modfax. ixH will print the following result: (-2)q + 1q’X*3 mod (-3)q + 2q’X 2 = (•2)q + (3/2)q X Similarly, given c(x) = (3/2)x —2, represented as ex := polydterm(^(-2.1). 0), term(2(3.2), 1)1) The result of evaluating pr{bx, " mod ”, ex, " = ", mod(bx. ex)} is (-3)q + 2q’X"2 mod + (3/2)q’X = (5/9)q

```icon
rem (a, b) 4=
-ft-(If (x ;= proc("rem_"lltype{a), 2)(a. b)) then X
else ©(a, ®(©(a, b), b)))
```

Example. The polynomials in the domain of quotients of machine-word integers are denoted with ICON by ax := po ly ([term (<2(5, 1). 0). term(fi(-2. 1). 1). term(2(1. 1). 2)l) The result of evaluating pr{ax, " rem ", bx, " = ", remCax, bx)} is 5q + (-2)q*X + 1q*X*2 rem 2q = Oq Similarly, given the equations over the integral domain of polynomials over machine integers denoted by

```icon
ax := po ly ([term (8, 0), term(-9, 1), term(6. 2)])
bx := poly_of(3),
```

the result of evaluating pr(ax, " rem ", bx, " = ", rem(ax, bx)} is 8 + (-QyX + 6*X*2 rem 3 = 2 normalize returns a preferred normal form of a value for a given domain. For example, for quotients, it would be the quotient such that the dividend and divisor have no common non-unit factors. For a modular domain, it would be the least positive element of the equivalence class of the value.

```icon
normalize (a) <=
if (x := proc("norm allze_"||type(a), 1 )(a)) then x
fl a
exp is the Russian Peasants algorithm for exponentiation. Our version Is transliterated
from R.B.K. Dewar’s SETL implementation of arithmetic for the NYU Ada/Ed system
[Dewar81a,Kruch83a].
exp (X, p) <=
ifp = 1then-fyx
else { result := l(x)
u ;= copy(x): v := p
running := u
whlie V ”= 0 do
{ If V % 2 = 1 then result := (gfresult. running)
running := ®(runnlng. running)
•(y resu It
```

Predicates. All of the predicates defined below except | are required to be defined by a domain instance implementation if they are to be used. However, this is not a minimal set: for example, is_zero could be defined in terms of =. 1 is really not a basic predicate, but since it may be defined in a general way, we include it here.

```icon
= (a, b) -(y proc("equal_"lltype(a),2)(a, b) ■
< (a, b) <= -fy ({proc("l8ss_"lltypa(a),2)(a, b)) ] <0(©(a, b))) ■
<0 (x) <= yy proc("negatlve_"||type(x),1 )(x) ■
unit M <= iy proc("unlt_"lltype(x),1 ){x) ■
= 0 (x) <= yy proc("is_zero_"||type(x),1 )(x) ■
```

a |c (a divides c) if c is a multiple of a, that is, if rem(c,a) — Q.

```icon
I (a, c) <= yy =0(rem(c, a)) ■
```

Commands. Every domain instance D implementation should define a preferred method of printing values in the domain, print^. On top of this, we supply printing control structures pr and prs. pr takes a list of arguments enclosed in braces, and prints them, using the printing

```icon
procedure appropriate for the type of each argument, followed by a carriage return, prs is
```

the same, omitting the carriage return. prs and pr are defined using the user-defined control operation features of ICON 5.10. [Grisw85a,Grisw83a] When pr or prs is called with a sequence of expressions in braces, the expressions are passed as unactivated co-expressions, which “are then activated with the ICON @ operator.

```icon
prs (x) <= every y := !x do prlnt(@y) ■
(every y := !x do print(@y))
w rlte()
print (x) <=
If type(x) = = "list"
then { w rltes("[")
```

every y := !x[1:*x] do { prlnt(y): wrlte(", ") } prlnt(x[*x]): w rltes("]") }

```icon
else if pp := proc("print_"||type(x), 1) then pp(x)
else if type(x) == "string" then writes(x)
else w rites(lm agex(x))
'Euclidean domains: representation and basic arithmetic
```


### 2.2. Primitive domains

The primitive domains are those which are not constructed from other domains, or which are best thought of as undecomposable. We have three such domains available: • Arbitrary-precision arbitrary-base integers. • Arbitrary-precision base 10 integers. • Ordinary machine integers. The latter are best unused: ICON does not notify the user of integer multiplication overflow, and overflow can occur very easily in the applications we deal with. For example, subresultant polynomial remainder sequences with cofficients in the 10000 range involve intermediate calculations in the 10000^ range.


#### 2.2.1. Abitrary base, infinite precision non-negative integer

arithmetic Base B Arithmetic Facilities Data structures base-a', set base Constants Ofcajeg , IhaxeB , ^base^ Operators > ©hajeg > ^base"^ » ^^base'Q > Predicates ^baseyst base^ Commands printbase-a Data structures. base is a number B such that 1 is less than the maximum machine word integer. Then digits is a list of machine word integers less than base and greater than 0. Width is the printing width of digits of the base, in terms of decimal digits.

```icon
record base-a (base, digits)
global Bass, W Idth
setbase (b. w) <=
Base := b
```

Constants. OhflieB

```icon
-fl-fta^esfx.base, [0]) ■
Ifcojea
basebase. [1]) ■
;o5-.k;r'j
kbasen W <= baseB^^asa. digits_oflabs(%), Base))
digits_of(x. B) <= if X < B then -ff [x] else -ft
Operators,
```

The base S addition algorithm is that of Lipson, p. 199. For input it takes a, b, lists of integers B, of length m returning a + b.

```icon
B := a.base
Z?ajeB(B , ©dig,-Mfa.digits,b.digits,B))
®digiti (ad. hd, B)
if m < n then {a := (llst(n-m,0) |||ad); b := bd }
else if m > n then { a := ad; b := list(m-n,0) ||| bd }
else { a := ad; b := bd }
c_dlglts := Ilst(m+1, 0);
gamma := 0
```

every I := m to 1 by -1 do

```icon
{ t := a[ll + b[i] + gamma
c_dlglts[l +1] := modi„teger(‘^- B)
c_d Ig its [ 11 := gamma
-ft- normalizedi;gj7j(c_digIts)
```

Example. The result of evaluating

```icon
X := baseji{Q ,(11): y := hajesCS .[7.7.7])
1 #8# + 7 7 7 #8# = 1 0 0 0 #8#
```

The base B subtraction algorithm is Knuth Algorithm 4.3.1 S, transliterated from a SETL implementation of Robert Dewar. Assume a^b are lists of integers ^B. Returns a-b. Qbastfi

```icon
b := copy(bb): B := a.base; m ;= *a.digits
repeat
{ n := ’b.digits
if m < n then pr{"ERROR: base^ Integer subtraction underflow"}
else if m > n
then b := base^k^^ list(in-n,0) ||lb.digits)
else -ft h<35eB(b.base, Qdigits (a.digits, b.digits, b.base))}
Qdigiis (a, b. B) <=
u := copy(a)
V := list(*a-*b,0) l||copy(b)
```

every j := *u to 1 by -1 do

```icon
{ utJl := u[il - vtn + k
if u[]l < 0 then { u[Jl +:= B; k := -1 } else k := 0 }
-ft- normalizedigitsM
```

Example. The result of evaluating

```icon
X := hajeB(10, 11,0.0.5,6,3]): y := baseBCiO, [5,3,3,5])
pr{x, " - ", y, " = ", ©fca,eB(X-y)}
X := Z><3jeB(10,[2,1,21): y := baseB('\0, [9,9])
pr{x, " ■ ", y. " = ", ebase^f-^' y)}
y := base-Bi'^O, [1.9,9])
pr{x,".", y," = ", ©,,,,^(x,y)}
100563 #10#-5335 #10# = 95228 #10#
2 1 2 #10 # ■ 9 9 #10 # = 1 1 3
2 1 2#10#-1 99 #10# = 1 3 #10#
normalizebase-B (0
d := normalizedigiuir.digits}
■ft
normalize digits (d)
while Cd > 1) & (d[1 ] = 0) do pop(d)
ft d
```

The base fl multiplication algorithm is that of Lipson, p. 200. As input it takes a, b, lists of integers ^fl, of length m and /i. It outputs a®b. Obajea (a- it

```icon
0dig,-«(a.dlglts, b.digits, a.base)) ■
^digits (a. b, B)
c := llst(m +n,0)
```

every k := 0 to n-t by 1 do { gamma: =0 every I := 0 to m-1 by 1 do { t ;= a[m-l]’b[n-k] + c[m+n-k-l] + gamma

```icon
if t < 0
then pr{"E''RUOR: integer overflow In
base = ", B}
c[m “l”n"k“i] : ^^^integer^^*
gam ma := t / B }
c[n-k] := gam m a
ft- normalizedigi,s(c)
```

Example. The result of evaluating X := A:z,a„B(28107324); y := kbase^^T ‘ kbase-^C^ pr{x. " * ", y. " = ", 0frajeB(x,y)} X kbasf^^"^ • kbaseyi^^^^^^ pr{x. " • ", y, " = ", 0baieB(x,y)} 8 1 0 7 3 2 4 #10# * 7 5 6 2 5 #10# = 2125616377500 #10# 8 1 0 7 3 2 4 #10# * 7 5 6 2 5 #10# = 2125616377500 #10# 4 7 8 #10#’ 4 6 2 5 #10# = 3 4 5 8 5 7 5 0 #10# Eoclidean domains: representation and basic arithmetic The following algorithm computes by long division. The design is that of Knuth Algorithm 4.3.1 D [Knuth73a], and the implementation is largely borrowed from a SETL implementation of Robert Dewar [NYU 84a]. Most of the following comments are lifted from the Dewar implementation. This is by far the most difficult of the four basic operations. This is because the paper and pencil algorithm involves certain amounts of guess work which cannot be programmed directly. The approach (analyzed in detail by Knuth) is to reduce the guess work by computing a rather good guess at each digit of the result, and then correcting if the guess is wrong. <= 'ft' normalizeiMuet(.base'a{»^-^^^*. ®digiu

```icon
b.diglts, a.base))) ■
©digit* (a, b, B) <=
If the divisor is 0, then fail.
If (*b = 1) & {b[1l = 0) then { prf’ERROR: divide by 0 In base^”}\ ±}
If a is shorter than b, return 0.
It *a < *b then
```

The case of a one digit divisor is treated specially. Not only is this more efficient, but the general algorithm assumes that the divisor contains at least two digits. Basically dividing by a single digit is straightforward. Since we can represent numbers up to B*B— 1, we can do the steps of the division exactly without any need for guess work. The division is then done left to right. If *b = 1 than Eaclidean domaina: representation and basic arithmetic every j 1 to *a do qUl ;= du / b[11 normalizetiigiak^} } Otherwise we must commence with the full long division algorithm. u copy(a)

```icon
V := copy(b)
m *u - n
q := llst(m +1,0)
Knuth Step DI. [Normalize] The first step is to multiply both the divisor and dividend by a
```

scale factor. Obviously such scaling does not affect the quotient. The purpose of this scaling is to ensure that the first digit of the divisor is at least B/2. This condition is required for the proper operation of the quotient estimation algorithm used in the division loop. Note that we added an extra digit at the front of the dividend above.

```icon
u := ®digia (u- Nl> B)
If *u = tn +n then u := [O] |I| u
V ®digiu • 1^1' B)
Knuth Step D2. [Initialize j] This is the major loop, corresponding to long division steps.
```

every J := 1 to m+l do Enclidean domains: representation and basic arithmetic Knuth Step D3. [Calculate qjiat] Guess the next quotient digit by doing a division based on the leading digits. This estimate is never low and at most 2 high.

```icon
If i|[j] = v[1] then qe := B-1 else qe
((u[irB) + u[J + 1])/v[11
```

The foUowing loop refines this guess so that it is almost always correct and is at worst one too high (see Knuth [Knuth73a] for proofs). while (v[21*qe) > (((uUl’B) + ull + 1l-(qe*vl1l))’B+uU + 2n do qe-:= 1 Knuth Step D4. [Multiply and subtract] Now (for the moment accepting the estimate as correct), we subtract the appropriate multiple of the divisor. This is similar to the inner loop of the multiplication routine. every k := n to 1 by -1 do { du ull + kl - (qe * v[k]) + c ulJ + kl du % B c du / B

```icon
if ull + kl < 0 then { utJ + kl +:= B: c-;= 1 }
u(Jl +:= c
```

Knuth Step D5,D6. [Test remainder. Add back] If the estimate was one off, then mU] went negative when the final carry was added above. In this case, we add back the divisor once, and adjust the quotient digit. qUl

```icon
If uin < 0 then
Eaclidean domains: representation and basic arithmetic
```

every k := n to 1 by -1 do

```icon
u[j + kl +:= vtkl + c
if utJ + kJ >= B then { uU + kl -:= B; c := 1 }
else c := 0
uUl +:= c }
■(y normalizedigfoM
```

Example. The result of evaluating every xy := IHIO. 1], 14.2], (27. 9], 142.2], 190,1], [188175, 325], (188175, 579], [188175, 580], [188175, 578], (121903, 5335],

```icon
[212, 99], [115668, 75625]]
do { X
pr{x, ” / ".y.” = ", ©iojeaCx. y)} }
1 0 #10# / 1 #10# = 1 0 #10#
1 8 8 1 7 5 #10# / 3 2 5 #10# =
1 8 8 1 7 5 #10# / 5 7 9 #10# =
188175 #10#/ 5 8 0 #10# = 3 2 4 #10#
188175 #10#/ 5 7 8 #10# = 3 2 5 #10#
2 1 2 #10# t 2 9 #10# = 2 #^2#
1 1 5 6 6 8 #10# / 7 5 6 2 5 #10# = 1 #10#
Eaclidean domains: representation and basic arithmetic
```

Commands. We supply a print command. printbaie^ (b) <=

```icon
local digits
wrltes(b.dlgits[1], " *)
```

every write8(right(Irest(b.digits), Width, "O"), " ") writesi"#", b.base, "#") Predicates. We supply two predicates, <bate3 and =basen'

```icon
^btuet (a. b) -(y fcajeala-base, <tiigio (a.digits, b.digits)) ■
^digits (a, b) <=
If ’a < ’b then -fy
else If ('a > ’b) then ±
else If *a = 0 then ±
else If (a(1] > b[1]) then ±
else If (all] < b[1]) then -f)
else ‘If <(fig(u(ta*f(a), rest(b))
= baset (a* b) <= -ft- -digits (a.digits, b.digits) ■
~ttigits (a, b)
If ’a < *b then ±
else If (*a > *b) then ±
else If *a = 0 then -(y
else If (a[1] "= b[1]) then ±
•Isa 'ft =digitt(rest(a), rest(b))
Euclidean domaini: representation and basic arithmetic
rest (x) <= If *x < 2 then H else -(y x(2:*x + l] ■
```


#### 2.2.2. Arbitrary precision integer Euclidean domain Z

Integer Arithmetic Facilities Data structures Constants Oz. Iz. kz Operators ©z. modz, absz, degz, normalizez Predicates “z. *^z. unitz, ^Oz. ““Oz Commands printz Data structures. sign is 1 or —1. mantissa is a base Base integer, where the Base is set by kz.

```icon
record Z (sign, mantissa)
```

Constants.

```icon
(a.mantissa)) ■
Iz (a) "ty
(a.mantlssa)) ■
kz takes an ICON integer and transforms it into a Z constant.
kz W <=
Initial
■|yZ(lf X = 0 then 1 else x/abs(x),
hajeaCBase. tf{gitr_oy(abs(x), Base)))
```

Operators. If <02(a) & >02(b) then ®z (b. a) ■ft normaZizez( It =02(a) then b • Ise if =0z(b) then a • Ise if (>02(a) & >Oz(b)) 1 (<02(a) & <02(b)) then Z(a.slgn, b.mantissa, Base)) else { # a > 0 and b < 0, so... It *^^eB(^**^*'^tlssa, b.mantissa) then Z(-1, @j,aje,(b.mantissa, a.mantissa, Base)) else Z(1, ©fcajeB^*'"’antlssa, b.mantissa, Base)) - Example. The result of evaluating X := ^z(1): y := kzi-999} pr{x. " + ", y, " = ", ®z(x, y)}

```icon
“Z (x) •<= ■fyziorzna/zz«z(^("X'*l9’’-x.mantlssa)) ■
```

Example. The result of evaluating X := Jtz(212); 'i := kz{-9^} >0 srf'Y .ajqsmsS Eaclidean domains: representation and basic arithmetic

```icon
(a, b) <= -fl-norwui/zzezCZfa.slgn’b.sIgn, 0j,aj^j(a.mantissa, b.mantissa))) ■
```

Example. The result of evaluating pr{x, ” * y. " - ®z(x.y)} pr{x, • • y. " - ", ®z(x,y)} 28107324Z * 75625Z = 2125616377500Z 7478Z * (-4625Z) = (-34585750Z) -(I-norzna2zzez(Z(a.sign/b.sign,©ha,eg(a.mantissa,b.mantissa,Base))) Example. The result of evaluating Eaclidean domains: representation and basic arithmetic every xy := 1(110, I], (121903, 5335], (115668, 75625]]

```icon
do { X := jt2(xy(l]): 'i A:2(xy(2]): pr{x, " / y, ** = ", ©z(x. y)}}
lOz / 1z = lOz
modz (a. b)
IKlf <z('’’
modz{>^. —z(b))
else If <z(&,
then ©2(a- ~z(®z(b. ®z(“z(lz(a))« ©z(a< b)))))
else ®2(a- “z(®z(b- ©z(a> b)))))
i i )
```

Example. The result of evaluating

```icon
X := *2(121903): y := *2(5335)
pr{x, " mod ", y, " = ”, modzk^. y)}
121903Z mod 5335z = 4533z
.3,aesdt»*K!.5
tseBsnve.
Ob fetsgiSsl
-*0 y^eve
{’’s’'>8eshw
ahsz (x) 4=
X.mantissa) ■
■4h« oedt 't5'> .*»§!«.» ’1
Eaclidean domains: representation and basic arithmetic
degz (X) •<= t X ■
normalizez (x) •ft’ (If =02(x) then Z(1, x.mantissa) else x) ■
```

Predicates. =z(a. b)

```icon
If ( = 02(a) 4 =02(b)) then it
else If a.sign
b.sign then ±
else ‘ft =2,aj«iiantlssa, b.mantissa)
If a.sign < b.sign then “ft
If a.sign > b.sign then ±
If a.sign = 1 then -ft <basei(^-mantissa, b.mantissa)
If a.sign = -1 then ft- <j„;«g(b.mantlssa, a.mantissa)
unitz {>•) <= ■ft(=z(x, lz(x)) 1 =z(x. Z(-1.1i,a,ej(x.mantissa)))) ■
>0^ (x) <= -ft ((x.sign = 1)4 not =02(x)) ■
<0^ (X) <= ■ft ((x.sign = -1) 4 not =02(x)) ■
= 0z (x) <= "ft =*a,eB(x.mantlssa. 0ia,«j(x.mantlssa)) ■
```

Commands. printz

```icon
local digits
If a.sign < 0 then writes(”(-”)
digits := a.mantissa.digits
```

every ch := idigits do wrltes(rlght(ch, Width, ”0")) wrItesC'z")

```icon
If a.sign < 0 then wrltes(")")
Eoclidean domains: representation and basic arithmetic
```


#### 2.2.3. Small integers Euclidean domain

We provide the following machine integer arithmetic facilities; Machine Integer Arithmetic Facilities Constants ^mttgerr ^integer Operators ©, integer^ Ointeger* circleslashinteger» ^^ftlintegert ftiodinugert ^^Sintegert ^^^integer Predicates integerintegert integer Commands print Steger Constants. We provide constants 0 and 1, as follows: ^integer (x) <= Operators. integer (x) ^integer

```icon
-jy a * b ■
circleslashinteger (a, b) -|y a / b ■
If m < 0 then m := -m
repeat If a < 0 then a := a + (abs(a/nri) + l)*m else a % m
rem is not mod, because rem may be negative, but mod is never negative.
reminuger (a. b) 4= -(1 a % b ■
Eaclidean domains: representation and basic arithmetic
^^SitUeger (*)
absinteger M
-ft ab8(x) ■
```

Predicates. ~ ^integer (x)^'f|'(X“O)" <®£Bttger (x)'^ ■ft'xCOH

```icon
~ integer (*> b) a “ . b ■
“WittBfejer (X) If ((X = 1) I (X = -1)) then -ft-x ■
```

Commands.

```icon
printinteger (x) <= If X < 0 then wrltes("(", x, ")") else writes(x) ■ i
Eoclidean domains: representation and basic arithmetic
```


### 2.3. Domain constructors

EUCLID provides three classes of domain constructions: quotient domains Qo, modular domains D/(e), polynomials D[x] and truncated power series r(D[[x]])„.


#### 2.3.1. Quotient Euclidean domain Q,

Quotient Domain Arithmetic Facilities Data structures Constants OjQ, 1q , Operators ~fl» f^odQ, normalizeq , degq Predicates — unitQ Commands printQ Data structures. The domains Q are of the form Q={— | m, n^D,n^0}, for some Euclidean domain D. Elements of such a domain Q are quotients with a dividend and a divisor:

```icon
record Q (dividend, divisor)
```

Constants.

```icon
0j2 (x) <= ■fl' i2(0(x.dividend), l(x.dividend)) ■
Ifl (X) 4= -fl fi(l(x.dlvidend), Kx.dividend)) ■
kiQx (•.»<= irterm(|2(l. 1(1)), I) ■
```

Operators.

```icon
Then
where x=pq'®p'q, y=qq’'.
©fl (a, b)
local zz, top
top := ©(®(a.dividend, b.divisor), ®(b.dlvidend, a.divisor))
zz := 0(a.dividend)
Yt (If “(top, zz} then Q{zz, l(a.dividend))
else zionna/izej2(<2(top, ®(a.dlvisor, b.divisor))))
— Q (x) ‘ft j2(“(x.dividend), x.divisor) ■
(»t b) 4= ■fl'noz7na/izC2(fi(®(a.dividend, b.dividend), ®(a.divisor, b.divisor))) ■
©fl (a, b)
local zz
zz 0(b.dividend)
If =(b.dividend, zz) then pr{"ERROR: divide by 0 In j2"}
else ■(|•(lf ={a.divisor, zz) then Ofl(a)
else zioz7na/izefl(i2(®(a.divldend, b.divlsor), (b.dividend, a.divisor))))
There are no remainders in quotient division.
modfl (a, m) <= ■fl'Ofl(a) ■
normalizejQ{x) reduces the size of the dividend and divisor, and ensures that any negative
```

sign is in the dividend. Let g=GCD(x,y). Then normalize=

```icon
normalizeQ (x) 4=
local g, top, bottom
g := GCD(x.dividend, x.divisor)
top := ©(x.dividend, g)
bottom := ©(x.divisor, g)
■fy (If <0(bottom) then j2(-(top), -(bottom))
else 5(top, bottom))
Eaclidean domains: representation and basic arithmetic
d8g_Q (X) 4= it X ■
```

Predicates.

```icon
if and only if pq’^gp'•
• quaI_Q (a. b)<=
= (®(a.divisor,b.dividend), ®(b.divisor, a.dividend)) ■
Everything is a unit in Q.
unlt_Q (X) <= -(y ■
```

Commands.

```icon
prlnt_Q (X) <=
If =(x.divisor, l(x.divisor))
then prs{x.dividend, "q"}
else prs{"(", x.dividend,
x.divlsor, ")q"}
```


#### 2.3.2. Modular Euclidean domain D/(x)

Modular Domain Arithmetic Facilities Data structures modulo Constants Operators Predicates Commands modulo ■> ^modulo © modulo, ~ modulo t ^modulot ® modulo t tlOrmalizejnofiuio, degmod^ig ~modulot H^itmodulot ^^modulo print„odulo Data structures. Enclideaa domains: representation and basic arithmetic An item from a modular domain, say Z5. is specified by the item in the “base” domain, plus the modulus.

```icon
record modulo (item, modulus)
```

Constants. Omodulo (»)

```icon
"ft modulo (O(a.ltem). a.modulus) ■
Imodulo (»)
it modulo (l(a.itom). a.modulus) ■
```

Operators. (a. b) ^tnorma/ize.„^„to(modulo(®(a.ltem. b.ltem). a.modulus)) ■ — moduloM"^ ■ft ^module b) <= ^normn/ize^„to(modulo(®(a.ltem. b.ltem). a.modulus)) ■ ©^uu> (a. b) ^t^o^^a^ze„«,„z.(modulo{®(a.item. IN VERS E(b.ltem .b.modulus)). a.modulu normalize^ul. W <= Itmodulo (mod(x.ltem. x.modulus). x.modulus) ■

```icon
deg„u>dulaM^ -ft mod (x.ltem. x.modulus) ■
```

Predicates.

```icon
“mfldMio (a. b) <= -ft =(mod(a.ltem, a.modulus), mod(b.ltem, b.modulus)) ■
```

unitn^ulo <= it -(mod(a.ltem. a.modulus). 1) ■ Nothing is negative in a modular domain.

```icon
^^modulo ia) -L ■
```

Commands. prints M <= p«rr.


#### 2.3.3. Polynomial Euclidean domain D[x]

Polynomial Domain Arithmetic Facilities Data structures poly, term; poly_of, Ort_coef, lead_coef Constants Operators ®polyt “pofyt ®polyt ®polyt ^odp0iy,evalpgiy, degpgfy, ®iieg> normalizCpoiy Predicates degrees ~polyf tOiltpoiy Commands printpoly Data structures. Polynomials a(x)€ some domain D[x] are finite sums of the form a(x) = They are represented as lists of terms, in increasing order of power, such that there is always at least one term, 0, if the polynomial is zero. Otherwise the least term may be of any degree.

```icon
record poly (terms)
poly_of (X) <= -H- poly ([term (x. 0)1) ■
```

The coefficient of the constant term as an element of D, if there is a constant term, otherwise 0, may be obtained with: (fx)

```icon
local a
```

a := fx.torms[1l ■f) (If a.power = 0 then a.coef else O(a.coef)) The coefficient of the term with the highest degree may be obtained with:

```icon
leadco^ (ax) •<= (ax.torms[*ax.terms]).coef ■
```

A term, say ax", is represented as . It is assumed that coefficient and indeterminate range over the same base domain, and that the power ranges over

```icon
record term (coef, power)
```

Constants. The zero of the base domain of a coefficient of the polynomial is obtained via:

```icon
Opofy (P) <=
z := 0(p.term«(1l.coef)
it poly([term(z. 0)l)
```

Example. The result of evaluating pr{"j2: 0pofy(poly([term(:2(-2.1). 0)1))} pr{”QZ: 0 = ", 0poZy(poly([A:Zj2x(-2, 0)]))} QZ: 0 = Ozq The one of the base domain of a coefficient of the polynomial may be obtained with: Ipo/y (P) Eaclidean domains: representation and basic arithmetic z ;= l(p.torm8[1l.coof) •ft poly(ltorm(z. 0)l) An arbitrary-precision rational whole number is obtaind with:

```icon
kZQ (e) 4=
•ff J2(top. 120®P))
```

An arbitrary-precision rational whole number-coefficient indeterminate sx^ is obtained with: An arbitrary-precision integer-coefficient indeterminate ex^ is obtained with:

```icon
kZx (•.¥)<= -ft term(;:2(«)-y) ■
```

Operators. ®poZy (®’ P)

```icon
local Terms, T, z
Terms :=
b-terms)
T := []: z := O(a.termslll.coef)
^y^ty t ;= ITerms do It not =(t.coef, z) then T |lj;= [t]
■(y (If *T > 0 then poly(T) else 0(a))
©fermj (*• b)
Enclidean domains: represenUtlon and basic arithmetic
```

local c_coef. at. ap, ac. bt. bp, be If *a = 0 then b else if *b = 0 then a

```icon
else { at := all]; ap := at.power; ac := at.coef
bt := b(1l; bp := bt.power; be := bt.coef
If less(ap. bp)
then { If — (ac, 0(ac))
then
else [atl ID ®t«nw(f®st{a). b) }
else If =(ap, bp)
then { c_coef :» ®(ac, be)
If “ (c_coef, 0(c_coef))
* then ®,ermj(f9aUa). rest(b))
else (term(c_coet, ap)] DI
®wrmj(fe8Ua). rest(b)) }
else ®teni» (^> ®)
```

Example. The result of evaluating ax := poly((term(j2(-2.1). 0). term(fi(1,1). 3)]) bx := poly(lterm(j2(-3.1), 0), torm(l2(2.1). 3)l)”- fx := poly(IfcZ]2x{*2. 0). ^Zj2x{1.3)l) gx := poly([feZi2x(*3. 0)- ^Z12x(2.3)]) prffi; (". ax. ") + C. bx. ") = ", ®p<,Zy(ax. bx)} prfQZ: {'•. fx. ") + (". gx. ") » ”, fl*)} {(•2)q + 1q*X‘3) + ((-3)q + 2q*X*3) = (•5)q + 3q*X 3 QZ: ((■2z)q + 1zq*X‘3) + ((■3z)q + 2zq*X‘3) = (-5z)q + 3zq*X 3 Enclidean domains: representation and basic arithmetic po/ji (x)

```icon
local c
```

every t := lx.terms do c 5}:= (~term(O] ■ft poly (c)

```icon
“term 0) <= -ft term(-(t.coef). t.power) ■
```

Example. The result of evaluating

```icon
ax := poly(lterm(fi(-2,1), 0), term(i2{1.1). 3)1)
fx := poly(IfcZi2x('2. 0).
prffi:
prfQZ:
• ((-2)q + 1q*X*3) = 2q + (-1)q*X*3
QZ:
- ((-2z)q + 1zq*X‘3) “ 2zq + (-1z)q*X‘3
®pofy (*• it ®poly termsi^i b-terms) ■
<S>pofyternu (»• b-torms) 4=
■ft (it *b_term8 = 0 then 0(a)
else ®poly^^poly term (*• b_terms[1l),
<^pofy terms (»■ rost(b_torms))))
^polyterm (»• b_term) <=
■ft (If *a.terms < 2
- I faaq'at
, nerti
Euclidean domaini: representation and basic arithmetic
then poly([0^rm
b_torm)])
also ®poiy (poly(I®term lermfa-term 8(1], b_term)l),
^pofyterm (poly(re8t(a.terms)). b_term)))
0term term (a_term, b_term) <= •f^torm (®(a_term.coef, b_torm.coef), a_term.power
```

Example. The result of evaluating

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
else { q := poly([term(©(ZeaJco</<f)7eac?coe/b)).m-n)])
Enciidean domains: representation and basic arithmetic
If m = 0
then -ft-©poiyCquotient, q)
• Ise { subtrand := ~pofy(®pofy(q. b))
r := ©po/y(r. subtrand)
- quotient := ©po/y(quotlont, q)
```

Example. The result of evaluating

```icon
ax := poly_of(1): bx := poly_of(3)
prpintegers: ", ax, "T, bx, " = ", ©poj^(ax, bx)}
poly(Iterm(fi(5,9), 0)])
poly(Iterm(i2(-2,1), 0), term(^2(3,2), 1)])
fx := poly ([term (j2(A:2(5),^2(9)), 0)])
gx poly([term(j2(^21'2).^2O))’ tef'”(fi(^7(3).^2(2)), 1)1)
pr{"fi:
(", ax, ") ! (", bx, ") = ", ©pofy{»^. bx)}
pr{"QZ:
```

C. gx. ") ! (", fx, ") - ", ©poiyig^. fx)}

```icon
ax := poly(lterm((2()5:2(166), Jt2(243)), 0), term(i2(fcz(-275),fc2(243)),1)l)
bx := poly([term(i2(^2(‘'''®®®®)' ^2(^5625)), 0)])
pr{"QZlx]; ax, "I ", bx, ") = 0", ©(ax, bx)}
integers: 1/3 = 0
((5/9)q)/((•2)q + (3/2)q*X) - Oq
QZ:
((-2z)q + (32/2z)q*X) ! ((5z/9z)q) = ((-18z)/5z)q + (272/10z)q*X
QZlx): ((166z/243z)q + ((-275z)/243z)q*X / (1156682/75625z)q) =
(6276875z/14053662z)q + ((•20796875z)/28107324z)q*X
Enclidean domains: representation and basic arithmetic
modpoiy (a, b) ■<= -ft ©(a, ®(b, ©(a, b))) ■
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

Truncated Power Series Domain Arithmetic Facilities Data structures tpower Constants ^tpower t ^tpower Operators ®tpowerr ~g>owert ^tpowert ©tpowert normalizetpower Predicates ~ tpower f ^^^^^ower Commands printtpower Data structures.

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

®ipow«- (a. *») <= ■(ttpowor(truncat8(®poly(a.Poly. b.Poly). a.N), a.N) ■ ©9»0H-er

```icon
**) •()^tpower(truncate(©po/y(a.Poly, b.Poly), a.N), a.N) ■
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

We provide algorithms for the following applications: <» Euclid’s algorithm for greatest common divisor, in simple and extended • versions. • Inverse of a mod m. • The Chinese Remainder for 1, 2 or N congruences. • The solutions to the Diophantine equation ax + by = c.


#### 3.1.1. Greatest Common Divisor

We have two versions of Euclid’s Algorithm over a Euclidean domain D, from Lipson, p.

```icon
GCD(a,h,D)
Input: a,h€D, not both zero.
Output: a gcd of a,b.
GCD (a, b) <= "ft (If *(b, 0(b)) then normalize(&} else GCD(b, mod(a, b))) ■
```

The following is a table of expressions and their gcd's, as computed via GCD: AlforithiBf for Tsrioni problwnt over Encltdosn doniolnt Greatest Common Divisors Domain GCD S333z *lSz Z5[x] ((-2) mod 5)+(l mod 5)*X*3 (3mod5)+(4mod5) "X QZtx] (166zZ243z)q + ((-275z)/243z)q*X QZ[x] (-2z)q + lzq’X*3 (5z/9z)q EUCUD{a,b) Input: a,h€D, not both zero. Output: g,s,t such that g is a ged of fl, b and g=jfl+rb.

```icon
EUCLID (A. B)
local q, a, a, t
```

a := [copy(A), copy(B)]

```icon
while not(®=(a(2]. 0(A))) do
```

a := (a[21. e(a[1l. ®(al21. q))] a (•[21. e(sI1l. 0(8(21. q))l t ItI21. e(tll]. ®(tI21. q))] } ■fl' [nflrmfl/zze(aI1]). normalize(9{'\]), nflZ7nfl/ize(tI1l)l Algoritlimi for ▼ariooi problem* over Enclidean domains The following is a table of expressions and their extended gcd’s, as computed via EUCLID: Extended Greatest Common Divisors A, B GCD, s, t (5/9)q, (.16/9)q-»-(-4/3)q’X, lq-h(8/9)q’X+(2Z3)q’X^ (.2mod5)+(lmod5)*X3. (-3mod5)+(2mod5)’X^) (3mod5)-t-{4mod5)’X, (Imod 5), (2mod5)*X


#### 3.1.2. Modular Inverse

Our modular inverse algorithms is that of Lipson, p. 214. INVERSE{a,m): Computation of a~^modm Input: a,m€D, where D is a Euclidean domain. Output: If then a~^modm: otherwise error.

```icon
INVERSE (a. m) 4=
local gst
gat := EUCLID(m, a)
If unit (gstllj) then -ftwod (© (gstI3], gstll]), m)
also pr{*’E R R O R: a, "“-1 ", " mod ", m, " doaa not exist"}
```

A table of modular inverses as computed by INVERSE is as follows: modulus ERROR (lmod2)-f-(lmod2)*X*2 (lmod2)+(lmod2)’X*2-l-(lmod2/X‘5) (lmod2)-t-(lmod2)*X-t- (lmod2) •X*2 -t- (Imodl) ‘XM (9/5)q -1- (8/5)q*X + (6/5)q*X-2 Algorithm! for Tarlont problem! over Enclldean domain!


#### 3.1.3. Chinese Remainders and Single-Variable Linear Congruential

Systems We provide three algorithms, CRAl for solving equations of the form a x ■« b mod m, and CRA2 and CRA for solving systems of equations of 2 or more congruences of the form X ■■ a mod m. CRAl (a, b, m): Solution of a single linear congruence relation. Input: a,b,m such that a x ■« b mod m. Output: a particular solution xi. Niven and Zuckerman [NivenSOa], in their section 2.3 note that, given a congruence ax^bmodm^ we can reduce it to my^— bmoda. If yo is a solution of the reduced (myo+^) congruence, then xo=-------------is a solution for the origmal congruence. They apply the reduction until the congruence is solvable “by inspection’’. This we do not do. They also have some tricks for size reduction (on p. 43) we will not apply (due to laziness). Our “by inspection’’ termination condition will be to perform the reduction until a mod m=l or b—Q. Then we return b mod a, in a recursive setting which builds up the original x q .

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

else fl-©(©(®(m. CRA1 (m. -(b), a)), b), a) } Algorithm! for ▼arioni problem! over Enclidean domain! Example. The following results were obtained from executing CRAl (the examples are from Niven and Zuckerman [NivenSOa], Sect. 2.3: • C2?A(7,1432,5317): x such that 7x-14327noJ5317 is 4762. • C/?A(863,880,2151): x such that 863x»880nioJ2151 is 173. • C22A(589,5O9,817): There is no x such that 589x"'509/nod817. CJ?A2 and CRA aic from Lipson, p. 254 and p. 257. CRA2 (r, m, s, n): Two-congruence Chinese Remainder Algorithm for Z Input: r,ni,j,n€Z, where n,/n are relatively prime. Output: tZ€Z such that U"*rmodm, U^smodn. CRA2 (r. m. a. n) <=

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

CT := TOoJ(®(e(r. TOod(U. m)). c), m) Example. The problem is to find u(x) in Z[x] such that u(x)mod3=x, u{x)modl= 1,

```icon
M(x)moJ4=2x+3, and
tt(x)mcwi5=3x+3
```

Let u(x)=ax+b. Then a mod 3=1 b mod 3 = 0 a mod 7 = 0 b mod 7=1 a mod 4 = 2 b mod 4 = 3 a mod 5 = 3 We can solve for a and b individually using the n-congruence CRA algorithm, and we are done. Executing the following code:

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

XI := ©(e(c, ®(b. yi)). a) } -n-Ig.xi.yi] } Example. By evaluating D/OPHANrZN£(84,54,-24), we find that all integer solutions (x,y) of the equation 84x+54y=(—24) are of the form x=l + 9t, y=(—2) —14t. Example. By evaluating DZOPHANrZNE(999,-49,5000), we find that all integer solutions (x,y) of the equation 999x+(—49)y=5000 are of the form x=13+49t, y- 163-(-999)f. Example. By evaluating DZOPHA2V77N£(247,589,817), we find that all integer solutions (x,y) of the equation 247x+589y=817 are of the form x=( —ll)+31t, 4y=6— 13t. 3-2 Polynomial remainder sequences Polynomial remainder sequences are studied as a method of finding variants of the greatest common divisor for elements of integral domains. Variation in the definition is required because integral domains do not support long division. It is also desirable to compute values which share properties of the greatest common divisor (which might then be reclaimed by homomorphic image methods; see Lipson, ch. 8), such that the computation does not suffer the large coefficient growth of Euclid’s algorithm on even moderate-sized polynomials. Yap [Yap85a] discusses the issue, presenting an example of Knuth exhibiting the coefficient growth problem. Polynomial remainder sequences are discussed in greater depth in the paper by Loos [Loosa]. We have implemented three variants of polynomial remainder sequence: • mod-based PRS. • prem, a pseudo-remainder for division over integral domains, and a •prem-based PRS, as defined in Yap |Yap85a]. • Subresultant PRS, as defined in Yap [Yap85a] and based on an algorithm of • Collins, as presented by Brown. 3.2.1 MOD-based PRS The simplest polynomial remainder sequence is simply that of Euclid’s algorithm. That is, we define MOD_RS{a,b) to be the PRS of mod{a,b).

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

exp(P,_i. -<fe,(8,_i. 1))) Pi (8i-2. C,—2. /?»-2) <= ■ft poly_of(®(®(oxp(-(l(c/-2)). Pi {Pi-2. Pi-1. Pi) <= -ft ©(P R E M {Pi-2. Pi-1}. Pi) ■ 3*3 Power series and polynomial inversion and interpolation Under this heading we provide the following facilities; • Newton’s method for construction of polynomials by interpolation. • Fast Fourier Transform (FFT) and Interpolation (FFI). • Newton’s method for truncated power series inversion. 3.3.1 Newton’s method for construction of polynomials by interpolation NIA (rm_list); Newton’s Interpolation Algorithm (CRA for F[x]) Input: [[ak, bk]] such that U(ak) = bk, U(x) € F[x] Output: U(x)

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
{ Mx := ®{Mx, ©(polydterm(1(b), 1)]), poly_of(a)))
ab := pop(ab_8); a ;= ab[1l; b := abl2l
c := ©{1(a), eva/pofy(Mx, a))
```

a := ®{©(poly_of(b), poly_of(evaZpoZj,(Ux, a))), poly_of(c))

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
C := FFT(N, bx, ©(l(omega), omega))
ax := polynomlallze(©vector ,caZar(C, modulo(N ,13)))
polynomiaiize (B) <=
local r, I
```

every b ;= IB do { If not( = (b, 0(b))) then r lterm(b, I)] H poly(r) ®vector scalar

```icon
local R , I
R := IlstCV); I ;= 1
```

every v ;= IV do { R[I] ;= ©(VII], x); I +:= 1 } -fr R 3.3.3 Newton’s method for truncated power series inversion NPSI (): Newton’s Power Series Inversion Method Input: a(t) mod t*(2‘n) » sum(i=0,2‘n-l,ai t*i), aO # 0. Output: x‘(n)(t) « a(t)*-l mod t*2‘n

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
