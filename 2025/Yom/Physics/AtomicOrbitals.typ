#let fancybold(varna, body) = {
  text(fill: varna, font:"Droid Sans", style: "italic", weight: "semibold", body)
  //text(fill: varna, font: "Fira Math",style: "italic" ,weight: "bold", body)
  //text(fill: varna, font:"Libertinus Math", style: "italic", weight: "semibold", body)
  //text(fill: varna, font: "Fira Math", style: "italic" , weight: "semibold", body)
}

#set document(title: "Atomic Orbitals") // 1. Defines the document title
//#set page(
//  margin: (top: 1.5in, bottom: 1in, left: 1in, right: 1in), // Optional: Set page margins
//)
#set text(font: "Droid Sans",weight: "medium" ) // Optional: Set font and justification
//#set text(font: "DejaVu Sans Mono", weight: "medium")
//#set text(font: "Fira Code Retina")

//#set text(font: "ComicShannsMono Nerd Font Mono", justify: true) // Optional: Set font and justification

// --- Chapter Title Section ---
#align(center)[ // Center the main chapter title
  #text(2.0em, weight: 650, "Atomic Orbitals") // Larger, bolder title
]

#v(1em) // Add some vertical space

// --- Table of Contents Section ---
#line(length: 100%, stroke: (paint: blue, thickness: 1pt)) // A subtle line before the TOC
#outline() // Generates the table of contents
#line(length: 100%, stroke: (paint: blue, thickness: 1pt)) // A subtle line after the TOC

#pagebreak() // Start the actual chapter content on a new page

// --- Chapter Content Settings ---
#set heading(numbering: "1.") // Set heading numbering for the chapter
#show outline.entry: it => link( // Custom styling for outline entries (clickable)
  it.element.location(),
  it.indented(it.prefix(), it.body()),
)

// Your chapter content would follow here, starting with your first heading:
// #heading(level: 1, "Introduction")
// #heading(level: 2, "Background")
= Atomic Orbitals :

In quantum mechanics #fancybold(olive,"atomic orbitals") are mathematical functions that describe the
#fancybold(olive, "Probability Distribution") of an electron around a nucleus. 

These orbitals emerge as solutions to the #fancybold(olive, "Schrodingers equation") for atoms ( Hyderogen atom ).

//#underline( stroke: 1.5pt + red, offset: 2pt, "NOTE:")
#text(fill: orange , weight: "semibold", "NOTE:")
#line(length: 100%, stroke: (paint: green, thickness: 1.0pt))
  - Orbitals have nothing to do with the Old #fancybold(olive, "planetary model") where electrons are
    visualized as moving around the nucleus in fixed orbitals ( like planets ).

  - Instead, orbitals are math functions that describe the #fancybold(olive, "probability distribution") of
    finding an electron in a particular region of space. 

  - These emerge from the solution to the #fancybold(olive, "Schrodingers equation") and reflect the
    #fancybold(olive, "wave nature") of electron, not a physical path or orbit.

  This clarification is important as moving from mental image of Bohr model, which is useful but inaccurate
  in modern Quantum Mechanics. 

  The Quantum model treats electrons as #fancybold(olive, "wave like entities") , and orbitals are just 
  regions where the electron is #fancybold(olive, "most likely to be found") and not where it travels.
#line(length: 100%, stroke: (paint: green, thickness: 1.0pt))


== Wave Function: 
#linebreak()
In Quantum mechanics, the $"wavefunction :" psi(r, theta, phi)$ describes the quantum state of an electron 
in an atom. 

Each orbital is associated with a #fancybold(olive , "wavefunction"), which contains all the information 
about the electron's behavior in an atom.

For this the wavefunction depends on #fancybold(olive, "three variables") because atoms are naturally
described in #fancybold(olive, "spherical co-ordinates")

- *#fancybold(red, "r ") :* radial distance from the nucleus
- *#fancybold(red, $theta$ ) :* polar angle (0 to $pi$)
- *#fancybold(red, $phi$ )   :* azimuthal angle (0 to $2pi$)

