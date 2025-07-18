import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d.axes3d import Axes3D
from scipy.special import sph_harm, genlaguerre
from math import factorial

# -------------------------------
# Hydrogen-like Radial Functions
# -------------------------------
def hydrogen_radial(n, l, r, Z=1):
    """
    Returns hydrogen radial wavefunction R_{n,l}(r) for Z=1.
    Units: r in Bohr radii
    """
    rho = 2 * Z * r / n
    normalization = np.sqrt((2 * Z / n)**3 * factorial(n - l - 1) / (2 * n * factorial(n + l)))
    laguerre_poly = genlaguerre(n - l - 1, 2 * l + 1)(rho)
    return normalization * np.exp(-rho / 2) * rho**l * laguerre_poly

# -------------------------------
# Orbital Plotter with Radial + Angular
# -------------------------------
def plot_orbital(n, l, m, resolution=100, r_max=20):
    # Spherical grid
    theta = np.linspace(0, np.pi, resolution)
    phi = np.linspace(0, 2 * np.pi, resolution)
    r = np.linspace(0, r_max, resolution)
    theta, phi, r = np.meshgrid(theta, phi, r, indexing='ij')

    # Compute wavefunctions
    Y_lm = sph_harm(m, l, phi, theta)        # Angular part
    R_nl = hydrogen_radial(n, l, r)          # Radial part
    psi = R_nl * Y_lm                        # Total wavefunction
    prob_density = np.abs(psi)**2            # Probability density

    # Convert to Cartesian coordinates
    x = r * np.sin(theta) * np.cos(phi)
    y = r * np.sin(theta) * np.sin(phi)
    z = r * np.cos(theta)

    # Normalize and downsample for plotting
    density = prob_density / np.max(prob_density)
    mask = density > 0.05                    # Threshold to show only significant areas

    x, y, z, density = x[mask], y[mask], z[mask], density[mask]

    # Plotting
    fig = plt.figure(figsize=(8, 6))
    ax = Axes3D(fig)
    fig.add_axes(ax)

    p = ax.scatter(x, y, z, c=density, cmap=cm.get_cmap("plasma"), alpha=0.7, s=1)
    ax.set_title(f"Hydrogen Orbital n={n}, l={l}, m={m}")
    ax.axis('off')
    plt.tight_layout()
    plt.show()

# -------------------------------
# 🧪 Examples
# -------------------------------
# Plot a 2s orbital (1 radial node)
plot_orbital(n=2, l=0, m=0)

# Plot a 3s orbital (2 radial nodes)
# plot_orbital(n=3, l=0, m=0)

# Plot a 3p orbital (1 radial node, 1 angular node)
# plot_orbital(n=3, l=1, m=0)


