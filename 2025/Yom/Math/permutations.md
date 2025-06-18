Here's a set of **advanced-level notes on Permutations and Combinations** for **Grade 9 students**, designed to challenge and deepen understanding while still being accessible:

---

# 📘 **Permutations and Combinations – Advanced Notes (Grade 9)**

---

## 🔶 **1. Introduction**

* **Counting Principle**: If one event can occur in *m* ways and a second in *n* ways, then both can occur in *m × n* ways.

---

## 🔷 **2. Permutations (Arrangement)**

### ➤ Definition:

Permutations are the **arrangements of items** in a specific order.

### ➤ Formulae:

1. **Without Repetition**:

   $$
   nP_r = \frac{n!}{(n - r)!}
   $$

   * *n* = total items
   * *r* = items chosen
   * Order **matters**

2. **With Repetition**:

   $$
   n^r
   $$

   * Each item can be repeated

3. **When Some Items are Repeated**:

   $$
   \frac{n!}{p_1! \cdot p_2! \cdot \dots \cdot p_k!}
   $$

   * Used when some items are identical (like letters in "BALLOON")

---

### ➤ Examples:

1. How many ways to arrange 5 books on a shelf?

   $$
   5! = 120 \text{ ways}
   $$

2. Arrange the letters of the word **“LEVEL”**?

   * L: 2, E: 2, V:1 →

   $$
   \frac{5!}{2! \cdot 2!} = 30 \text{ ways}
   $$

---

## 🔷 **3. Combinations (Selection)**

### ➤ Definition:

Combinations are the **selections of items** where **order doesn’t matter**.

### ➤ Formula:

$$
nC_r = \frac{n!}{r!(n - r)!}
$$

* Choosing *r* items from *n*
* Order **doesn’t** matter

---

### ➤ Examples:

1. Choose 3 students from a group of 5:

   $$
   5C3 = 10 \text{ ways}
   $$

2. From the word “APPLE”, how many ways to choose 2 letters?

   * Total letters = 5, A:1, P:2, L:1, E:1
   * List all combinations avoiding repetitions

---

## 🔶 **4. Key Differences: Permutation vs Combination**

| Feature | Permutation           | Combination             |
| ------- | --------------------- | ----------------------- |
| Order   | Matters               | Doesn’t matter          |
| Formula | $\frac{n!}{(n - r)!}$ | $\frac{n!}{r!(n - r)!}$ |
| Example | ABC ≠ BAC             | {A, B, C} = {C, B, A}   |

---

## 🔷 **5. Advanced Concepts**

### ➤ Circular Permutations:

* Arranging *n* objects in a circle:

$$
(n - 1)!
$$

* If clockwise and counter-clockwise are same (e.g., necklace), divide by 2:

$$
\frac{(n - 1)!}{2}
$$

---

### ➤ Restricted Permutations:

1. **Together/Adjacent**: Treat them as one block

   * Example: 3 people A, B, C where A and B must be together → AB, BA = 2! × remaining

2. **Not Together**:

   $$
   \text{Total Permutations} - \text{Permutations where they are together}
   $$

---

### ➤ Combinations with Restrictions:

* Example: From 6 people, choose 3 such that 2 specific people are never together.

---

## 🔶 **6. Pascal’s Triangle and Combinations**

* Useful for quickly finding combinations:

$$
\text{Row } n \text{ gives values of } nC0, nC1, ..., nCn
$$

---

## 🧠 **Challenge Questions**

1. How many 4-digit numbers can be made using digits 1–9 without repetition?
2. From 7 different books, how many ways to choose 3 books such that a specific book is always included?
3. In how many ways can you arrange the letters of the word “SUCCESS”?

---

## 📌 **Tips & Tricks**

* Use factorial simplifications:

  $$
  \frac{7!}{4!} = 7×6×5
  $$

* When order matters → Use **Permutation**

* When just selecting → Use **Combination**

* Practice with word problems involving **teams**, **arrangements**, **number formation**, and **seating**.

---

Would you like this as a **printable PDF** or need **practice worksheets with solutions**?


Sure! Here's a **step-by-step derivation** of the **permutation formula without repetition**:

---

# 🔷 **Goal**: Derive the formula for

$$
^nP_r = \frac{n!}{(n - r)!}
$$

---

## 🔶 **Step 1: Understand What a Permutation Is**

A **permutation** is an **arrangement** of items **where order matters**.

Suppose we have:

* $n$ distinct items
* We want to arrange **$r$** of them in **order**

---

## 🔶 **Step 2: Count the Choices**

Let’s count the number of ways to choose and arrange these $r$ items:

1. For the **1st position**, we have $n$ choices.
2. For the **2nd position**, we now have $n - 1$ choices.
3. For the **3rd position**, we have $n - 2$ choices.
4. ...
5. For the **$r$th position**, we have $n - r + 1$ choices.