In quantum mechanics, the #fancybold(olive, "wave function"), $psi(r, theta, phi, t)$") (or $psi(r, theta, phi)$ 
for stationary states, often simply referred to as $psi$ ), is the central mathematical entity that 
#fancybold(olive, "completely describes the quantum state of an electron (or any particle) in an atom").

- #fancybold(black, "Each orbital is associated with a unique wave function.") #linebreak() 
When we talk about the "1s orbital," the "2p orbital," etc., we are fundamentally referring to the specific 
mathematical form of the wave function that describes the electron in that particular state, characterized 
by its quantum numbers (* #fancybold(red, $n, l, m_l$ ) *).

#pagebreak()
- #fancybold(black, "The wave function contains all the information about the electron's behavior.")
  #linebreak()
While it doesn't give a precise trajectory (as in classical mechanics), it allows us to calculate the
following: 

#linebreak()
    - #fancybold(olive, "Probability Distribution:") The square of the absolute value of the wave function,
      $|psi|^2$, gives the probability density of finding the electron at a particular point in space.
      This is how we get the "electron cloud" picture of orbitals.
#linebreak()
    - #fancybold(olive, "Energy:") By applying the Hamiltonian operator to the wave function (as in the
      Schrödinger equation), we can determine the allowed energy levels of the electron.
#linebreak()
    - #fancybold(olive, "Angular Momentum:") The wave function also contains information about the
      electron's angular momentum.
#linebreak()
    - #fancybold(olive, "Other Measurable Properties:") In principle, any measurable property of the
      electron in that state can be derived from its wave function using appropriate quantum mechanical 
      operators.

So, when we delve into the quantum mechanical model of the atom, thinking of the "orbital" as synonymous 
with its specific "#fancybold(red, "wave function")" is a very accurate and powerful way to understand it.

=== Eigenfunctions and Eigenvalues:
#linebreak()

Eigenfunctions and Eigenvalues are fundamental concepts in various fields of mathematics, physics, and 
engineering, particularly in linear algebra, differential equations, and quantum mechanics. 

The prefix "eigen-" derived from the German = "proper," "characteristic," or "own."
#linebreak()

1. The Core Idea: 

What happens when an "operator" acts on a "function"?

Imagine you have a *function* (ex: $f(x) = e^(a.x)$, or $g(x) = sin(k.x)$) and an *operator* 

(something that acts on the function, like differentiation $dif /(dif x)$ or taking the square *^2*).

Generally, when an operator acts on a function, it transforms it into a *different* function. 
For example:
  - If the operator is $dif /(dif x)$ and the function is $f(x) = x^2$, then $dif (x^2)/(dif x) = 2x$. 
    The function changed.
    However, for some special functions and some specific operators, something remarkable happens: 
    *the function doesn't change its fundamental form; it's merely scaled by a constant factor.*

This is the essence of an eigenfunction and eigenvalue.
#pagebreak()

2.  Definition: An *eigenvalue equation* is typically written as:

  $ 
  hat(L) f(x) = lambda f(x)
  $

Where:

- $hat(L)$  is a *linear operator*. An operator is a mathematical rule that transforms one function into
  another. In physics, operators often represent measurable physical quantities (observables) like energy, 
  momentum, or position.
#linebreak()
- $f(x)$ is the *eigenfunction*. This is the special, non-zero function that, when the operator $hat(L)$
  acts upon it, simply gets scaled by a constant factor. It retains its original form.
#linebreak()
- $lambda$ (lambda) is the *eigenvalue*. This is the constant scalar factor by which the eigenfunction is
  scaled. It's a numerical value.

*In simpler terms:* An eigenfunction is a function that, when operated on by a specific operator, only 
changes in magnitude (is scaled), not in its fundamental shape or "direction." 

The eigenvalue is the amount by which it is scaled.

3. Analogy with Eigenvectors and Eigenvalues (Linear Algebra)

The concept of eigenfunctions and eigenvalues is a generalization of *eigenvectors* and *eigenvalues* in 
linear algebra.

For a matrix $A$ and a vector $vec(v))$ , an eigenvalue equation looks like this:

$vec(v)$  = $lambda vec(v))$ 

Here