'''

*extended version** of your orbital plotting program that includes **radial nodes**, meaning it now visualizes:

* ✅ **Angular dependence** via spherical harmonics $Y_l^m(\theta, \phi)$
* ✅ **Radial dependence** via hydrogen-like radial functions $R_{n,l}(r)$, which contain radial nodes

---

## 📐 Quantum Mechanics Refresher

The **full orbital** is:

$$
\Psi_{n,l,m}(r, \theta, \phi) = R_{n,l}(r) \cdot Y_l^m(\theta, \phi)
$$

* $R_{n,l}(r)$: radial wavefunction → contains **radial nodes**
* $Y_l^m(\theta, \phi)$: angular wavefunction → contains **angular nodes**
* $|\Psi|^2$: total probability density to be visualized

---

## ✅ Radial Functions for Hydrogen Orbitals

We’ll implement **normalized hydrogenic radial wavefunctions** for small $n$ and $l$:

### Examples:

* **2s**: 1 radial node
* **3s**: 2 radial nodes
* **3p**: 1 radial node
* **3d**: 0 radial nodes

---

## 🧪 Full Working Code (Radial + Angular Nodes)

```python
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d.axes3d import Axes3D
from scipy.special import sph_harm, genlaguerre
from math import factorial

# -------------------------------
# Hydrogen-like Radial Functions
# -------------------------------
def hydrogen_radial(n, l, r, Z=1):
    """
    Returns hydrogen radial wavefunction R_{n,l}(r) for Z=1.
    Units: r in Bohr radii
    """
    rho = 2 * Z * r / n
    normalization = np.sqrt((2 * Z / n)**3 * factorial(n - l - 1) / (2 * n * factorial(n + l)))
    laguerre_poly = genlaguerre(n - l - 1, 2 * l + 1)(rho)
    return normalization * np.exp(-rho / 2) * rho**l * laguerre_poly

# -------------------------------
# Orbital Plotter with Radial + Angular
# -------------------------------
def plot_orbital(n, l, m, resolution=100, r_max=20):
    # Spherical grid
    theta = np.linspace(0, np.pi, resolution)
    phi = np.linspace(0, 2 * np.pi, resolution)
    r = np.linspace(0, r_max, resolution)
    theta, phi, r = np.meshgrid(theta, phi, r, indexing='ij')

    # Compute wavefunctions
    Y_lm = sph_harm(m, l, phi, theta)        # Angular part
    R_nl = hydrogen_radial(n, l, r)          # Radial part
    psi = R_nl * Y_lm                        # Total wavefunction
    prob_density = np.abs(psi)**2            # Probability density

    # Convert to Cartesian coordinates
    x = r * np.sin(theta) * np.cos(phi)
    y = r * np.sin(theta) * np.sin(phi)
    z = r * np.cos(theta)

    # Normalize and downsample for plotting
    density = prob_density / np.max(prob_density)
    mask = density > 0.05                    # Threshold to show only significant areas

    x, y, z, density = x[mask], y[mask], z[mask], density[mask]

    # Plotting
    fig = plt.figure(figsize=(8, 6))
    ax = Axes3D(fig)
    fig.add_axes(ax)

    p = ax.scatter(x, y, z, c=density, cmap=cm.get_cmap("plasma"), alpha=0.7, s=1)
    ax.set_title(f"Hydrogen Orbital n={n}, l={l}, m={m}")
    ax.axis('off')
    plt.tight_layout()
    plt.show()

# -------------------------------
# 🧪 Examples
# -------------------------------
# Plot a 2s orbital (1 radial node)
plot_orbital(n=2, l=0, m=0)

# Plot a 3s orbital (2 radial nodes)
# plot_orbital(n=3, l=0, m=0)

# Plot a 3p orbital (1 radial node, 1 angular node)
# plot_orbital(n=3, l=1, m=0)
```

---

## 🔍 How It Works

| Component           | Description                                                          |      |                           |
| ------------------- | -------------------------------------------------------------------- | ---- | ------------------------- |
| `hydrogen_radial()` | Computes radial wavefunction $R_{n,l}(r)$ using Laguerre polynomials |      |                           |
| `sph_harm()`        | Computes angular wavefunction $Y_l^m(\theta, \phi)$                  |      |                           |
| `psi = R \cdot Y`   | Full wavefunction                                                    |      |                           |
| \`                  | psi                                                                  | ^2\` | Total probability density |
| `scatter(...)`      | Plots dense points in space where electrons are likely to be found   |      |                           |
| `mask`              | Removes low-density areas to make the plot clearer                   |      |                           |

---

## 🎯 What You Can Do Now

* ✅ Visualize orbitals with both **radial** and **angular** nodes
* 🎨 Customize color map, resolution, or threshold
* 💡 Try different orbitals like:

  * `plot_orbital(3, 2, 1)` → 3d orbital
  * `plot_orbital(4, 0, 0)` → 4s orbital (3 radial nodes)

---

Would you like:

* An interactive UI (e.g. with sliders)?
* Animated transitions between orbitals?
* Output as image or video?

Let me know — I can build on this!
'''

