To master AP Physics chapter by chapter using AI, treat the chat as a 
**structured 5-stage physics tutor** rather than asking a vague question like 
*"Explain torque and give me practice problems."

* AP Physics—especially AP Physics 1's 8-unit framework—rewards 
**qualitative reasoning, representation translation (graphs, free-body diagrams, equations), experimental design, and error diagnosis** just as much as numerical calculation.

---

## The 5-Stage Chapter Workflow

Run these five stages in order for every chapter or topic.

1. **Build Conceptual Intuition and System Boundaries:**
Start with physical models, conservation laws, and when equations apply before plugging in numbers.


2. **Expose and Dismantle Misconceptions:**
Force the AI to surface classic AP distractors and test your mental model with "what-if" edge cases.


3. **Practice Qualitative and Representation-Heavy MCQs:**
Train on conceptual multiple-choice questions that test proportional reasoning, graphs, and physical arguments without full numbers.


4. **Tackle AP-Style FRQs with Rubric Grading:**
Write full free-response answers—including justifications, experimental setups, and derivations—and have the AI score line-by-line against AP rubric conventions.


5. **Run a Targeted Error & Transfer Audit:**
Log every missed MCQ or lost FRQ point and ask for fresh problems targeting those exact failure modes.


---

## Copy-Paste Prompts for Each Stage

Swap out `[CHAPTER / TOPIC]` (and `[SUBTOPICS]` or `[COURSE: AP Physics 1 / 2 / C: Mechanics / C: E&M]`) before sending.

### Stage 1: Concept & Mental Model Prompt

> "Act as an experienced AP Physics teacher for **[COURSE]**. Teach me **[CHAPTER / TOPIC]**, specifically **[SUBTOPICS]**.
> 1. Explain the core physical principles and when each model/conservation law is valid vs. invalid.
> 2. Show how key equations connect to physical intuition and graphs (slopes, areas, asymptotes).
> 3. Give me a 3-question quick check to verify I have the intuition before we move to traps."
> 
> 

### Stage 2: Misconceptions & Edge-Case Prompt

> "For **[CHAPTER / TOPIC]** in AP Physics, list the top 6 student misconceptions that cause lost points on exams. For each misconception:
> * State the false intuition students hold.
> * Explain the true physics clearly.
> * Give a quick 'predict before you peek' scenario where I have to commit to an answer before you reveal why."

### Stage 3: MCQ Practice Prompt (Qualitative + Quantitative)

> "Generate **[6]** AP Physics-style multiple-choice questions on **[CHAPTER / TOPIC]** with 4 options (A–D) each. Include a mix of proportional reasoning, graph/diagram interpretation, and multi-step algebraic/numerical problems.
> **Do NOT show the answers or explanations yet.** Wait for me to reply with my answers A–D for each question. Once I reply, grade each one, explain why the right answer works, and explain why the specific distractors I picked are wrong."

### Stage 4: FRQ Practice & Rubric Grader Prompt

> "Write one multi-part AP Physics Free-Response Question (FRQ) on **[CHAPTER / TOPIC]** that mirrors AP exam style (include parts requiring justification/argumentation, derivation or mathematical routine, and either graph sketching or experimental design).
> **Stop after giving the prompt.** After I submit my written response, act as an AP Reader: break down the scoring points, tell me exactly which points I earned or missed, and rewrite any weak justification so it earns full credit."

### Stage 5: Post-Mortem & Transfer Prompt

> "Here are the questions and FRQ parts I missed on **[CHAPTER / TOPIC]**:
> [PASTE WHAT YOU GOT WRONG AND YOUR REASONING]
> Diagnose the root cause of each mistake (misread constraint, wrong system/boundary, sign/direction error, or flawed claim-evidence link). Then give me 2 new practice problems per mistake type that test the *same underlying skill* in a slightly unfamiliar context."

---

## Quick Comparison: What to Ask for Each Exam Format

| Target Skill | What Vague Prompts Miss | What to Include in Your Prompt |
| --- | --- | --- |
| **Concept & Graphs** | Memorizing formulas without knowing when they fail | Ask for **assumptions/limits**, **free-body/energy/momentum views**, and **graph shapes** |
| **Misconceptions** | Hearing "be careful with signs/forces" generically | Ask for **common traps**, **boundary cases** (zero, infinity, frictionless, sudden release), and **predict-first checks** |
| **MCQs** | Purely plug-and-chug arithmetic | Ask for **proportionality/scaling** ("if mass doubles and radius halves..."), **4-option AP format**, and **delayed answer reveals** |
| **FRQs** | Hand-wavy paragraphs without physics principles | Ask for **claim–evidence–reasoning**, **symbolic derivations**, **experimental procedure/error analysis**, and **rubric point mapping** |