So the total number of permutations is:

$$
n \cdot (n - 1) \cdot (n - 2) \cdot \ldots \cdot (n - r + 1)
$$

---

## 🔶 **Step 3: Express in Terms of Factorials**

This product looks like the beginning of $n!$, but it **stops** after $r$ terms.

So we can write:

$$
^nP_r = \frac{n!}{(n - r)!}
$$

Why?

Because:

$$
n! = n \cdot (n - 1) \cdot (n - 2) \cdots (n - r + 1) \cdot (n - r) \cdots 1
$$

So to get only the **first $r$** terms, we divide out the last $(n - r)$ terms:

$$
^nP_r = \frac{n!}{(n - r)!}
$$

---

## ✅ **Conclusion**:

$$
^nP_r = \frac{n!}{(n - r)!}
$$

This gives the number of **ordered arrangements** of $r$ objects selected from $n$ distinct objects.

---


# 🔷 **Goal**: Derive the formula for permutations with repeated elements:

$$
\text{Total permutations} = \frac{n!}{p_1! \cdot p_2! \cdot \dots \cdot p_k!}
$$

Where:

* $n$ = total number of items,
* $p_1, p_2, \dots, p_k$ are the counts of **repeated** (indistinguishable) items.

---

## 🔶 **Step-by-Step Derivation**

---

### ✅ **Step 1: Assume All Items Are Distinct**

If **all $n$ items are distinct**, then the total number of **permutations** is:

$$
n!
$$

Because each item is unique, swapping any two will give a different arrangement.

---

### ✅ **Step 2: Consider Some Items Are Indistinguishable**

Now, suppose **some items are repeated** and **indistinguishable** from each other.

Let’s say:

* There are **$p_1$** identical items of one kind (say, letter A),
* $p_2$ identical items of another kind (say, letter B),
* …
* $p_k$ identical items of the $k^{\text{th}}$ kind,

And:

$$
p_1 + p_2 + \dots + p_k = n
$$

---

### ✅ **Step 3: Remove Overcounting Due to Indistinguishability**

When items are repeated, **swapping them among themselves doesn’t create a new arrangement**.

So, we **overcount** by the number of ways we can rearrange **each set of identical items**.

* $p_1!$: ways to arrange the first type (which look the same)
* $p_2!$: ways to arrange the second type
* …
* $p_k!$: for the $k^{\text{th}}$ type

Thus, to **correct for overcounting**, we divide:

$$
\text{Correct number of unique permutations} = \frac{n!}{p_1! \cdot p_2! \cdot \dots \cdot p_k!}
$$

---

## ✅ **Conclusion**:

$$
\boxed{
\text{Number of distinct permutations} = \frac{n!}{p_1! \cdot p_2! \cdot \dots \cdot p_k!}
}
$$

---

## 🔶 **Example: "BALLOON"**

* Total letters: 7 (B, A, L, L, O, O, N)
* Repeats: L (2 times), O (2 times)

$$
\text{Permutations} = \frac{7!}{2! \cdot 2!} = \frac{5040}{4} = 1260
$$

---


---

# 🔷 **Goal**: Derive the formula for permutations with repetition, where repetition **is allowed**:

$$
^nP_r = n^r
$$

Where:

* $n$ = total number of **distinct items** available,
* $r$ = number of **positions/items** to fill,
* **Repetition is allowed**, and **order matters**.

---

## 🔶 **Step-by-Step Derivation**

---

### ✅ **Step 1: Understand the Situation**

You're choosing $r$ items **from a set of $n$ distinct items**, and:

* **Each item can be chosen more than once** (repetition allowed),
* The **order in which they are selected matters** (permutation).

---

### ✅ **Step 2: Count the Choices for Each Position**

We need to fill $r$ positions.

For each position:

* We can choose **any** of the $n$ items (since repetition is allowed).

So:

* 1st position: $n$ choices
* 2nd position: $n$ choices
* 3rd position: $n$ choices
* ...
* $r$th position: $n$ choices

---

### ✅ **Step 3: Use the Counting Principle**

By the **Fundamental Counting Principle**:

$$
\text{Total number of permutations} = n \times n \times \dots \times n \quad (r \text{ times}) = n^r
$$

---

## ✅ **Conclusion**:

$$
\boxed{
^nP_r = n^r
}
$$

This is the number of **ordered arrangements** of $r$ items chosen **with repetition** from $n$ distinct options.

---

## 🔶 **Example**

How many 4-digit PIN codes can be made using digits 0–9 (i.e., 10 digits), if digits **can repeat**?

$$
n = 10, \quad r = 4 \Rightarrow 10^4 = 10,000 \text{ PINs}
$$

---