- $A$ is a square matrix (the linear operator).
- $vec(v))$ is an *eigenvector*. It's a special non-zero vector that, when transformed 
  by the matrix $A$, remains on the same line (i.e., its direction doesn't change), but its length might be 
  scaled.
- $lambda$ is the *eigenvalue*. It's the scalar factor by which the eigenvector $vec(v))$ is 
  stretched or shrunk.

Think of it geometrically: if you apply a transformation (like stretching, rotating, or shearing) to a bunch 
of vectors, most vectors will change both their length and direction. 
But eigenvectors are those special vectors that *only* change their length (or might reverse direction if 
$lambda$ is negative), staying along their original line.

Examples

A. Derivative Operator

Let's consider the operator $hat(L) = dif /(dif x)$ (the derivative).

- If $f(x) = x^2$, then $dif (x^2)/(dif x) = 2x$. Not an eigenfunction.
- If $f(x) = e^(a.x)$:
    $ dif (e^(a.x))/(dif x) = a e^(a.x)$
    Here, $e^(a.x)$ is the eigenfunction, and $a$ is the eigenvalue. The function $e^(a.x)$ kept its form, 
    it was just multiplied by $a$.

B. Quantum Mechanics (Schrödinger Equation)

This is where eigenfunctions and eigenvalues are incredibly important in physics. 
The time-independent Schrödinger equation is a famous eigenvalue equation:

$hat(H) psi = E psi$

Where:

- $hat(H)$ is the *Hamiltonian operator*, which represents the total energy of a quantum system (K.E + P.E).
- $psi$ (psi) is the *wavefunction*, which describes the quantum state of a particle (ex: an electron in an
  atom). In this context, the wavefunction $psi$ is an eigenfunction of the Hamiltonian.
- $E$ is the *energy eigenvalue*. These are the discrete, allowed energy levels that a quantum system can possess.

Significance in Quantum Mechanics:
- The *eigenfunctions* $psi$ tell you the spatial distribution and behavior of the particle for a given energy.
- The *eigenvalues*  $E$  tell you the *possible measurable values* of that physical quantity (energy in 
  this case). The fact that energy values are often discrete (quantized) comes directly from the eigenvalue 
  problem for bound systems.

C. Vibrating String

Imagine a vibrating string fixed at both ends. The different modes of vibration (the fundamental tone, the 
first overtone, etc.) are eigenfunctions of a wave operator. Each mode has a specific frequency, which would 
be the eigenvalue.

Key Takeaways:

- *Operator:* Something that acts on a function (or vector).

- *Eigenfunction (or Eigenvector):* A special function (or vector) that, when an operator acts on it, 
  doesn't change its fundamental form, only its magnitude. It points in its "own" characteristic direction.

- *Eigenvalue:* The scalar factor by which the eigenfunction (or eigenvector) is scaled. It represents the
  "characteristic" value associated with that eigenfunction and operator.

Eigenfunctions and eigenvalues provide a powerful framework for understanding the intrinsic properties and 
behaviors of systems across many scientific and mathematical disciplines.

#pagebreak()

== Understanding the Atomic Orbital Model

===  What Are Atomic Orbitals?

In quantum mechanics, *atomic orbitals* are mathematical functions that describe the *probability 
distribution* of an electron around a nucleus. 

These orbitals emerge as solutions to the *Schrödinger equation* for atoms, particularly the hydrogen atom.

Each orbital is associated with a *wavefunction* $psi(r, theta, phi)$, which contains all the information 
about the electron's behavior in an atom.

==== Wavefunctions as Eigenfunctions

In the atomic orbital model, the *wavefunction* $psi$ is an *eigenfunction* of the *Hamiltonian operator* 
(the total energy operator in quantum mechanics). 

This means:

$
hat(H) psi = E psi
$

Where:

- $hat(H)$ is the Hamiltonian (includes kinetic + potential energy),
- $psi$ is the wavefunction (describes the electron),
- $E$ is the energy (the *eigenvalue*).

So, an *eigenfunction* here is a function that, when operated on by $hat(H)$, yields the same function 
scaled by the energy value. This is the foundation for describing quantized energy levels and the structure 
of orbitals.

=== Wavefunction Structure: Radial and Angular Parts

The wavefunction for an electron in an atom can be *separated* into:

$
psi (r, theta, phi) = R(r) . Y(theta, phi)
$

- *$R(r)$*: The *radial part* — depends on the distance from the nucleus.
- *$Y(theta, phi)$*: The *angular part* — depends on direction and gives the shape and orientation of the 
  orbital.

These two parts define the shape, energy, and behavior of each orbital.

=== 🔳 Nodes: Where Electrons Cannot Be

*Nodes* are regions where the wavefunction equals zero, and therefore the *probability of finding an 
electron is zero*. 

There are two types:

1. *Radial Nodes*

- Occur at certain distances from the nucleus.
- Caused by zeros in the *radial function* $R(r)$.
- Appear as *spherical shells*.

2. *Angular Nodes*

- Occur due to the angular part $Y(theta, phi)$.
- Appear as *planes or cones* passing through the nucleus.
- Correspond to the shapes of *p, d, and f orbitals*.

#align(left, 
table(columns:2, align: (left),
[Node Count: ],[],
[ *Total nodes* in an orbital: ],[$n - 1$],
[ *Angular nodes* (from orbital shape):], [ $l$ ],
[ *Radial nodes* (from radial distance):], [ $n - l - 1$ ]),
)

