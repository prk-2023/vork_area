# Dimensional Analysis:

In AP Physics (1, 2, and C), dimensional analysis is rarely tested as a simple unit-conversion exercise.
Instead, it is used to verify complex symbolic derivations, deduce unknown relationships between physical
variables, and determine the units of empirical constants.

Part 1: AP Physics Dimensional Analysis Study Guide


1. Core Principles for the AP Exam

- Principle of Dimensional Homogeneity: Every term added or subtracted in a valid physical equation must
  have the exact same dimensions. If \(A = B + C\), then \([A] = [B] = [C]\).
- Transcendental Functions Rule: The arguments inside trigonometric (\(\sin, \cos, \tan\)), exponential
  (\(e^{x}\)), and logarithmic (\(\ln x\)) functions must be completely dimensionless (\([M^0 L^0 T^0]\)).
  The output of these functions is also dimensionless.
- Eliminating Multiple-Choice Distractors: On symbolic AP multiple-choice questions, you can often eliminate
  2 or 3 wrong answers immediately by checking if the variables on the right-hand side combine to match the
  target dimension on the left-hand side.

2. Essential Mechanics & E&M Dimensions Reference


| Quantity  | Formula | Dimensions	| SI Units|
| :--- | :--- | :--- | :--- |
| Force $F$ | $ma$ | $[M  L T^{-2}]$	| $\text{N} . \text{kg} . {m/s}^2$ |
Energy / Work (\(E, W\))	\(Fd\)	\([M L^2 T^{-2}]\)	\(\text{J}\) (\(\text{N}\cdot\text{m}\))
Power (\(P\))	\(W/t\)	\([M L^2 T^{-3}]\)	\(\text{W}\) (\(\text{J/s}\))
Pressure (\(P\))	\(F/A\)	\([M L^{-1} T^{-2}]\)	\(\text{Pa}\) (\(\text{N/m}^{2}\))
Angular Momentum (\(L\))	\(mvr\)	\([M L^2 T^{-1}]\)	\(\text{kg}\cdot\text{m}^2/\text{s}\)
Universal Grav. Constant (\(G\))	\(Fr^2 / m_1m_2\)	\([M^{-1} L^3 T^{-2}]\)	\(\text{N}\cdot\text{m}^2/\text{kg}^2\)
Spring Constant (\(k\))	\(F/x\)	\([M T^{-2}]\)	\(\text{N/m}\)


Part 2: Harder AP-Style Practice Questions


Question 1: Deducing an Equation (Rayleigh's Method)

When a small sphere of radius \(r\) moves at a slow speed \(v\) through a viscous fluid, it experiences a drag force \(F_{d}\). The drag force depends only on the radius \(r\), the speed \(v\), and the dynamic viscosity \(\eta \) of the fluid (where viscosity has dimensions \([\eta] = [M L^{-1} T^{-1}]\)).
Using dimensional analysis, determine the proportional relationship for the drag force \(F_{d}\) in terms of \(\eta \), \(r\), and \(v\).
• A) \(F_d \propto \eta r^2 v\)
• B) \(F_d \propto \eta r v\)
• C) \(F_d \propto \eta^2 r v\)
• D) \(F_d \propto \frac{\eta v}{r}\)

Question 2: Transcendental Functions & Non-Standard Variables

The position \(x\) of a damped oscillator as a function of time \(t\) is modeled by the equation:
\(x(t)=\frac{A}{\beta }\left(1-e^{-\beta t}\right)\cos (\omega t+\phi )\)
where \(x\) is in meters and \(t\) is in seconds. What are the dimensions of the constant \(A\)?
• A) \([L]\)
• B) \([L T^{-1}]\)
• C) \([L T^{-2}]\)
• D) \([M L T^{-1}]\)

Question 3: AP-Style Symbolic Elimination (Electrostatics)

Two small spheres, each with mass \(m\) and positive charge \(q\), are suspended from a common point by two insulating strings of length \(L\). Each string makes an angle \(\theta \) with the vertical in static equilibrium. Using dimensional analysis (without necessarily solving the free-body diagram), which of the following expressions correctly represents the mass \(m\) of each sphere in terms of \(L\), \(q\), \(\theta \), the gravitational field \(g\), and Coulomb's constant \(k\) (where \(F_E = \frac{kq^2}{r^2}\))?
• A) \(m = \frac{4gL^2 \sin^2 \theta \tan \theta}{kq}\)
• B) \(m = \frac{kq}{4gL^2 \sin^2 \theta \tan \theta}\)
• C) \(m = \frac{4gL^2 \sin^2 \theta \tan \theta}{kq^2}\)
• D) \(m = \frac{kq^2}{4gL^2 \sin^2 \theta \tan \theta}\)

Question 4: Changing the Fundamental Base Dimensions (Challenge)

Suppose a student invents a new system of units where Force (\(F\)), Velocity (\(V\)), and Time (\(T\)) are chosen as the three fundamental base dimensions instead of Mass, Length, and Time. What is the dimensional formula for Energy (\(E\)) and Density (\(\rho \)) in this new system?
• A) \([E] = [F V T]\), \([\rho] = [F V^{-4} T^{-2}]\)
• B) \([E] = [F V T^{-1}]\), \([\rho] = [F V^{-3} T^{-2}]\)
• C) \([E] = [F V^2 T]\), \([\rho] = [F V^{-4} T^{-1}]\)
• D) \([E] = [F V T]\), \([\rho] = [F V^{-2} T^{-4}]\)

Part 3: Step-by-Step Solutions


