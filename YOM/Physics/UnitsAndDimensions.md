# Units and Dimensions:

## Introduction :


Humans conciousness allow us to observe thing and describe the world qualitatively and express then as 
"this is fast", "the object is heavy",or "its a long table", these statements only give qualitative
description and lack precision needed for science. 

**Quantitative descriptions** allows us to measure help in measurement, comparison, test and reproduce
anywhere.

To achieve this we use two tools:

- **Dimensions**: Tell us the *nature* of the physical quantity ( ex: length, time)
- **Units**: Tells the *standard of measurement being used (ex: meters, seconds, kelvin..)

Without Units & Dimensions numbers in science are meaningless, the *Units give Physical context* and
*Dimensions ensure the Physical logic* is consistent. 

> Units: An agreed upon standard to express the magnitude of a physical quantity. These are defined by
> International agreement ( like SI system )

> Dimension: A universal property of nature. Nature does not care how we measure things as units are human
> conventions chosen for convenience. 

=> changing units just changes numbers but not the physics.

### Science:

Science seeks Objectivity. 

Units and dimensions:
    * Remove ambiguity from language.
    * tie abstract numbers to real-world measurements. 
    * Ensure that scientific knowledge is testable and falsifiable. 

They turn Observations => Laws.
Experiments in to => Evidence.
Mathematics into => Physics.

Units & Dimensions: Is the bridge between mathematics and physical world. Science would collapse without
them in to meaningless numbers. 



## Fundamental and Derived Quantities:

Unit is the standard, its used to measure the magnitude of a physical quantity. 

Math:

In mathematics a 'base' is a fundamental reference set from which all other related quantities are defined
or constructed. 

Example: Linear Algebra and Programming:

Base is the set of elements from which you can built everything else:

Linear Algebra:  2D space:
   Vector $(1,0)$ and $(0,1)$

Forms a basis of the 2D plane:

   Any vector $(i,j)$ can be written as :
       $(i,j) = i(1,0) + j(0,1)$

   So (1,0) and (0,1) are the base vectors and you can construct every vector, in the plane.

### 1. Fundamental quantities: 

Quantities that are independent of others. And all other quantities can be expressed in terms of the 
fundamental quantities.

When we classify measured units, they can be classified into two groups fundamental quantities and derived
quantities. 

Fundamental units are those that can not be expressed in terms of other, i.e Mass cannot define using Time
or Length using Temperature. 

=> In measurements a 'base units' are fundamental units that are independent and cannot be expressed in
terms of other units. There are limited number of these base units. It turns out the number of Fundamental 
Quantities are 7 and ( two supplementary units : Plane angle and solid angle )

Note: 
    SI units are the internationally agreed standard units used in science, engineering, and technology to 
    ensure uniform and consistent measurements worldwide. 

7 SI base units are :

- Length    : meter (m) 
    1 m = length that makes speed of light in vacuum = 299792458 when expressed in m/s. 

- Mass      : kilogram  (kg)
    1 Kg = mass that makes planks constant (h = 6.62607015 J.s which is kg.m^2/s ) 

- Time      : seconds (s)
    1 second = time that makes the unperturbed ground state hyperfine transition frequency Cs atom to be
    9192631770 when expressed in the unit Hz which is equal to 1/s. 

- Electric Current : ampere (A)
    1 ampere is the current which makes the elementary charge "e" to be 1.602176634 x 10^-19 when expressed
    in the unit C which is equal to A.s

- Thermodynamic Temperature: kelvin (K):
    kelvin is the temperature that makes the Boltzmann constant to  be 1.380649 x 10^-23 when J/K which is 
    equal to expressed in the unit kg. m^2 . s^2 / k.