Where:

- $n$ = principal quantum number,
- $l$ = angular momentum quantum number.

Examples:

- *2s orbital*:
  - $n = 2$, $l = 0$ → 1 radial node, 0 angular nodes
- *2p orbital*:
  -  $n = 2$, $l = 1$ → 0 radial nodes, 1 angular node
- *3d orbital*:
  - $n = 3$, $l = 2$ → 0 radial nodes, 2 angular nodes

=== Why It Matters
#linebreak()
- The number and type of nodes determine the *energy* and *shape* of orbitals.
- More nodes → higher energy.
- Angular nodes give orbitals their characteristic *shapes* (spherical for s, dumbbell for p, etc.).
- These concepts explain the *structure of the periodic table*, *chemical bonding*, and *spectroscopy*.

= Translate Wavefunctions to Orbital shapes:

How *wavefunctions*, their *nodes* and the resulting *orbital shapes* all connect:

1. 
  - Atomic orbitals are solutions to the Schrödinger equation for electrons in atoms. 
  - The full wavefunction for an electron in an atom is:
     $
      psi #sub[n, l, m] (r, theta, phi) = R #sub[n,l] (r) .  Y#sub[l]#super[m] (theta, phi)
$

This splits into:

- *Radial part*: $R #sub[n,l] (r)$ → affects how the wavefunction varies with distance from the nucleus.
- *Angular part*: $Y #sub[l] #super[m] (theta, phi)$ → gives shape in 3D space (orientation and symmetry).


== 🔳 How Nodes Affect Shape


1. *Radial Nodes → Spherical Shells*

- These are places where the *radial wavefunction $R(r) = 0$*.
- The electron density dips to zero at certain *distances* from the nucleus.
- *They don’t affect the angular shape*, just how many concentric regions there are.

2. *Angular Nodes → Planes or Cones*

- These come from the angular part $Y(theta, phi)$.
- They determine the *number of lobes* and the *symmetry*.

- For example:

  - *p orbitals* have 1 angular node → they look like dumbbells.
  - *d orbitals* have 2 angular nodes → more complex lobes and cloverleaf shapes.


== Plotting: How Orbital Shapes Are Made

To visualize an orbital:

Step 1: Compute the *Probability Density*

We plot:

$
 | psi #sub[n,m,l] (r, theta, phi) |^2 = |R #sub[n,l] (r)|^2  . |Y #sub[l] #super[m] (theta, phi)|^2
$

This gives the *electron density*, which tells us *where the electron is likely to be*.

Step 2: Convert to 3D Cartesian Coordinates

We switch from spherical coordinates $(r, theta, phi)$ to Cartesian $(x, y, z)$ for visualization:

#align(center, 
table(columns:1, align: (left),
  [ $x = r.sin(theta).cos(phi)$],
  [ $y = r.sin(theta).sin(phi)$],
  [ $z = r.cos(theta)$ ])
)

Then, we map the probability density onto a 3D grid and render surfaces of *constant probability density*.

Example: 2p Orbital

- $n = 2, l = 1, m = -1, 0, 1$
- Angular node: 1 (a plane through the nucleus — e.g., the xy-plane if it's the $p #sub[z]$ orbital)
- Radial nodes: 0 (no spherical shells where the density goes to zero)

The shape appears as *two lobes* on opposite sides of the nucleus (a dumbbell), with a *node at the nucleus*
(probability zero at the center).

Recap: How Shapes Arise

#table(columns:5,
  table.header[ *Component* ][ *Mathematical Origin* ][ *Shape Effect* ][ ][ ], 
  [ Radial nodes ],[ Zeroes in $R(r)$ ], [ Concentric spheres where density = 0  ],[       ],[    ],
  [ Angular nodes],[ Zeroes in $Y(theta,phi)$ ],[ Planes/cones → lobes and symmetry],[     ],[    ],
  [ Total probability ],[ ],[ $psi$ ],[ $psi ^2$  ],[ Defines the 3D orbital shape ]
)

== Python program for plotting 


Python script using *Matplotlib* and *NumPy* to plot atomic orbitals by computing and visualizing the 
squared wavefunctions $| psi #sub[n,l,m] |^2 $. 

This script will:

- Accept orbital quantum numbers: `n`, `l`, `m`
- Compute the spherical harmonics $Y#sub[l]#super[m] (theta, phi)  $
- Use a radial function approximation (simplified for visualization)
- Plot the *3D probability density* or *isosurface* using Matplotlib's `plot_surface` or a volumetric slice

=== Python Script to Plot Atomic Orbitals

This example uses `matplotlib`, `numpy`, and `scipy.special` for spherical harmonics.

> You can extend this later with more accurate radial functions, but this version shows *angular node 
structure* very clearly.

```python 
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d.axes3d import Axes3D
from scipy.special import sph_harm

def plot_orbital(n, l, m, resolution=100, r_max=1.0):
    theta = np.linspace(0, np.pi, resolution)
    phi = np.linspace(0, 2 * np.pi, resolution)
    theta, phi = np.meshgrid(theta, phi)

    r = r_max * np.exp(-r_max)

    Y_lm = sph_harm(m, l, phi, theta)
    prob_density = np.abs(Y_lm)**2

    x = r * np.sin(theta) * np.cos(phi) * prob_density
    y = r * np.sin(theta) * np.sin(phi) * prob_density
    z = r * np.cos(theta) * prob_density

    fig = plt.figure(figsize=(8, 6))
    ax = Axes3D(fig)   # Explicit 3D Axes — Pyright will now detect all methods
    fig.add_axes(ax)

    cmap = cm.get_cmap("viridis")
    ax.plot_surface(x, y, z, facecolors=cmap(prob_density / np.max(prob_density)),
                    rstride=1, cstride=1, linewidth=0, antialiased=False, alpha=0.8)

    ax.set_title(f'Orbital (n={n}, l={l}, m={m})')
    ax.axis('off')
    plt.tight_layout()
    plt.show()

# Example: Plot 2p orbital
#plot_orbital(n=2, l=1, m=0)
#plot_orbital(n=2, l=1, m=0)
plot_orbital(n=3, l=2, m=1)
```

Notes:

- This script visualizes *angular nodes* — not full radial structure.
- The radial part is oversimplified; real $R#sub[n,l] (r) $ comes from solving the radial Schrödinger
  equation (for hydrogenic case).
- `sph_harm(m, l, φ, θ)` is from `scipy.special` and returns complex values.
- You can visualize different `m` values to see *orbital orientations*.

== Python Orbital plot program:

Program function including what it computes and how it visualizes orbitals based on the quantum numbers $n, l, m$.

=== What This Program Does

Python script *visualizes atomic orbitals* by plotting the *angular probability distribution* derived from 
Quantum Mechanics.

