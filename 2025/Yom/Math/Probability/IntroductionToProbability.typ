= Probability Course Outline
//#set heading(numbering: "1.")
#show outline.entry: it => link(
  it.element.location(),
  // Keep just the body, dropping
  // the fill and the page.
  it.indented(it.prefix(), it.body()),
)
#line(length: 100%, stroke: (paint: blue, thickness: 2pt))
#outline()

//== Sample Spaces and Probability 
//- A foundational understanding of sample spaces and how to calculate basic probabilities.
//- Understand sample spaces and how to compute basic probabilities.

// == Two-way Tables and Probability
// Introduce two-way tables to visualize and calculate joint, marginal, and conditional probabilities.
// Use contingency tables to explore joint, marginal, and conditional probabilities.
//
// == Independent and Dependent Events
// Independent and Dependent Events
// Define independent and dependent events, using two-way tables for examples.
// Define events, examine dependence and independence.
//
// == Probability of Disjoint and Overlapping Events
// Probability of Disjoint and Overlapping Events
// Cover mutually exclusive (disjoint) and overlapping events with unions and intersections.
// Cover unions, intersections, and mutually exclusive cases.
//
// == Permutations and Combinations
// Permutations and Combinations
// Teach counting techniques essential for complex probability calculations.
//
// Learn counting techniques for arrangements and selections.
//
// == Binomial Distribution
// Binomial Distribution
// Apply permutations and probability to understand and calculate binomial probabilities.
// Apply previous concepts to model binomial random variables.
//
#pagebreak()
#set heading(numbering: "1.")

= Sample Spaces and Probability
#line(length: 100%, stroke: (paint: green, thickness: 1pt))

== Learning Objectives

After completing this lesson, students will be able to:

- Define sample spaces for simple and compound experiments.
- Calculate theoretical probabilities.
- Distinguish between equally likely and non-equally likely outcomes.
- Connect probability concepts to real-world and physics contexts.

== What is a Sample Space?

A *sample space* is the set of all possible outcomes of a random experiment.

Examples:

- Tossing a coin:  
  Sample space: $ S = {"Heads", "Tails"} $

- Rolling a 6-sided die:  
  Sample space: $S = {1, 2, 3, 4, 5, 6}$

- Tossing two coins:  
  Sample space: $S = {"HH", "HT", "TH", "TT"}$

Each outcome is called a *sample point*.

==  What is Probability?

The *probability* of an event is a number between 0 and 1 that expresses how likely the event is to occur.

For *equally likely outcomes*:

$
P(E) = {"Number of favorable outcomes"}/{"Total number of outcomes"}
$ 

Where:

* $P(E)$ is the probability of event E
* The denominator is the size of the sample space

Example:
What is the probability of rolling an even number on a 6-sided die?

- Sample space: $S = {1, 2, 3, 4, 5, 6}$
- Favorable outcomes: ${2, 4, 6}$
- $P(E) = 3/6 = 1/2$

== Visualizing Sample Spaces

You can visualize sample spaces using:

- Lists (e.g. ${"HH", "HT", "TH", "TT"}$)
- Tree diagrams
- Grids (for compound events)

Example (Tossing a coin and rolling a die):
Sample space:
$S = {(H,1), (H,2), (H,3), (H,4), (H,5), (H,6), (T,1), (T,2), ..., (T,6)}$
Total outcomes = 12

== Problems (math)

Examples:

== Practice Problems

=== A. Conceptual and Applied Problems

1. A drawer contains 3 red socks and 2 blue socks. One sock is pulled at random.
   a) What is the sample space?
   b) What is the probability of pulling a red sock?

2. A coin is flipped twice.
   a) List the sample space.
   b) Find the probability of getting exactly one head.

3. A student rolls two standard dice.
   a) What is the total number of possible outcomes?
   b) What is the probability that the sum is 7?

4. (Physics) A radioactive isotope has a 1 in 5 chance of decaying in a second.
   What is the probability it does *not* decay in that second?

\=== B. Pure Math Problems

5. A bag contains 4 green marbles, 3 blue marbles, and 5 yellow marbles.
   a) What is the total number of marbles?
   b) What is the probability of selecting a yellow marble?

6. A 3-digit number is randomly selected from 100 to 999.
   What is the probability that the number ends with a 0?

7. Two cards are drawn from a standard 52-card deck *with replacement*.
   a) What is the probability that both cards are hearts?
   b) What changes if the cards are drawn *without replacement*?

8. A spinner is divided into 8 equal sectors labeled A–H.
   a) What is the sample space?
   b) What is the probability of landing on a vowel?

9. A student guesses on a 4-option multiple-choice question.
   What is the probability they guess correctly?
   What is the probability they guess wrong *three times in a row*?

10. A box has 5 fair coins. What is the sample space for flipping *all 5 coins*?
    How many outcomes contain exactly 3 heads?

== Summary

- A *sample space* lists all possible outcomes of a random experiment.
- *Probability* quantifies the chance of an event occurring.
- *Physics* often relies on probability in complex or subatomic systems.


== Connection to Physics

Probability is fundamental in modern physics, especially in:

- *Quantum Mechanics*:
  Systems are described by probability amplitudes. The probability of an electron being in a region is derived from its wavefunction.

