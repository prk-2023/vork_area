# 1. Permutations, Combinations  and Problems:

## Overview:

Here’s a solid overview of **permutations and combinations** suitable for Grade 9, plus some advanced 
concepts to challenge you.
---

## **Permutations and Combinations**

### 1. **Basic Definitions**

* **Permutation:** Arrangement of objects in a specific order. Order **matters**.
* **Combination:** Selection of objects without regard to order. Order **does not matter**.

---

### 2. **Permutations**

* **Formula for permutations of n objects taken r at a time:**

$$
P(n, r) = \frac{n!}{(n-r)!}
$$

* **Example:**

How many ways to arrange 3 books out of 5 on a shelf?

$$
P(5, 3) = \frac{5!}{(5-3)!} = \frac{5 \times 4 \times 3 \times 2 \times 1}{2 \times 1} = 60
$$

---

### 3. **Combinations**

* **Formula for combinations of n objects taken r at a time:**

$$
C(n, r) = \binom{n}{r} = \frac{n!}{r! (n-r)!}
$$

* **Example:**

How many ways to choose 3 students from 5?

$$
C(5, 3) = \frac{5!}{3! \times 2!} = \frac{120}{6 \times 2} = 10
$$

---

### 4. **Factorials**

* $n! = n \times (n-1) \times (n-2) \times \dots \times 1$
* By definition, $0! = 1$

---

### 5. **Relationship Between Permutations and Combinations**

$$
P(n, r) = C(n, r) \times r!
$$

Because permutations are just combinations with ordering.

---

## **Advanced Topics**

### 1. **Permutations with Repetition**

* If you have repeated objects, the number of distinct permutations is:

$$
\frac{n!}{n_1! \times n_2! \times \dots \times n_k!}
$$

where $n_1, n_2, ..., n_k$ are the counts of each repeated object.

* **Example:**

How many ways to arrange the letters in **BALLOON**?

Letters: B(1), A(1), L(2), O(2), N(1)

$$
\frac{7!}{2! \times 2!} = \frac{5040}{4} = 1260
$$

---

### 2. **Combinations with Repetition**

* Number of ways to select r objects from n types **with repetition allowed**:

$$
C(n + r - 1, r) = \binom{n + r - 1}{r}
$$

* **Example:**

Number of ways to choose 3 candies from 5 types, allowing repeats:

$$
C(5 + 3 - 1, 3) = C(7, 3) = 35
$$

---

### 3. **Circular Permutations**

* Number of ways to arrange n objects **in a circle**:

$$
(n - 1)!
$$

Because rotations are considered the same arrangement.

* **Example:**

Ways to seat 5 friends around a round table:

$$
(5 - 1)! = 4! = 24
$$

---

### 4. **Permutation with Restrictions**

* If certain elements must be together or apart, adjust accordingly.

* **Example:**

5 people sitting in a row, but two specific people must sit together:

Treat those two as a block:

Number of ways:

$$
P(4, 4) \times 2! = 4! \times 2 = 24 \times 2 = 48
$$

---

### 5. **Binomial Theorem and Combinations**

* The coefficients in $(a + b)^n$ are combinations:

$$
(a + b)^n = \sum_{k=0}^{n} \binom{n}{k} a^{n-k} b^k
$$

<!-- for generating a horizontal red line -->
<hr style="border: 1px solid red;">

# 2. **practice problems** and explanations of these topics with detailed examples?


Practice problems on permutations and combinations, covering basic and advanced levels. 

---
# Practice Problems

### **Problem 1: Basic Permutation**

**Q:** How many different ways can 4 students be arranged in a line from a group of 7?

Before starting first figure out if its permutation or combinations problem to be solved.

Method 1:
Number of different ways to arrange 4 students in a line chosen from a group of 7 students.
Its permutation problem as order matters
Step 1: Choose which 4 students out of the 7 to arrange.
Number of ways to choose 4 students out of 7 is $\binom{7}{4}$.
Step 2: Arrange those 4 students in a line.
Number of ways to arrange 4 students is $4! = 24$.
Step 3: Total number of ways
$$
    \binom{7}{4} \times 4! = \frac{7!}{4! \times 3!} \times 4! = \frac{7!}{3!} = \frac{5040}{6} = 840.
$$

Method 2: use the formula directly calculate the permutations of 7 students taken 4 at a time, denoted $P(7,4)$:

$$
    P(7,4) = \frac{7!}{(7-4)!} = \frac{7!}{3!} = 840.
$$

**Answer:**

$$
\boxed{840}
$$

There are 840 different ways to arrange 4 students in a line from a group of 7.

---

### **Problem 2: Basic Combination**

