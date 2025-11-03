**Big Ideas Math Algebra 2, Chapter 2: Quadratic Functions**, covering **Sections 2.1 → 2.4**.



Below is a **complete, classroom-ready tutorial** (concepts + examples + tips + mini-practice) that you can use for your student or adapt to slides/notes.

---

# 📘 **Tutorial: Quadratic Functions (Big Ideas Math, Algebra 2, Chapter 2)**

---

## ✳️ **Section 2.1 – Transformations of Quadratic Functions**

### 1️⃣ Parent Function

The basic quadratic function (the *parent*) is
[
f(x) = x^2
]
It’s a **U-shaped** curve (a **parabola**) that opens **upward**, with **vertex (0, 0)** and **axis of symmetry x = 0**.

---

### 2️⃣ Transformations

| Type of Change                     | Equation Form   | Effect on Graph                     |   |                          |   |                                                    |
| ---------------------------------- | --------------- | ----------------------------------- | - | ------------------------ | - | -------------------------------------------------- |
| **Vertical stretch / compression** | (y = a x^2)     | If (                                | a | >1) → *narrower*; if (0< | a | <1) → *wider*; if (a<0) → *reflects across x-axis* |
| **Vertical shift**                 | (y = x^2 + k)   | Moves up if (k>0); down if (k<0)    |   |                          |   |                                                    |
| **Horizontal shift**               | (y = (x - h)^2) | Moves right if (h>0); left if (h<0) |   |                          |   |                                                    |
| **Reflection**                     | (y = -x^2)      | Flips upside down (opens downward)  |   |                          |   |                                                    |

---

### 3️⃣ Vertex Form

The **general vertex form** is
[
y = a(x - h)^2 + k
]

* Vertex → ((h, k))
* Axis of symmetry → (x = h)
* “a” controls **opening** and **width**

---

### 🔹 Example 1

Transform (f(x)=x^2) into (g(x)=-2(x+3)^2+4)

**Interpretation:**

* (a=-2): reflect across x-axis + vertical stretch by 2
* (h=-3): shift left 3
* (k=4): shift up 4
  **Vertex:** ((-3, 4))

---

### 💡 Quick Practice

Describe the transformation:

1. (y = (x-5)^2 + 2)
2. (y = -\frac{1}{2}(x+1)^2 - 3)

---

---

## ✳️ **Section 2.2 – Characteristics of Quadratic Functions**

A quadratic in **standard form**:
[
y = a x^2 + b x + c
]

### Key Features

| Feature                  | Formula / Description                                                               |
| ------------------------ | ----------------------------------------------------------------------------------- |
| **Axis of symmetry**     | (x = -\dfrac{b}{2a})                                                                |
| **Vertex**               | (\left(-\dfrac{b}{2a},; f!\left(-\dfrac{b}{2a}\right)\right))                       |
| **Direction of opening** | Up if (a>0); down if (a<0)                                                          |
| **Y-intercept**          | (c)                                                                                 |
| **X-intercepts**         | Solve (a x^2 + b x + c = 0)                                                         |
| **Domain**               | All real numbers                                                                    |
| **Range**                | (y \ge k) (if opens up) or (y \le k) (if opens down), where k is the vertex y-value |

---

### 🔹 Example 2

Find vertex and intercepts for (y = 2x^2 - 8x + 5)

[
x_v = -\frac{b}{2a} = \frac{8}{4} = 2, \quad y_v = 2(2)^2 - 8(2) + 5 = -3
]
Vertex → (2, −3); opens up; axis x = 2; y-int = 5.

---

### 💡 Practice

For (y = -x^2 + 6x - 8):

* Find vertex
* Axis of symmetry
* Direction of opening
* Range

---

---

## ✳️ **Section 2.3 – Focus of a Parabola**

### 1️⃣ Geometric Definition

A **parabola** is the set of points *equidistant* from a **focus** (a fixed point) and a **directrix** (a fixed line).

---

### 2️⃣ Standard Forms

| Orientation | Equation | Vertex | Focus | Directrix |
|--------------|-----------|---------|---------|
| **Vertical axis** | ((x-h)^2 = 4p(y-k)) | ((h,k)) | ((h, k+p)) | (y = k - p) |
| **Horizontal axis** | ((y-k)^2 = 4p(x-h)) | ((h,k)) | ((h+p, k)) | (x = h - p) |

(p) = distance from vertex → focus or → directrix
If (p>0), parabola opens **up** or **right**; if (p<0), opens **down** or **left**.

---

### 🔹 Example 3

Given ((x+2)^2 = 8(y - 3)), find focus and directrix.

[
4p = 8 \Rightarrow p = 2
]
Vertex → (−2, 3); opens up
Focus → (−2, 3 + 2) = (−2, 5); Directrix → (y = 1)

---

### 💡 Practice

Find vertex, focus, and directrix for ( (x - 1)^2 = -12(y + 2) )

---

---

## ✳️ **Section 2.4 – Modeling with Quadratic Functions**

Quadratic functions model many real situations: **projectile motion**, **profit**, **area optimization**, etc.

---

### 1️⃣ Projectile Motion

Equation of height:
[
h(t) = -16t^2 + v_0 t + h_0
]

* (h_0): initial height
* (v_0): initial velocity
* Vertex gives **maximum height**
* Zeros give **time when projectile hits the ground**

---

### 🔹 Example 4

A ball is thrown upward: (h(t) = -16t^2 + 48t + 5)