- *Thermodynamics & Statistical Mechanics*:
  Particle behavior is analyzed statistically. The concept of *microstates* and *macrostates* depends on counting possible configurations.

- *Radioactive Decay*:
  The decay of an unstable nucleus is *random*, but we can predict decay probabilities over time using half-life calculations.

Physics uses probabilities because systems often involve too many particles or too much complexity to determine outcomes deterministically.

== Practice Problems

1. A drawer contains 3 red socks and 2 blue socks. One sock is pulled at random.
   a) What is the sample space?
   b) What is the probability of pulling a red sock?

2. A coin is flipped twice.
   a) List the sample space.
   b) Find the probability of getting exactly one head.

3. A student rolls two standard dice.
   a) What is the total number of possible outcomes?
   b) What is the probability that the sum is 7?

4. (Physics) A radioactive isotope has a 1 in 5 chance of decaying in a second.
   What is the probability it does *not* decay in that second?

== Summary

-  A *sample space* lists all possible outcomes of a random experiment.
-  *Probability* quantifies the chance of an event occurring.
-  *Physics* often relies on probability in complex or subatomic systems.

#line(length: 100%, stroke: (paint: green, thickness: 1pt))

#pagebreak()


= Two-Way Tables and Probability
#line(length: 100%, stroke: (paint: green, thickness: 1pt))

== Objectives

- Interpret two-way tables (contingency tables) to organize data.
- Identify and calculate *joint*, *marginal*, and *conditional* probabilities.
- Understand the difference between independent and dependent events in the context of data.
- Apply these concepts in real-world scenarios, including physics and statistics.

==  What is a Two-Way Table?

A *two-way table* (or contingency table) displays the frequency of data categorized by two variables.

Example:

|           | Left-handed | Right-handed | Total |
|-----------|-------------|--------------|-------|
| Male      |     8       |     42       |  50   |
| Female    |     4       |     46       |  50   |
| *Total* |    12       |     88       | 100   |

- Each *cell* shows a joint outcome (e.g., Male & Left-handed = 8).
- Row and column totals give *marginal frequencies*.

== 2.2 Types of Probabilities

- *Joint Probability*: Probability of two events occurring together.  
  Example:  
  `P(Male ∩ Left-handed) = 8 / 100 = 0.08`

- *Marginal Probability*: Probability of a single event occurring (from row/column totals).  
  Example:  
  `P(Left-handed) = 12 / 100 = 0.12`

- *Conditional Probability*: Probability of one event given another has occurred.  
  Example:  
  `P(Left-handed | Male) = 8 / 50 = 0.16`

  Read as: "The probability that a person is left-handed *given* that they are male."

== 2.3 Using Two-Way Tables in Physics

Two-way tables help in analyzing *experimental data*, especially when looking at outcomes across categories.

Examples in physics:

- Measuring outcomes of experiments by *conditions* (e.g., mass category vs. energy release).
- Relating *quantum states* to observed measurements.
- Categorizing particle detection results by detector type and decay result.

Such tables help physicists compute empirical probabilities and test for independence between variables.

== 2.4 Practice Problems

=== A. Table-Based Problems

1. A survey of 200 students recorded whether they liked Math and Science.

|             | Likes Math | Does Not Like Math | Total |
|-------------|------------|--------------------|-------|
| Likes Science     |    80     |         30         | 110   |
| Does Not Like Science |    40     |         50         | 90    |
| *Total*     |   120     |         80         | 200   |

a) What is the probability that a student likes both Math and Science?  
b) What is the probability that a student does *not* like Science?  
c) What is the probability that a student likes Science *given* they like Math?  
d) Are liking Math and liking Science independent? Justify with probabilities.

---

2. In a group of 150 drivers:

|             | Uses Seatbelt | Does Not Use Seatbelt | Total |
|-------------|----------------|------------------------|-------|
| Urban       |       60       |           30           |  90   |
| Rural       |       20       |           40           |  60   |
| *Total*   |       80       |           70           | 150   |

a) What is `P(Uses Seatbelt ∩ Urban)`?  
b) Find `P(Rural | Does Not Use Seatbelt)`  
c) Find `P(Uses Seatbelt)`  
d) Are seatbelt use and location independent?

=== B. Create Your Own Table

3. A physics lab measures the success of two materials in conducting electricity at low temperature.

- Material A: 18 worked, 7 failed  
- Material B: 25 worked, 10 failed

a) Construct a two-way table for material and result  
b) What is `P(Success | Material A)`?  
c) Compare `P(Success | Material A)` and `P(Success | Material B)`

=== C. Challenge Question

4. A study tracks whether students passed Physics and/or Chemistry:

|         | Passed Chem | Failed Chem | Total |
|---------|-------------|-------------|-------|
| Passed Physics |     48      |     12      |  60   |
| Failed Physics |     20      |     20      |  40   |
| *Total* |     68      |     32      | 100   |

a) What is `P(Passed Chem ∩ Passed Physics)`?  
b) What is `P(Failed Physics | Failed Chem)`?  
c) What is `P(Passed Physics)`?  
d) Is passing Chemistry independent of passing Physics?

== Summary

- Two-way tables organize data for two variables.
- You can extract *joint*, *marginal*, and *conditional* probabilities.
- Independence of events can be tested using conditional probability.
- Physics experiments often rely on analyzing results in a table format for interpretation.