**Q:** A team of 3 is to be selected from 8 students. How many ways can this be done?

Fist figure out order matter or not : as in a Team order does not matter ==> this is combinations problem.
$$ 
    P(8,3) = \frac{8!}{3!(8-3)!} = \frac{8!}{3!x5!} = \frac{336}{6} = 56
$$

---

### **Problem 3: Permutation with Repetition**

**Q:** How many distinct ways can the letters in the word **“SUCCESS”** be arranged?

step 1: figure out order matter or not: ( distinct ==> order matter ==> permutations with repetitions)
Plug the formula: there are C and S repeat twice and thrice.
    $n=7$, p1(S) = 3, p2(U) = 1 , p3(C) = 2, p4(E) = 1

formula =

$$ 
    \frac{n!}{p1! p2! p3!..} = \frac{7!}{3!x1!x2!x1!} = \frac{7x6x5x4x3x2x1}{3x2x1x2x1x1x1} = 420
$$

---

### **Problem 4: Combination with Repetition**

**Q:** In an ice cream shop, there are 6 flavors. You want to choose 4 scoops of ice cream, and you can 
pick any flavor more than once. How many ways can you select the scoops?

Step1: figure out order matter or not =>  pick any ==> Repetition allowed, order does NOT matter 
Its a combinations with allowed repetitions.

Number of flavors $n = 6$ , * Number of scoops $r = 4$ 
Formula for combinations with repetition:
$$
\text{Number of ways} = \binom{n + r - 1}{r} = \binom{6 + 4 - 1}{4} = \binom{9}{4}
$$

Calculate $\binom{9}{4}$:

$$
\binom{9}{4} = \frac{9!}{4! \cdot 5!} = \frac{9 \times 8 \times 7 \times 6}{4 \times 3 \times 2 \times 1} = \frac{3024}{24} = 126
$$

---

### **Problem 5: Circular Permutation**

**Q:** In how many ways can 6 friends sit around a round table?

Step1: for linear arrangement of $n$ distinct people, the number of ways is $n!$
for circular arrangement its $(n-1)!$ 
for linear total number of arrangements = $6!$ 
for circular its $(6-1)!$

Reason: (A,B,C,D,E,F) say we fix person A’s seat to break symmetry (say, always sit A at a specific seat). 
Now, arrange the remaining 5 people around A in any order.

The number of ways to arrange B, C, D..F around A is $5! = 120$

---

### **Problem 6: Permutation with Restriction**

**Q:** From 5 people, in how many ways can they be seated in a row if two particular people must sit together?

Step1:  order matters => permutation with Restriction that 2 are always together

Consider each person as a unit and two people as 1 unit we get total of 4 units

Number of ways 4 units can be arranged = $4! = 24$

Now two people can re-arrange in $2! = 2$ ways

So total arrangements = $24 x 2 = 48$


---

# Solutions & Explanation

---

### Problem 1 Solution

Number of ways to arrange 4 students out of 7 in a line:

$$
P(7, 4) = \frac{7!}{(7-4)!} = \frac{7!}{3!} = \frac{7 \times 6 \times 5 \times 4 \times 3!}{3!} = 7 \times 6 \times 5 \times 4 = 840
$$

---

### Problem 2 Solution

