# Quantum States:

---

### **1. What are quantum states?**

A **quantum state** is the complete description of a quantum system.
It contains all the information there is to know about the system's physical properties.

#### Think of it this way:

In classical physics, the **state** of a system (say, a baseball) can be fully described by its
**position** and **velocity**.

You know where it is and how fast it’s moving.

In **quantum physics**, particles don’t have definite values for things like position or spin until you
measure them.

Instead, they exist in a **superposition**
— a mix of all possible values—until observed.

The quantum state tells you the **probabilities** of finding each possible result if you make a measurement.

#### Mathematically:

* A quantum state is often represented by a **state vector** (like $|\psi\rangle$) or
  a **wavefunction** $\psi(x)$, depending on the situation.
* For example, the state of an electron spin might be:

  $$
  |\psi\rangle = \frac{1}{\sqrt{2}}(|\uparrow\rangle + |\downarrow\rangle)

  $$

  Which means the electron is in a **superposition** of "spin up" and "spin down."

So, a **quantum state** encodes:

* What outcomes are possible when you measure the system.
* The **probabilities** for each of those outcomes.

---

### **2. What do you mean by 'quantum states of two or more particles become linked'?**

This is the essence of **quantum entanglement**.

When we say the quantum states of two particles become **linked**, we mean:

> You can no longer describe each particle’s state **independently** of the other.

#### Classical comparison (not entangled):

Let’s say you have two coins:

* Coin A is heads.
* Coin B is tails.

Even if you keep them in sealed boxes and take them far apart, each coin still has its own definite state.
They’re **independent**. No mystery.

#### Quantum version (entangled):

Now imagine two quantum coins (qubits) in this **entangled state**:

$$
|\psi\rangle = \frac{1}{\sqrt{2}}(|\text{Heads}_A\rangle|\text{Tails}_B\rangle + |\text{Tails}_A\rangle|\text{Heads}_B\rangle)

$$

This means:

* Neither coin has a definite state on its own.
* But **if** you open box A and find "heads," you instantly know box B will be "tails"—**even if it's on the
  other side of the galaxy**.
* This correlation exists **without either coin having a defined value** before the measurement.

#### Linked quantum states (entanglement) mean:

* The system as a whole (the pair of particles) has a well-defined state.
* But **individual particles don’t have their own separate states**.
* Their properties are correlated in a way that **can't be explained** by classical physics or local hidden
  variables.

---

### Summary:


| Concept                                  | Explanation                                                                                                                                                         |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Quantum state**                        | A complete description of a system’s possible behaviors and measurement outcomes, typically in the form of a vector or wavefunction.                               |
| **Linked quantum states** (Entanglement) | When the quantum state of two(or more) particles is described by a**single** shared state, such that measurements on one  affect the other, regardless of distance. |

---

# A simple experiment (like the Bell test), or a deeper mathematical description!

- **simple entanglement experiment** like a **Bell test**, 
- **mathematical formulation** that reveals why entanglement defies classical logic.

---

## 🔬 **Simple Bell Test Experiment (Conceptual)**

### 🎯 **Goal:**

To test whether the world is governed by **local realism** (classical physics) or **non-local quantum entanglement**.

---

### ⚙️ **Setup:**

1. **Entangled photons** are created using **Spontaneous Parametric Down-Conversion (SPDC)** in a crystal. 
They are in the state:


   $$
   |\psi\rangle = \frac{1}{\sqrt{2}}\left( |H\rangle_A |H\rangle_B + |V\rangle_A |V\rangle_B \right)
   $$

   This is a **Bell state**: both photons are entangled in **polarization** — either both horizontal (H) or 
   both vertical (V), but not known until measured.

2. **Alice** gets photon A. **Bob** gets photon B. They go far apart (e.g., kilometers).

3. Each person can choose between **two possible measurement angles** on their polarizer:

   * Alice chooses between angles **a** and **a′**
   * Bob chooses between **b** and **b′**

4. At each run of the experiment:

   * They randomly choose an angle and measure polarization.
   * They record **+1** for "pass" (e.g., photon passed the polarizer) and **–1** for "blocked".

---

### 📊 **Bell Inequality (CHSH version):**

Bell derived an inequality based on **local realism**:

$$
|E(a, b) - E(a, b′) + E(a′, b) + E(a′, b′)| \leq 2
$$

* $E(a, b)$ is the **correlation** between Alice and Bob’s results when they use settings $a$ and $b$.
* Local realistic theories **must** satisfy this inequality.
* **Quantum mechanics violates it.**

---

### 🔥 **Quantum Violation:**

If you pick the angles cleverly (like 0°, 45°, 22.5°, and 67.5°), then quantum mechanics predicts:

$$
|E(a, b) - E(a, b′) + E(a′, b) + E(a′, b′)| = 2\sqrt{2} \approx 2.828
$$

🔔 This **violates Bell's inequality**, proving that **no local hidden variable theory** can explain quantum entanglement.

---

## 📐 **Mathematical Description of Entanglement and Bell Test**

### 🧱 1. **The Bell State**

One of the four **maximally entangled** Bell states for two qubits (photons, electrons, etc.) is:

$$
|\Phi^+\rangle = \frac{1}{\sqrt{2}} \left( |00\rangle + |11\rangle \right)
$$

This state says:

* The system is not in $|00\rangle$ or $|11\rangle$ alone.
* It’s in a **superposition** of both.
* Measuring one qubit collapses the entire state.

---

### 🧲 2. **Measurement Operators**

A measurement in quantum mechanics is described by an **operator** (observable). For spin or polarization, we often use **Pauli matrices**:

* $\sigma_x$ (bit flip), $\sigma_y$ (phase flip), $\sigma_z$ (spin up/down)

Measurement angle $\theta$ corresponds to:

$$
\hat{O}_\theta = \cos(\theta) \sigma_z + \sin(\theta) \sigma_x
$$

For example:

* Alice measures along $a$: $A = \hat{O}_a$
* Bob measures along $b$: $B = \hat{O}_b$

---

### 🔗 3. **Quantum Correlation Function**

The expected value of joint measurement is:

$$
E(a, b) = \langle \psi | A \otimes B | \psi \rangle
$$

In quantum theory, for entangled state $|\Phi^+\rangle$ and appropriately chosen angles, this gives:

$$
E(a, b) = \cos(2(a - b))
$$

This violates Bell’s inequality when plugged into the CHSH formula.

---

### 🧠 **Why This Matters:**

* Classical hidden-variable theories **cannot** explain correlations beyond the Bell bound of 2.
* Quantum entanglement **does** produce correlations up to $2\sqrt{2}$.
* This suggests **non-locality**: the state of one particle **depends on** how the other is measured—even at a distance.

---

### 📌 Summary Table:

| Concept             | Classical View                 | Quantum View                                      |
| ------------------- | ------------------------------ | ------------------------------------------------- |
| Measurement outcome | Pre-existing                   | Created at measurement                            |
| Correlation         | Limited by Bell inequality     | Can exceed the limit (Bell violation)             |
| Locality            | No faster-than-light influence | Entangled states defy this intuitively            |
| Realism             | Hidden variables exist         | Hidden variables must be non-local or don’t exist |

---

# Python code simulation (e.g., using Python or Qiskit) / visual diagrams of how this plays out?

Great! Let's start by simulating a simple **Bell test** using Python. We can use **Qiskit**, which is a Python framework for quantum computing that lets you simulate quantum circuits, including entanglement and Bell state experiments.

### **Setting Up the Simulation:**

1. **Install Qiskit** if you haven't already:

   ```bash
   pip install qiskit
   ```

2. We'll create a **Bell state** and measure it in different bases (angles) to simulate the violation of the Bell inequality.

---

### **Step-by-Step Code:**

Here’s the code that simulates the **Bell state experiment** and calculates the correlation values for different measurement angles. The correlation function $E(a, b)$ is based on the angle difference between Alice’s and Bob’s measurements.