Solution to Question 1: B

1. Set up the dimensional equation with unknown exponents:
\([F_{d}]=[\eta ]^{a}[r]^{b}[v]^{c}\)
2. Substitute the dimensions of each variable:
\([M^{1}L^{1}T^{-2}]=[ML^{-1}T^{-1}]^{a}[L]^{b}[LT^{-1}]^{c}\)
\([M^{1}L^{1}T^{-2}]=[M^{a}L^{-a+b+c}T^{-a-c}]\)
3. Match the exponents for each fundamental dimension:
	• For \(M\): \(a = 1\)
	• For \(T\): \(-a - c = -2 \implies -1 - c = -2 \implies c = 1\)
	• For \(L\): \(-a + b + c = 1 \implies -1 + b + 1 = 1 \implies b = 1\)
4. Thus, \(F_d \propto \eta^1 r^1 v^1 = \eta r v\) (which is Stokes' Law).

Solution to Question 2: B

1. The argument of the exponential function (\(-\beta t\)) must be dimensionless:
\([\beta ][t]=[1]\implies [\beta ]=[T^{-1}]\)
2. The terms \((1 - e^{-\beta t})\) and \(\cos(\omega t + \phi)\) are both dimensionless.
3. Therefore, the dimensions of \(x(t)\) must equal the dimensions of \(\frac{A}{\beta }\):
\([x]=\frac{[A]}{[\beta ]}\implies [L]=\frac{[A]}{[T^{-1}]}\)
4. Solve for \([A]\):
\([A]=[LT^{-1}]\)

Solution to Question 3: D

1. From Coulomb's Law, \(F_E = \frac{kq^2}{r^2}\), we know the term \(kq^{2}\) has dimensions of \(\text{Force} \times \text{Length}^2\):
\([kq^{2}]=[F][L^{2}]\)
2. Trigonometric functions (\(\sin^2\theta \tan\theta\)) are dimensionless.
3. Let's check the dimensions of Option D:
\(\left[\frac{kq^{2}}{gL^{2}}\right]=\frac{[F][L^{2}]}{[a][L^{2}]}=\frac{[F]}{[a]}\)
4. Since \(F = ma\), \(\frac{[F]}{[a]} = [M]\), which matches the dimension of mass \(m\). (Options A and B only have \(q^{1}\), and Option C inverts the fraction, giving \([M^{-1}]\)).

Solution to Question 4: A

1. For Energy (\(E\)): Energy is Work (\(F \cdot d\)), and distance \(d = V \cdot T\).
\([E]=[F][d]=[F][V][T]=[FVT]\)
2. For Density (\(\rho \)): Density is \(\frac{\text{Mass}}{\text{Volume}} = \frac{M}{L^3}\).
	• Express \(M\) using \(F = ma = m \frac{V}{T} \implies [M] = [F V^{-1} T]\).
	• Express \(L^{3}\) using \(L = V T \implies [L^3] = [V^3 T^3]\).
	• Divide \([M]\) by \([L^3]\):
\([\rho ]=\frac{[FV^{-1}T]}{[V^{3}T^{3}]}=[FV^{-4}T^{-2}]\)
Would you like more AP Physics C calculus-based dimensional problems (involving integrals and differential equations), or a set of AP Physics 1 experimental design questions using dimensional analysis?


---

1. (d)

Suppose a quantity x can be dimensionally represented in terms of $M$, $L$, $T$,   
such that $[x] =  M^a * L^b *  T^c$, the quantity $M$ can:  

a. can always be dimensionally represented in terms of L, T and x
b. can never be dimensoinally represented in terms of L, T and x
c. may be represented in terms of L, T and x if a = 0
d. may be represented in terms of L, T and x if a $\neq$ 0.

Reason:   
Rearranging the other tearms to express $M$ as:
$$M=[x]^{\frac{1}{a}}\cdot L^{-\frac{b}{a}}\cdot T^{-\frac{c}{a}}$$  
  
If a $\neq$ 0 then fraction $1/a$ is mathematically defined and M can be written in terms of x, L, T. 
  
When $a = 0$ the division $\frac{1}{a}$ is undefined, physically if $a = 0$ the quantity x is not dependent on Mass at all.


2. 
For a dimensionless quantity:

i.   Never has a unit, 
ii.  Always has a unit,
iii. May have a unit, 
iv,  Does not exist.

A dimensional quantity always has units. 
In fact, having a physical dimension is the exact reason a quantity requires a unit to express its measurement.

Note: Unit less quantity: A number 

Most unit less quantities come from dividing two physical quantities that have the exact same units. 
Because the units are identical, they cancel each other out.

Examples: 
Refractive Index ( ratio of speed of light in vacuum $\frac{m}{s}$ )
Coefficient of Friction: Its the ratio of force of friction (N) to normal force (N), $\mu$ this is a unit-less 
number that measures how much grip or resistance exists between two surfaces sliding or trying to slide
against each other.

A low $\mu$ : ( close to 0 ) == Surface is very slippery ( ice ) 
a High $\mu$ : ( greater than 1 ) means the surface has a lot of grip ( rubber tiers ) 

Formula : is a ratio of the frictional force between two objects to the force pressing them together. 
$$
\mu =\frac{F_{f}}{N}
$$
• $\mu$ : Coefficient of friction (unitless).
• $F_{f}$: Force of friction, measured in Newtons \text{N}.
• $N$: Normal force (the perpendicular force pressing the two surfaces together, usually equal to the object's 
weight on a flat surface), measured in Newtons $\text{N}$.