Number of ways to choose 3 students out of 8 (order doesn't matter):

$$
C(8, 3) = \frac{8!}{3! \times 5!} = \frac{8 \times 7 \times 6}{3 \times 2 \times 1} = 56
$$

---

### Problem 3 Solution

Word: **SUCCESS**

* Total letters = 7
* S appears 3 times
* C appears 2 times
* U and E appear once each

Number of distinct arrangements:

$$
\frac{7!}{3! \times 2! \times 1! \times 1!} = \frac{5040}{6 \times 2} = \frac{5040}{12} = 420
$$

---

### Problem 4 Solution

Choosing 4 scoops from 6 flavors with repetition allowed:

$$
C(n + r - 1, r) = C(6 + 4 - 1, 4) = C(9, 4) = \frac{9!}{4! \times 5!} = \frac{9 \times 8 \times 7 \times 6}{4 \times 3 \times 2 \times 1} = 126
$$

---

### Problem 5 Solution

Number of ways to seat 6 friends around a round table:

$$
(6 - 1)! = 5! = 120
$$

---

### Problem 6 Solution

Two particular people must sit together.

* Treat these two as one block → So total blocks = 4 (this pair + other 3 people)
* Number of ways to arrange the 4 blocks:

$$
4! = 24
$$

* The pair can switch seats among themselves:

$$
2! = 2
$$

Total arrangements:

$$
24 \times 2 = 48
$$

---
# **Medium Level Problems**
---

### **Problem 7: Arrangements with Restrictions**

**Q:** How many ways can 6 people be arranged in a row if two particular people **cannot** sit next to each other?

---

### **Problem 8: Selecting Committees**

**Q:** A club has 10 members. How many ways are there to form a committee of 4 people that **must include** at least one particular member?

---

### **Problem 9: Words from Letters**

**Q:** How many 5-letter "words" (not necessarily meaningful) can be formed from the letters of the word **"TURTLE"** if no letter is repeated?

---

### **Problem 10: Combination with Multiple Conditions**

**Q:** From a group of 8 boys and 7 girls, a committee of 5 is to be formed such that the committee has **at least 3 girls**. How many such committees are possible?

---

# **Difficult Level Problems**

---

### **Problem 11: Circular Permutations with Restrictions**

**Q:** 7 friends sit around a round table. Two particular friends must **not** sit next to each other. How many seating arrangements are possible?

---

### **Problem 12: Complex Permutation**

**Q:** How many different 6-digit numbers can be formed using the digits 1, 2, 3, 4, 5, 6 without repetition, such that the number is **even** and the digits 1 and 2 are **not adjacent**?

---

### **Problem 13: Combinations with Repetition and Restrictions**

**Q:** How many solutions are there to the equation

$$
x_1 + x_2 + x_3 + x_4 = 10
$$

where $x_i \geq 0$ are integers, but $x_1 \leq 3$?

---

### Problem 14: Permutations of Multisets with Restrictions

**Q:** How many ways can the letters of the word **"BALLOON"** be arranged such that the two **L's** are **not adjacent**?

---

# **Solutions**

---

### Problem 7 Solution

Total permutations of 6 people in a row:

$$
6! = 720
$$

Number of permutations where two particular people **are together**:

Treat the two as a block, so number of entities = 5 (block + 4 others)

Number of arrangements:

$$
5! \times 2! = 120 \times 2 = 240
$$

Number of permutations where they **are NOT together**:

$$
720 - 240 = 480
$$

---

### Problem 8 Solution

Total ways to form committee of 4 from 10:

$$
C(10, 4) = 210
$$

Committees **without** the particular member:

$$
C(9, 4) = 126
$$

Committees **with at least that member**:

$$
210 - 126 = 84
$$

---

### Problem 9 Solution

Letters in **TURTLE**:

* T appears twice
* U, R, L, E appear once each

No repetition allowed means you can only use one T.

Choose 5 letters from the 6, but only one T can be used.

Number of ways:

* Pick T once and choose other 4 letters from U, R, L, E (4 letters):

$$
C(4,4) = 1
$$

So the 5 letters are T, U, R, L, E.

Number of permutations:

$$
5! = 120
$$

* Or pick 5 letters **without T** (just U, R, L, E) but only 4 letters total so can't pick 5 without T.

Hence total 120 ways.

---

### Problem 10 Solution

At least 3 girls means 3 girls + 2 boys, or 4 girls + 1 boy, or 5 girls + 0 boys.

Calculate each case:

* 3 girls + 2 boys:

$$
C(7, 3) \times C(8, 2) = 35 \times 28 = 980
$$

* 4 girls + 1 boy:

$$
C(7, 4) \times C(8, 1) = 35 \times 8 = 280
$$

* 5 girls + 0 boys:

$$
C(7, 5) = 21
$$

Total:

$$
980 + 280 + 21 = 1281
$$

---

### Problem 11 Solution

Number of total circular permutations of 7 people:

$$
(7-1)! = 6! = 720
$$

Number of arrangements where two particular friends **sit together**:

Treat the two as a block: total blocks = 6

Number of ways:

$$
(6-1)! \times 2! = 5! \times 2 = 120 \times 2 = 240
$$

Number of arrangements where they **do NOT sit together**:

$$
720 - 240 = 480
$$

---

### Problem 12 Solution

6-digit numbers using digits 1-6, no repetition, even number → last digit is 2,4, or 6.

Digits: {1,2,3,4,5,6}

**Step 1: Fix the last digit to be even**

Number of choices for last digit = 3 (2,4,6)

---

**Step 2: The digits 1 and 2 are not adjacent**

We consider cases depending on the last digit:

* If last digit = 2

Then 2 is at the end, so 1 cannot be adjacent to last digit (which is 2), so 1 cannot be in the 5th position.

Total digits left for the first 5 positions:

Digits left = {1,3,4,5,6}

Number of permutations for first 5 digits with 1 not at position 5 (because that would be adjacent to 2):

Total permutations of these 5 digits = 5! = 120

Number of permutations with 1 at position 5:

Fix 1 at position 5, permute other 4 digits in 4! = 24

Valid permutations with 1 not adjacent to 2:

$$
120 - 24 = 96
$$

---

* If last digit = 4 or 6

Then last digit is 4 or 6, so 2 is somewhere in first 5 digits.

We want 1 and 2 not adjacent anywhere.

Total digits for first 5 positions: {1,2, other 3 digits}

Let’s denote the 5 digits as a set with 1 and 2, plus three others.

Number of permutations of 5 digits = 5! = 120

Number of permutations where 1 and 2 are adjacent:

Treat 1 and 2 as a block → 4! permutations

But 1 and 2 can be in two orders inside the block → multiply by 2

Number of adjacent permutations:

$$
2 \times 4! = 2 \times 24 = 48
$$

So permutations where 1 and 2 **not** adjacent:

$$
120 - 48 = 72
$$

For each choice of last digit = 4 or 6, number of such permutations = 72

---

**Step 3: Total number of 6-digit numbers**

$$
\text{last digit }= 2 \rightarrow 96 \\
\text{last digit }= 4 \rightarrow 72 \\
\text{last digit }= 6 \rightarrow 72
$$

Sum:

$$
96 + 72 + 72 = 240
$$

---

### Problem 13 Solution

Equation:

$$
x_1 + x_2 + x_3 + x_4 = 10, \quad x_i \geq 0, \quad x_1 \leq 3
$$

---

**Step 1:** Ignore $x_1 \leq 3$

Number of non-negative integer solutions to:

$$
x_1 + x_2 + x_3 + x_4 = 10
$$

is

$$
C(10 + 4 - 1, 4 - 1) = C(13, 3) = 286
$$

---

**Step 2:** Count solutions where $x_1 \geq 4$

Put $y_1 = x_1 - 4 \geq 0$, so

$$
y_1 + x_2 + x_3 + x_4 = 6
$$

Number of solutions:

$$
C(6 + 4 - 1, 3) = C(9, 3) = 84
$$

---

**Step 3:** Solutions with $x_1 \leq 3$:

$$
286 - 84 = 202
$$

---

### Problem 14 Solution

Arrange letters in **BALLOON** such that two **L's** are not adjacent.

---

Total letters = 7

* B(1), A(1), L(2), O(2), N(1)

Total arrangements:

$$
\frac{7!}{2! \times 2!} = 1260
$$

---

Number of arrangements where two L's **are together**:

Treat LL as one letter → so total letters = 6 (LL + B + A + O + O + N)

Number of arrangements:

$$
\frac{6!}{2!} = \frac{720}{2} = 360
$$

---

Number of arrangements where L's are **not together**:

$$
1260 - 360 = 900
$$

---
## **More Challenging Problems**

permutation and combination problems designed to really test your skills — 
with a mix of tricky conditions, multiple steps, and clever reasoning.
---

### **Problem 15: Permutations with Multiple Restrictions**

In how many ways can the letters of the word **"MISSISSIPPI"** be arranged such that **no two S’s are adjacent**?

---

### **Problem 16: Complex Committee Selection**

A committee of 7 is to be formed from 10 men and 8 women. The committee must have **at least 3 women** and **at most 4 men**. How many such committees are possible?

---

### **Problem 17: Counting Paths (Combinatorics Application)**

You are standing at the bottom-left corner of a 6x6 grid. You want to reach the top-right corner by moving **only right or up** along the grid lines. How many paths are there that **do not pass through the center square** (the square at row 3, column 3, counting rows and columns starting from 1 at the bottom-left)?

---

### **Problem 18: Derangements**

How many ways can 5 letters be placed into 5 addressed envelopes so that **no letter is in the correct envelope**?

---

### **Problem 19: Integer Solutions with Bounds**

How many integer solutions are there to

$$
x_1 + x_2 + x_3 + x_4 + x_5 = 20
$$

such that $0 \leq x_1 \leq 5$, $x_2 \geq 2$, and all other $x_i \geq 0$?

---

### **Problem 20: Necklace Arrangements**

How many distinct necklaces can be made by stringing together 8 beads where each bead is either red or blue, considering that rotating or flipping the necklace doesn’t create a new arrangement?

---

### **Problem 21: Multiset Permutations with Fixed Positions**

From the letters of the word **"BANANA"**, how many different 6-letter strings can be made such that **the two A's are separated by exactly one letter**?

---

### **Problem 22: Probability and Combinations**

A box contains 7 red, 5 blue, and 8 green balls. If 6 balls are drawn at random without replacement, what is the probability that:

* (a) Exactly 2 are red, 2 are blue, and 2 are green?

* (b) At least 4 are green?

---

