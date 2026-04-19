# Typst: Presentations:


## Review: 

**Typst** is designed around 3 core ideas:

- **Markup + Code Integration ** :
    - Unlike **LateX** which requires switching between "text mode" and "math mode" using complex
      back-slashes. Typst uses two distinct modes:
      - Markup Mode ( Default ): similar to markdown, you use `=` for heading, `*` for bold and `-` for
        lists. It's clean and easy to read. 
      - Code Mode ( The `#` sign ): Whenever you type a `#` you enter a scripting env. You can use
        variables, loops, ( `for` ) and conditionals ( `if` ).
      Example: 
        ` #let name = Alice` or `#for i in range(3) [ *Hello!* ]`

- **Instant compilations:**
    -  Typst uses incremental compilation. It only re-calculates the parts of the document you actually
       changed, meaning your preview updates in milliseconds.

- **Consistency and Composabiility** 
    - Instead of having 50 different ways to do one thing, Typst has a unified system of **Set Rules** and
      **Show Rules**:
      - Set Rules: "Make all my text 12pt" ( `#set text(size: 12pt)` )
      - SHow Rules: "Whenever you see a heading, make it blue and put a line under it"

- Typst Universe: An official centralized package repo and community hub for typst.
  [Universe](https://typst.app/universe) 

- In LateX when we need a package its either present in the TeX package that is installed of requires a
  download opackage that is installed of requires a download of `.sty`. Universe change that entirely :
  `#import "@preview/touying:0.5.3` Typst compiler automatically knows to look in the Universe, download
  that specific version, and cache it for you. 

- Templates: Its a full premade templates for resumes, Scientific journals and presentations ( like
  Touying/Metropolis ...)

- Vetting: Unlike a random GitHub repo, packages in the Universe follow a specific naming convention and
  versioning system, making your documents more "reproducible", which means if you open your file in 5 
  years, it will still work because it’s locked to a specific version of the package.

------

## Presentations: using Touying / Metropolis themes:

- **Touying** library is "gold standard" for creating presentations in Typst. 

- **Metropolis** theme is a port of the famous, minimalist LaTeX Beamer theme.


Here is a quick-start tutorial to get you up and running with a Metropolis-style presentation.

---

### 1. Setting Up the Document

Fist import the package at the top of your `.typ` file.

```typst
#import "@preview/touying:0.5.3": *
#import "@preview/touying-metropolis:0.1.0": *

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Introduction to Typst],
    subtitle: [Presenting with Metropolis],
    author: [Your Name],
    date: datetime.today().display(),
  ),
)
```

---

### 2. Creating Slides

- Touying uses level-one headings (`=`) for sections and level-two headings (`==`) to automatically create 
  new slides.

#### Title Slide & Sections

- The 1st slide is usually generated automatically by the theme `config`, but you can add sections to 
  organize your progress bar.

```typst
= Getting Started

== The First Slide
This is a standard slide. You can use standard Typst formatting here:
* **Bold text** for emphasis.
* List items for clarity.
* #link("https://typst.app")[Links] to external resources.
```

---

### 3. Advanced Layouts
Metropolis in Typst supports several specialized slide types to make your deck look professional.

#### Focus Slides
If you want a slide with a dark background and centered text (perfect for big quotes or transition points), use the `focus-slide`:

```typst
#metropolis-theme.focus-slide[
  Questions?
]
```

#### Multiple Columns
You can easily split your slide into columns using Typst's native `grid` function:

```typst
== Comparison Slide
#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  [
    === Column A
    - Point 1
    - Point 2
  ],
  [
    === Column B
    - Point 3
    - Point 4
  ]
)
```

---

### 4. Dynamic Content (Animations)

One of the best features of Touying is how it handles "pauses" or incremental lists. 

You use the `#pause` keyword to tell the presentation to create a new sub-slide.

```typst
== Incremental Reveal
1. First, you see this.
#pause
2. Then, this appears.
#pause
3. Finally, the conclusion!
```

---

## 5. Summary of Key Commands

| Feature | Command / Syntax |
| :--- | :--- |
| **New Section** | `= Section Name` |
| **New Slide** | `== Slide Title` |
| **Highlight Slide** | `#metropolis-theme.focus-slide[Text]` |
| **Step-by-step** | `#pause` |
| **Images** | `#image("path.png", width: 80%)` |

---

### Tips for Success
* **Live Preview:** 
    - If you are using the Typst Web App or the VS Code "Typst Preview" extension, you will see your 
      slides update instantly as you type.

* **Math:** 
    - Remember that math in Typst is enclosed in `$` symbols but uses a leaner syntax (ex: `$sum_(i=1)^n$` 
      instead of `\sum_{i=1}^{n}`).