```python
# Import necessary libraries
from qiskit import QuantumCircuit, Aer, execute
import numpy as np
import matplotlib.pyplot as plt

# Create a Bell state |Φ+⟩
def create_bell_state():
    # Create a quantum circuit with 2 qubits
    qc = QuantumCircuit(2)
    qc.h(0)  # Apply Hadamard gate to qubit 0 (creates superposition)
    qc.cx(0, 1)  # Apply CNOT gate to entangle qubits 0 and 1
    return qc

# Measurement in the basis defined by angle theta
def measure_in_basis(qc, theta, qubit=0):
    # Apply a rotation to the qubit around the X-axis and Z-axis
    qc.rx(2 * theta, qubit)  # Rotation around X-axis
    qc.measure_all()

# Run the quantum circuit and calculate correlation E(a, b)
def run_bell_test(theta_a, theta_b):
    # Create Bell state circuit
    qc = create_bell_state()
    
    # Measure in the specified angles
    measure_in_basis(qc, theta_a, qubit=0)
    measure_in_basis(qc, theta_b, qubit=1)
    
    # Simulate the circuit
    simulator = Aer.get_backend('qasm_simulator')
    job = execute(qc, simulator, shots=1000)
    result = job.result()
    
    # Get measurement counts (how many times each outcome occurs)
    counts = result.get_counts(qc)
    
    # Calculate correlation: E(a, b)
    # '00' means both qubits are 0, '11' means both are 1, etc.
    correlation = (counts.get('00', 0) + counts.get('11', 0) - counts.get('01', 0) - counts.get('10', 0)) / 1000.0
    return correlation

# Define angles for Alice and Bob's measurements
angles = np.linspace(0, np.pi, 6)  # 0, 30, 60, 90, 120, 150 degrees

# Calculate correlation for different angle pairs (a, b)
correlations = []
for angle_a in angles:
    correlations_for_a = []
    for angle_b in angles:
        correlation = run_bell_test(angle_a, angle_b)
        correlations_for_a.append(correlation)
    correlations.append(correlations_for_a)

# Plot the correlation matrix (heatmap)
plt.imshow(correlations, cmap='coolwarm', extent=(0, np.pi, 0, np.pi), origin='lower')
plt.colorbar(label="Correlation E(a, b)")
plt.xlabel("Angle for Bob (b)")
plt.ylabel("Angle for Alice (a)")
plt.title("Bell Test: Correlation vs. Measurement Angles")
plt.show()
```

### **How the Code Works:**

1. **Create the Bell State**:

   * We use a **Hadamard gate** (H) on qubit 0 to create a superposition of $|0\rangle$ and $|1\rangle$.
   * Then, a **CNOT gate** is applied to entangle the two qubits.

2. **Measurement in a Chosen Basis**:

   * For both Alice (qubit 0) and Bob (qubit 1), we apply a rotation gate $R_x(\theta)$ before measurement, which corresponds to measuring in a basis defined by angle $\theta$.

3. **Run the Experiment**:

   * The quantum circuit is executed using the **qasm\_simulator** backend, and the results (measurement outcomes) are recorded.
   * We calculate the correlation $E(a, b)$ based on how many times both qubits measured the same value (00 or 11) versus when they measured different values (01 or 10).

4. **Plotting**:

   * The correlation values $E(a, b)$ for all possible combinations of Alice and Bob’s measurement angles are plotted in a heatmap.

---

### **Results:**

* The plot will show how the correlations $E(a, b)$ change with respect to the measurement angles of Alice and Bob.
* According to quantum mechanics, these correlations **will violate** the Bell inequality, showing a value larger than 2, which cannot be explained by any classical theory of local realism.

---

### **Interpreting the Results:**

* If the plot shows values **greater than 2**, it indicates that the quantum state is indeed exhibiting **non-local correlations** that violate classical expectations.
* This violation is evidence that **local hidden variable theories** cannot fully explain quantum entanglement and the correlations between entangled particles.

---

### **What to Expect**:

The **Bell inequality violation** happens when you choose certain angles (e.g., 0°, 45°, 22.5°, and 67.5°). You should see a clear deviation from classical expectations, illustrating the **non-local nature of quantum mechanics**.

---

### **Running the Code**:

To run this experiment on your local machine:

1. Ensure you have **Qiskit** installed (`pip install qiskit`).
2. Copy the code into a Python file and run it.
3. You should see a heatmap that shows how the correlation between Alice's and Bob's measurements varies with angle. You’ll observe a pattern consistent with quantum predictions.

---

Would you like any adjustments to the simulation, or more help running the code?

