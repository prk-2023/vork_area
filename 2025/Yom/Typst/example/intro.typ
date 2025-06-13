#set page(width: 10cm, height: auto)
#set heading(numbering: "1.")

#line(length: 100%)
#line(end: (50%, 50%))
#line(
  length: 4cm,
  stroke: 2pt + maroon,
)
= Sequences:

== Fibonacci Sequence 

The Fibonacci Sequence is defined through the recurrence relation $F_n = F_(n-1)+F_(n-2)$. It can also be
expressed in _closed form:_ 

$ F_n = round(1/sqrt(5) phi.alt^n), quad phi.alt = (1+sqrt(5))/2 $


#let count = 8
#let nums = range(1, count+1)
#let fib(n) = ( 
    if n <= 2 {1}
    else { fib(n - 1) + fib(n - 2) }
)

The first #count numbers of the sequence are:

#align(center, table(
    columns: count,
    ..nums.map(n => $F_#n$),
    ..nums.map(n => str(fib(n))),
))


$ binom(n, k_1, k_2, k_3, ..., k_m) $

Here, we can simplify:
$ (a dot b dot cancel(x)) /
    cancel(x) $


#line(length: 100%)
$ f(x, y) := cases(
  1 "if" (x dot y)/2 <= 0,
  2 "if" x "is even",
  3 "if" x in NN,
  4 "else",
) $
#line(length: 10cm, stroke: 2pt + green )