- Amount of Substance: mole (mol)
    1 mole of a substance = 6.02214076 X 10^23 elementary entities. ( Avogadro constant N_A, When expressed 
    in the unit mol^-1 is called Avagadro number. 
    
- Luminous Intensity: candela (cd)
    SI unit of luminous intensity.

    luminous intensity that makes the luminous efficacy of monochromatic radiation of frequency 540x10^12 Hz,
    Kcd to be 683 when expressed in unit lm.W which is equal to cd.sr.kg^-1.m^2.s^3.

Supplementary Units:

- Plane angle: units radians (rad). This is the regular angle. ( 2-D )

- Solid Angle: units steradian (sr). A 3-D angle, which defines a solid angle subtended at the center of a
  sphere by a surface area equal to the square of the spheres radius. 

    1 sr = covers a cone-shaped area on a sphere's surface that is equal to r^2.

    ( Total Sphere: A complete sphere has a total solid angle of 4𝜋 steradians, which is approximately
    12.57 sr )


#### Standard Unit: 

Should have two properties: 
1. A standard unit must be invariable. 
2. Availability: standard unit should easily made available for comparing with other quantities. 

### 2. Derived SI units

Derived units are formed by combining base units. ( multiplication or division )

Example: 

- Velocity → m/s

- Force → newton $N = kg·m·s^{-2}$

- Energy → joule $J = kg·m^2·s^{-2}$

- Pressure → pascal $Pa = N/m^2$



#### SI prefixes:

Magnitude of physical quantities vary over  a wide range. The SI CGMP group recommendation standard
prefixes for certain powers:

Multiples (positive powers of 10)
| Power of 10 | Prefix | Symbol |
| ----------- | ------ | ------ |
| 10¹         | deca   | da     |
| 10²         | hecto  | h      |
| 10³         | kilo   | k      |
| 10⁶         | mega   | M      |
| 10⁹         | giga   | G      |
| 10¹²        | tera   | T      |
| 10¹⁵        | peta   | P      |
| 10¹⁸        | exa    | E      |
| 10²¹        | zetta  | Z      |
| 10²⁴        | yotta  | Y      |
| 10²⁷        | ronna  | R      |
| 10³⁰        | quetta | Q      |


Submultiples ( negative powers of 10)
| Power of 10 | Prefix | Symbol |
| ----------- | ------ | ------ |
| 10⁻¹        | deci   | d      |
| 10⁻²        | centi  | c      |
| 10⁻³        | milli  | m      |
| 10⁻⁶        | micro  | µ      |
| 10⁻⁹        | nano   | n      |
| 10⁻¹²       | pico   | p      |
| 10⁻¹⁵       | femto  | f      |
| 10⁻¹⁸       | atto   | a      |
| 10⁻²¹       | zepto  | z      |
| 10⁻²⁴       | yocto  | y      |
| 10⁻²⁷       | ronto  | r      |
| 10⁻³⁰       | quecto | q      |

## Dimensions of Physical quantities: 

Dimensions of a physical quantity tells us the nature of that quantity in terms of fundamental quantities.

Dimensions express a physical quantity as a product or powers of fundamental quantities like mass, length,
and time.

They are written using symbols:

- Mass → **[M]**

- Length → **[L]**

- Time → **[T]**

- Electric current → **[I]**

- Temperature → **[Θ]**  
( Note temp has 2 related concepts: physical quantity and its units. In dimensional analysis we express the
nature of quantity using dimensions not units. here **[Θ]** is just symbol of temperature not units.

- Amount of substance → **[N]**

- Luminous intensity → **[J]**

---

### Dimensional formula

> **The dimensional formula of a physical quantity is the expression that shows how it depends on fundamental quantities.**

Example:

* $Velocity → ([L T^{-1}])$
* $Force → ([M L T^{-2}])$

---

### How to derive dimensional formulas

The general method is always the same.

---

#### Step-by-step method

1. **Write the defining equation** of the physical quantity.
2. **Replace each quantity** in the equation with its dimensional formula.
3. **Simplify** using laws of indices.
4. **Write the final dimensional formula**.

---

#### Example 1: Velocity

Definition:
$$
\text{Velocity} = \frac{\text{distance}}{\text{time}}
$$

Dimensions:
$$
[v] = \frac{[L]}{[T]} = [L T^{-1}]
$$

---

#### Example 2: Acceleration

Definition:
$$
\text{Acceleration} = \frac{\text{change in velocity}}{\text{time}}
$$

$$
[a] = \frac{[L T^{-1}]}{[T]} = [L T^{-2}]
$$

---

#### Example 3: Force

Using Newton’s second law:
$$
F = ma
$$

$$
[F] = [M][L T^{-2}] = [M L T^{-2}]
$$

---

#### Example 4: Pressure

Definition:
$$
\text{Pressure} = \frac{\text{Force}}{\text{Area}}
$$

$$
[P] = \frac{[M L T^{-2}]}{[L^2]} = [M L^{-1} T^{-2}]
$$

---

### Important rules to remember

* Only **fundamental quantities** appear in dimensional formulas.
* Numerical constants (2, π, ½) have **no dimensions**.
* Functions like sin, cos, exp, log take **dimensionless arguments**.
* => Dimensions on both sides of a physical equation must be the same. <=

---

> **Dimensional formulas are derived by expressing a physical quantity in terms of fundamental quantities 
  using its defining equation.**

Note: 

In computational physics, certain "packages" of dimensions appear constantly. 
Understanding these helps you debug equations at a glance.


| Quantity | Relation | Dimensional Formula | Key Insight |
| --- | --- | --- | --- |
| **Work / Energy** | Force  Distance |  | All forms of energy (Heat, Kinetic, Potential) have the same "type." |
| **Pressure / Stress** | Force / Area |  | In code, Pressure and Energy Density have identical dimensions. |
| **Power** | Energy / Time |  | The "Bitrate" of energy. |
| **Frequency** | 1 / Time |  | Dimensions of "Hertz." Used in signal processing. |

---

### The Coding Perspective: Dimensional Signatures

When a programmer builds a physics engine, they often assign a **"Dimensional Signature"** to variables. 
This is a bit-vector representing the powers of  and .

For example, Force  could be represented as an array or struct:

`Force_Signature = {M: 1, L: 1, T: -2}`

**Why this is useful:**
If your code tries to calculate `Force + Energy`, the program looks at the signatures:

* `Force: {1, 1, -2}`
* `Energy: {1, 2, -2}`
The computer sees the `L` power doesn't match and throws a **Type Error** before the code even runs. 
This prevents physical impossibilities from being simulated.

---

### Constants with Dimensions

Not all constants are just numbers like . Some have "units" because they act as **Translators** between
different dimensions.

* **Universal Gravitational Constant ():**
From , we derive .
Dimensions: .
* **In STEM:**  is the "scaling factor" that tells the universe how much "Curvature of Space" (Length) you get for a certain amount of "Mass."

---

### Summary for Students

* **For JEE:** You must memorize the common formulas and be fast at algebraic simplification.
* **For STEM/Computing:** You treat dimensions as **Metadata**. 
  They tell you what the data *represents*, ensuring that your algorithms obey the laws of physics.

---

## Principle of Homogeneity: ( Golden rule )

Def:
    Principle of Homogeneity states that in a physically meaningful equation, all terms must have the same
    dimensions. 


=> If the dimensions don't match the equation is physically meaningless.
i.e You can **add** or **equate** quantities that are dimensionally the same.

In the world of Science and SW architecture, the **Principle of Homogeneity** is the ultimate validation
logic. It is the physical equivalent of **Type Checking** in programming. 

---

### 1. The Rule: "Like Adds to Like"

Homogeneity states that **the dimensions of each term of a physical equation must be the same.**

You can add 5 m to 10 m, but you can never add 5 m to 10 kgs. 
If you see an equation like , then mathematically:

> **The "Code" Reality:** In a physics engine, if you try to execute `total = distance + mass`, the 
  compiler should throw an error. 
  This principle is the "unit test" that ensures your equation isn't nonsense.

---

### 2. Transcendental Functions (The Dimensionless Trap)

This is a critical nuance for both JEE and high-level computation. 
Arguments of logarithmic, exponential, and trigonometric functions **must be dimensionless**.

Consider the wave equation: 
$y = A \sin(\omega t - kx)$

* The term $(\omega t - kx)$ is an angle.
* Angles are ratios (Arc/Radius), so they have no dimensions $[M^0L^0T^0]$.
* Therefore, $[\omega t]$ must be $[1]$. This tells us $[\omega] = [T^{-1}]$.
* Similarly, $[kx]$ must be $[1]$, so $[k] = [L^{-1}]$.

---

### 3. Application: Solving for the Unknown

In STEM, we often encounter "Black Box" constants in empirical formulas. 
We use homogeneity to "extract" what those constants actually represent.

Example: Van der Waals Equation (Real Gas Law) 
    $(P + \frac{a}{V^2})(V - b) = RT$


Where $P$ is pressure and $V$ is volume. What are the dimensions of $a$?

- According to the principle, you can only add $\frac{a}{V^2}$ to $P$ if they have the same dimensions.
- $[P] = [\frac{a}{V^2}]$
- $[ML^{-1}T^{-2}] = \frac{[a]}{[L^3]^2} \implies [a] = [ML^5T^{-2}]$


### 4. Computational Efficiency: Nondimensionalization

For a STEM student or programmer, the Principle of Homogeneity allows for a technique called 
**Nondimensionalization**.

By dividing an equation by a combination of characteristic constants (like the total length $L_0$ or max 
velocity $V_0$), you can turn an equation into a "Pure Number" version.

**Why do this?**

1. **Generalization:** A single simulation of a "Nondimensional Pipe" can describe fluid flow in a tiny 
   medical needle AND a massive oil pipeline.
2. **Stability:** It prevents the computer from dealing with units that have vastly different magnitudes 
  (e.g.,  $10^{-9}$ meters vs $10^6$ ), which keeps the math "numerically stable."

---

### 5. Summary Table

| Feature | JEE Exam Perspective | STEM / Programmer Perspective |
| --- | --- | --- |
| **Primary Use** | Solving for exponents in  problems. | Writing "Unit Tests" for mathematical models. |
| **Addition/Subtraction** | Terms must match dimensions. | **Type Safety:** Preventing "Apple + Orange" logic errors. |
| **Trig/Log Functions** | Their arguments are always dimensionless. | Ensuring inputs are "normalized" before processing. |

---

## Dimensional Analysis:

Dimensional analysis uses the dimensions of physical quantities to solve problems, check formulas, and
understand relationships.

Allows you to guess how the world works without even knowing the full physics yet.

---

### **1. Checking correctness of equations**

* **Golden Rule:** All terms in a physically meaningful equation must have the **same dimensions**.

* This helps **catch mistakes** in formulas before doing calculations.


**Example 1: Correct equation**
$s = ut + \frac{1}{2} a t^2$

* $s → [L]$
* $ut → [L]$
* $at^2 → [L]$

✔ Homogeneous → correct

**Example 2: Incorrect equation**

- $s = ut + at$
    * $at → [L/T] × [T] = [L/T]$ ❌
    → Not dimensionally consistent → formula is wrong

---

### **2. Converting units**

* Dimensional formulas help convert **derived units** without memorizing formulas.
* **Example:** Convert velocity from km/h to m/s

$$
v = 90 \text{ km/h} \times \frac{1000 \text{ m}}{1 \text{ km}} \times \frac{1 \text{ h}}{3600 \text{ s}} = 25 \text{ m/s}
$$

* By knowing **[L T⁻¹]**, you can check that your conversion is dimensionally consistent.

---

### **3. Deriving relations between physical quantities**

* Many physical relationships can be guessed using **dimensions alone**, up to a **dimensionless constant**.

**Example: Period of a simple pendulum**

Assume $T$ depends on:

* length $l → [L]$
* acceleration due to gravity (g) → $[LT^{-2}]$

Assume:
$$
T \propto l^a g^b
$$

* Dimensions:
  $[T] = [L]^a [L T^{-2}]^b = [L]^{a+b} [T]^{-2b}$

* Compare powers:
  $[T^1] = [L]^{a+b} [T]^{-2b}$ →

* For $[T]$: $-2b = 1 \implies b = -\frac{1}{2}$

* For $[L]$: $a+b=0 \implies a = \frac{1}{2}$

   $\therefore T \propto \sqrt{\frac{l}{g}}$

* Constant factor $2\pi$ cannot be found by dimensional analysis.

---

### **Other Applications**

1. **Checking derived units** (like force, pressure, energy)
2. **Estimating magnitudes of physical quantities**
3. **Scaling laws in physics and engineering**
4. **Simplifying experimental data and modeling** (using dimensionless numbers like Reynolds number)

---

### **Summary Table**

| Application          | How it works                                       | Example                          |
| -------------------- | -------------------------------------------------- | -------------------------------- |
| Checking correctness | Ensure all terms have same dimensions              | $s = ut + \frac{1}{2} at^2$ ✅    |
| Converting units     | Use dimensions to verify conversion                | Velocity $[LT^{-1}]$: $km/h → m/s$     |
| Deriving relations   | Express unknown as product of powers of quantities | Pendulum: $T \propto \sqrt{l/g}$ |

---

## Limitations of Dimensional Analysis

Dimensional Analysis is powerful but it has inherent limitations.
It can guide and check but it can not replace full physics, i.e it does'nt understand the soul of the
physics.

### Limitations:

1. Cannot determine dimensionless constants.

* Dimensional analysis gives relations **up to a multiplicative constant**, but it cannot find **pure numbers** like π, 2, or 9.8.

**Example:** Period of a pendulum
$$
T \propto \sqrt{\frac{l}{g}}
$$

* Dimensional analysis cannot give the exact formula:
  $$
  T = 2\pi \sqrt{\frac{l}{g}}
  $$

* The $2\pi$ factor is **dimensionless** → invisible to dimensions.

2. Cannot handle dimensionless quantities or ratios

* Quantities like angles, coefficients of friction, refractive index, and Reynolds number are **dimensionless**.
* Dimensional analysis **cannot predict their numerical values**.

**Example:**

* Angle $θ$ in radians → $[Θ]/[Θ]$ = 1 → dimensionless
* Dimensional analysis cannot tell you that $sin(θ)$ appears in an equation.

3. Cannot distinguish between different functions of the same dimensions

* Equations like $y = \sin(x)$ or $y = x$ are dimensionally consistent if $x$ is dimensionless, 
  but the **functional form** cannot be guessed.

**Example:**

* $s = l \sin(\theta)$ → dimensionally [L] = [L] × 1 ✅
* Dimensional analysis cannot tell that $\sin$ is involved.

---

4. Cannot differentiate between physically different quantities with same dimensions

* Different physical quantities may have the **same dimensional formula**, so dimensional analysis cannot 
  distinguish them.

**Example:**

* Torque and energy → both [M L² T⁻²]
* Dimensional analysis cannot tell which is which.

---

5. Cannot handle constants with dimensions derived from other constants

* Some formulas involve **fundamental constants** like Planck’s (h) or the gravitational (G) constants.
* While dimensional analysis can include them, it **cannot fully derive equations** without additional physics.

---

### ✅ Summary of Limitations

| Limitation                                                  | Why it happens               | Example                         |
| ----------------------------------------------------------- | ---------------------------- | ------------------------------- |
| Cannot find dimensionless constants                         | They have no dimensions      | Pendulum: $2\pi$ factor             |
| Cannot handle dimensionless quantities                      | No dimensions to work with   | Angles, refractive index        |
| Cannot determine functional form                            | Many functions dimensionless | $sin(x), exp(x), log(x)$          |
| Cannot distinguish quantities with same dimensions          | Only dimensions considered   | Torque vs energy                |
| Cannot fully derive constants involving universal constants | Requires physical law        | $F = G m₁.m₂/r²$ (G must be known) |

---

### Exam-friendly one-liner

> **Dimensional analysis cannot give dimensionless constants, functional forms, or distinguish quantities with the same dimensions; it guides but does not replace full physics.**

| **Aspect**                             | **Applications (What it can do)**               | **Limitations (Where it fails)**                   | **Example**                                              |
| -------------------------------------- | ----------------------------------------------- | -------------------------------------------------- | -------------------------------------------------------- |
| **Check correctness of equations**     | Ensures all terms have same dimensions          | Cannot detect dimensionless constants              | $s = ut + \frac{1}{2} at^2$ ✅ vs wrong: $s = ut + at$ ❌  |
| **Unit conversion**                    | Helps verify conversions of derived units       | Cannot handle purely dimensionless quantities      | Velocity: $km/h → m/s$ ✅                                   |
| **Derive relationships**               | Can predict how quantities depend on each other | Cannot determine exact numerical factors           | Pendulum: $T \propto \sqrt{l/g}$, missing $2\pi$         |
| **Estimate magnitudes & scaling laws** | Helps in dimensional scaling                    | Cannot find functional forms (sin, log, exp)       | $s = l \sin\theta$ – dimensional analysis sees [L] = [L] |
| **Simplify experimental analysis**     | Guides experiments & predicts trends            | Cannot distinguish quantities with same dimensions | Torque [M L² T⁻²] vs Energy [M L² T⁻²]                   |