Find:
(a) Max height (b) Time in air

**(a)** (t_v = -\frac{b}{2a} = \frac{48}{32} = 1.5 s)
(h(1.5) = -16(1.5)^2 + 48(1.5) + 5 = 41 ft)

**(b)** When (h=0:)
(-16t^2 + 48t + 5 = 0) → (t ≈ 3.1 s)

---

### 2️⃣ Modeling from Data

Given data points, you can **fit a quadratic** (using graphing or regression).
Form: (y = a(x-h)^2 + k) or (y = ax^2 + bx + c)

### 3️⃣ Optimization

* *Maximize area* (fence problems)
* *Maximize profit* (revenue vs cost)

---

### 💡 Practice

A company’s revenue follows (R(x) = -50x^2 + 400x), where x = number of units (hundreds).
Find:

* Number of units for max revenue
* Max revenue value

---

---

## 🧩 Summary Sheet

| Concept               | Key Idea                            | Example                                    |
| --------------------- | ----------------------------------- | ------------------------------------------ |
| **Transformation**    | (y = a(x-h)^2 + k)                  | Identify shifts, stretches, reflections    |
| **Characteristics**   | (a,b,c) → vertex, axis, intercepts  | Vertex = (-b/2a, f(-b/2a))                 |
| **Focus & Directrix** | ((x-h)^2 = 4p(y-k))                 | Find focus = (h, k+p), directrix = y = k-p |
| **Modeling**          | Real-world situations fit quadratic | Projectile motion, optimization            |

---

## ⚙️ Extension / Physics Connection

* In projectile motion, quadratic height–time curves appear naturally.
* In optics, the **focus** property explains how parabolic mirrors concentrate light.
* In energy potential wells, the near-equilibrium potential energy curve (U(x) = kx^2/2) is quadratic.

---

Would you like me to make this tutorial into a **PDF handout** (formatted with diagrams, graphs, and a short quiz at the end)?
I can include:

* labeled parabolas showing transformations,
* a focus/directrix diagram, and
* a 10-question practice quiz aligned to 2.1 – 2.4.
--------------------------------------
1. 
How do the constants a, h, and k affect the graph of the quadratic function g(x) =a(x-h)^2+k?

The parent function of the quadratic family is f(x) = x^2. 
A transformation of the graph of the parent function is represented by the function g(x) =a(x-h)^2+k, where a≠ 0.

Carefully break this down. 
We are looking at **quadratic transformations** of the parent function (f(x) = x^2) using the **vertex form**:

[
g(x) = a(x - h)^2 + k, \quad a \neq 0
]

---

## **The Parent Function**

* (f(x) = x^2)
* Graph: a U-shaped parabola
* Vertex: ((0,0))
* Opens **upward**
* Axis of symmetry: (x = 0)
* Domain: all real numbers
* Range: (y \ge 0)

---

## **The Constants in (g(x) = a(x-h)^2 + k)**

### **A. The “a” constant – Vertical stretch, compression, and reflection**

* **Effect on width:**

  * (|a| > 1) → parabola **narrower** (stretched vertically)
  * (0 < |a| < 1) → parabola **wider** (compressed vertically)

* **Effect on direction:**

  * (a > 0) → opens **upward**
  * (a < 0) → opens **downward** (reflected across x-axis)

* **Example:**

  * (g(x) = 2(x-1)^2 + 3) → opens upward, narrower than (f(x))
  * (g(x) = -\frac{1}{2}(x-1)^2 + 3) → opens downward, wider than (f(x))

---

### **B. The “h” constant – Horizontal shift**

* Replaces (x) with (x-h)

* **Moves the graph left or right**:

  * (h > 0) → shift **right** by (h) units
  * (h < 0) → shift **left** by (|h|) units

* **Vertex moves horizontally:** new x-coordinate of vertex = (h)

* **Example:**

  * (g(x) = (x-2)^2) → vertex moves from (0,0) to (2,0)

---

### **C. The “k” constant – Vertical shift**

* Adds directly to the function

* **Moves the graph up or down**:

  * (k > 0) → shift **up** by (k) units
  * (k < 0) → shift **down** by (|k|) units

* **Vertex moves vertically:** new y-coordinate of vertex = (k)

* **Example:**

  * (g(x) = (x-2)^2 + 3) → vertex moves to (2,3)

---

## 3️⃣ **Summary – How (a), (h), (k) Affect the Graph**

| Constant | Effect on Graph                                                                            |
| -------- | ------------------------------------------------------------------------------------------ |
| **a**    | Vertical stretch/compression; reflection over x-axis; controls width and opening direction |
| **h**    | Horizontal shift; vertex moves left/right; axis of symmetry (x = h)                        |
| **k**    | Vertical shift; vertex moves up/down; affects range                                        |

---

### 4️⃣ **Vertex Form Insight**

[
g(x) = a(x-h)^2 + k
]

* Vertex: ((h, k))
* Axis of symmetry: (x = h)
* Direction: determined by **sign of (a)**
* Width: determined by **magnitude of (a)**
* Range: depends on (a) and (k)

---

### 🔹 **Quick Example**

Function: (g(x) = -3(x + 1)^2 + 4)

* **a = -3:** opens downward, narrow
* **h = -1:** vertex shifted left 1 → x = -1
* **k = 4:** vertex shifted up 4 → y = 4
* **Vertex:** (-1, 4)
* **Axis:** x = -1
* **Range:** (y \le 4)

---

use kalebra or kalc 

