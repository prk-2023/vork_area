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

'''

prog func — including what it computes and how it visualizes orbitals based on the quantum numbers $n, l, m$.


=== What This Program Does

Python script *visualizes atomic orbitals* by plotting the *angular probability distribution* derived from 
Quantum Mechanics. 
Specifically, it computes and plots the square of the *spherical harmonic* $Y_l^m(\theta, \phi)$, which 
defines the **shape and orientation** of an orbital in 3D space.


=== Quantum Concepts Behind the Code

- *Atomic orbitals* are solutions to the Schrödinger equation.
- Each orbital is defined by 3 quantum numbers:

  - $n$: principal quantum number (energy level)
  - $l$: angular momentum quantum number (shape)
  - $m$: magnetic quantum number (orientation)
- The full wavefunction $\Psi$ is made of two parts:

  $
  \Psi(r, \theta, \phi) = R_{n,l}(r) \cdot Y_l^m(\theta, \phi)
  $

  This script visualizes **$|Y_l^m(\theta, \phi)|^2$** only — the angular part.

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

- Creates a 2D mesh in spherical coordinates: $\theta$ (polar), $\phi$ (azimuthal)

4. *Simplified Radius*

```python
r = r_max * np.exp(-r_max)
```

- Uses a constant $r$ just for visualization scale
- This does **not** include actual radial nodes (e.g. 2s orbital shells)

5. *Compute Spherical Harmonic*

```python
Y_lm = sph_harm(m, l, phi, theta)
prob_density = np.abs(Y_lm)**2
```

- `sph_harm` gives complex values for the angular wavefunction
- Taking the magnitude squared $|\Psi|^2$ gives the *probability density*

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


Would you like an extended version that includes *radial nodes* (e.g., for 2s, 3s orbitals) or exports the orbitals to an image/animation?
'''