Specifically, it computes & plots the square of the *spherical harmonic* $Y#sub[l]#super[m] (theta, phi)$ , which 
defines the *shape and orientation* of an orbital in 3D space.


=== Quantum Concepts Behind the Code

- *Atomic orbitals* are solutions to the Schrödinger equation.
- Each orbital is defined by 3 quantum numbers:

  - $n$: principal quantum number (energy level)
  - $l$: angular momentum quantum number (shape)
  - $m$: magnetic quantum number (orientation)
- The full wavefunction $psi$ is made of two parts:

  $
  psi(r, theta, phi) = R#sub[n,l] (r) . Y#sub[l]#super[m] (theta, phi)
  $

  This script visualizes *$| Y#sub[l]#super[m] (theta, phi) |^2$* only — the angular part.

=== How the Code Works (Line-by-Line)

1. *Imports*

```python
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d.axes3d import Axes3D
from scipy.special import sph_harm
```

- Brings in necessary libraries:

  - `numpy` for math
  - `matplotlib` for 3D plotting
  - `scipy.special.sph_harm` to compute spherical harmonics

2. *Function to Plot Orbital*

```python
def plot_orbital(n, l, m, resolution=100, r_max=1.0):
```

- Takes in orbital quantum numbers $n, l, m$
- `resolution`: quality of the meshgrid
- `r_max`: scaling factor for visual size

3. *Create Angular Grid*

```python
theta = np.linspace(0, np.pi, resolution)
phi = np.linspace(0, 2 * np.pi, resolution)
theta, phi = np.meshgrid(theta, phi)
```

- Creates a 2D mesh in spherical coordinates: $theta$ (polar), $phi$ (azimuthal)

4. *Simplified Radius*

```python
r = r_max * np.exp(-r_max)
```

- Uses a constant $r$ just for visualization scale
- This does *not* include actual radial nodes (e.g. 2s orbital shells)

5. *Compute Spherical Harmonic*

```python
Y_lm = sph_harm(m, l, phi, theta)
prob_density = np.abs(Y_lm)**2
```

- `sph_harm` gives complex values for the angular wavefunction
- Taking the magnitude squared $|psi|^2$ gives the *probability density*

6. *Convert to Cartesian Coordinates*

```python
x = r * np.sin(theta) * np.cos(phi) * prob_density
y = r * np.sin(theta) * np.sin(phi) * prob_density
z = r * np.cos(theta) * prob_density
```

- Converts spherical to Cartesian so we can plot in 3D
- Multiplies by `prob_density` to create lobes that reflect where electrons are likely to be

7. *Create 3D Plot*

```python
fig = plt.figure(figsize=(8, 6))
ax = Axes3D(fig)
fig.add_axes(ax)
```

- Sets up a 3D figure and explicitly defines `Axes3D`, so Pyright understands it

8. *Plot Surface*

```python
cmap = cm.get_cmap("viridis")
ax.plot_surface(x, y, z, facecolors=cmap(prob_density / np.max(prob_density)), ...)
```

- Plots a colored 3D surface where shape = electron density
- Uses `viridis` colormap to represent intensity

9. *Finalize Plot*

```python
ax.set_title(f'Orbital (n={n}, l={l}, m={m})')
ax.axis('off')
plt.tight_layout()
plt.show()
```

- Adds title
- Removes axes for a cleaner plot
- Displays the orbital


Summary: What You See

- *Shape of the orbital*: dictated by $l$ and $m$
- *Lobes and nodes*: angular nodes appear as regions with zero probability (gaps in the plot)
- *Orientation*: changes with different $m$ values

For example:

- $l = 0$ → spherical (s orbital)
- $l = 1, m = 0$ → dumbbell along z-axis (p orbital)
- $l = 2, m = 2$ → cloverleaf shape (d orbital)




🎯 Possible Enhancements

- Compute actual *hydrogenic radial wavefunctions* (with Laguerre polynomials)
- Add 3D *volumetric rendering* using `pyvista` or `mayavi`
- Add CLI or GUI for selecting orbital
- Animate changes in `n`, `l`, `m` interactively






Would you like me to expand this with real radial functions (e.g., 2s, 3d), or keep it lightweight for concept visuals?
