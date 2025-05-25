# Typst:

Typst is a tool that is written in Rust, which is comparative to LaTeX.
A quick take is its like Markdown with Functions, but there is more to it.

*Typst* is a new markup based scripting system that is designed to be as powerful as LaTeX while being much 
easier to learn and use.

Supports the following:

* Builtin markup for the most common formatting tasks.
* Flexible functions for everything else
* A tightly integrated scripting system
* Math Typesetting, bibliography management and more
* faster compilation time ( uses incremental compilation )
* User friendly error messages if some thing goes wrong.

Typst is good for writing any long form of text such as essays, articles, scientific papers, books, reports,
and homework assignments. 
It's also great tool for any document that contains mathematical notations, such as papers in math, physics,
and engineering fields.


Core Concept of Typst:
- Markdown Style: Uses clean, readable syntax that's more approachable then LaTeX. 
- Programmable: It supports functions, loops, conditions and variables, enabling logic-driven document
  generation, which is messy in LaTeX.
- Builtin Layout Engine: Unlike LaTeX which relies in macro packages, Typst includes built-in layout model
  for better layout precision and flexibility. 

Main Features:
- Template System: Easily re-usable document structures and styles similar to HTML templates and themes.
- Mathematics support: Full support of mathematical notations like LaTeX.
- Customization of Logic: Support *inline expressions* computed content and document-level logic.
- Cross-reference & Citations: Native support for references, citations and bibliography.
- Real-time Compilation: much faster and more responsive then LaTeX. Works great with online editors or live
  previews.
- No external dependencies: everything needed to compile a document is included- no need to install extra
  packages line in LaTeX.
- built-in scripting: You can define *functions and modules*, enabling modular document structures.

Design & Visuals:
- Precise layout tools: Grid, alignments, page layouts and advanced typographic tools.
- Vector Graphics: Create and manipulate vector graphics inline.
- Modern Typography: Advanced font handling, kerning and Onetype features. 
- Multicolumn and Flow layouts: More intuitive and powerful layout handling than LaTeX floating
  environments.

WorkFlow and Tooling: 
- CLI tool: easy to integrate into automation or build pipelines
- Typst previewer: Typst has its own online editor and local review tools.
- Web Integration: Typst is built with an eye towards the web including webassembly support for rendering in
  browsers. 

Drawbacks:
- It's not 1:1 compatible with LaTeX, which means you can not directly import LaTeX documents without
  rewriting them.
- Relatively new but its very capable, and has a smaller ecosystem than LaTeX.


---
Quick learning flow:

- Core Document formatting:
    - Heading, paragraphs, lists
    - Bold, italic, underline
    - Quotes and code blocks.
    - page breaks and sections
    - tables columns 
    - bullets and number notations
    
- Math Support:
    - Inline Math $x^2 +y^2 = z^2$
    - Display math  : $$\int_{0}^{\infty} e^{-x} dx = 1$$
    - Common symbols: Greek letters, operators, relations
    - matrices, fractions, roots and aligned equations
    Ref: https://typst.app/docs/reference/math/

- Customization Logic: Leverage Typst scripting-like features
    - Use *variables* for reusable content
    - Define functions for logic and formatting
    - Embed *inline expressions* like #(x + y)
    Ex: 
        #set name = "daybian"
        Hello #name!

    The goal is to create dynamic maintainable documents.

- Layout Tools: Control how elements appear on the page:
    - Columns, grid and stacks.
    - Boxes and frames
    - positioning and alignments
    - margins, padding, spacing
    Ref: https://typst.app/docs/reference/layout/ 
    The goal is to professionally arrange content and math on the page.

- Handling Fonts and Styling: Customize the visual style of your document:
    - Change fonts globally or locally
    - Use font familes, size, weights
    - Apply consistent style accross elements. 
    Ex:
        #set text(font: "Libertinus Serif", size:12pt)
    Goal is to make the document look polished and consistent.

- Figures and Images: Enhance document with visual elements:
    - Insert Images using *image("/path/to/file")*
    - set width, height, alignment 
    - Add captions and labels
    Goal is add diagrams or plots alongside math content.

- Tables: Create Structured tables:
    - With header row
    - styled with boarders and spcaing
    - combine with inline math when needed 
    Goal is to present data or organized information cleanly.
    
- bibliography and Citations: ( this is useful for writing academic or techinical papers)
    - use bibliography files ( BibTeX .bib support)
    - Use @cite(key) for inline citations
    - Format references lists automatically
    Ref: https://typst.app/docs/reference/model/cite/
    Goal is properly cite sources in a professional format. 

- Cross-reference and Labeling: ( refer to figures, equation or sections by label)
    - Label with *=label("eq1")*
    - Reference with @eq1
    Goal: Keep references dynamic and accurate, especially in academic area.

- Templates and Reusability: ( Learn to use and create document templates)
    - Cover pages, headers, footers
    - Shared styles and layouts
    - Define your own components for reuse.
    Goal: is to speedup future writing and maintain consistency across projects. 

---

NOTE:
    Like with LaTeX learning its best to start writing a document with full math and other features. 
    
--- 

## Simple document:
    - Basic structures of formatting 
    - Inline and display math 
    - A small function or variable 
    - Custom layout ( ex: columns of framed box )
    - A citation or labeled figure/tables

- Example 1: Simple typst document that includes key features ( with math academic writing ):
    Includes:
    - Document structure and formatting
    - Inline and display math
    - variables and functions
    - custom layout with a box
    - A figure (placeholder) with caption 
    - Table with inline math
    - Cross-references
    - Citations ( mocked BibTeX entry)

Example1:
Edit file ex1.typ
```typst 
#let title = "A Short Note on the Pythagorean Theorem"
#let author = "Jane Doe"
#let date = "2025-05-25"

#heading(title)
#author
#date

#heading[Introduction]

The Pythagorean theorem is a fundamental principle in Euclidean geometry. It states that in a right triangle, the square of the hypotenuse equals the sum of the squares of the other two sides:

$ a^2 + b^2 = c^2 $

This theorem is useful in many fields such as architecture, physics, and computer science.

#heading[Math and Logic]

We define a quick function to compute the hypotenuse length:

#let hypotenuse(a, b) = $sqrt(a^2 + b^2)$

For example, if `a = 3` and `b = 4`, then the hypotenuse is:

#hypotenuse(3, 4) // --- = $ \sqrt{3^2 + 4^2} = 5 $

You can also align multiple equations:

$$
\begin{aligned}
a^2 + b^2 &= c^2 \\
3^2 + 4^2 &= 9 + 16 = 25 = 5^2
\end{aligned}
$$

#heading[Visuals and Layout]

Here is a diagram representing a right triangle:

#figure(
  image("triangle.png", width: 40mm),
  caption: [Right triangle showing sides a, b, and hypotenuse c.],
) =fig-triangle

#box(
  inset: 6pt,
  fill: luma(240),
  [This box highlights a key result: $ c = sqrt{a^2 + b^2} $]
)

#heading[Table Example]

Below is a small table showing sample values:

#table(
  columns: 3,
  [ ["a", "b", "c = $sqrt{a^2 + b^2}$"],
    ["3", "4", "#hypotenuse(3, 4)"],
    ["5", "12", "#hypotenuse(5, 12)"]
  ]
)

#heading[Citation Example]

As noted in classical geometry literature @euclid, the theorem has ancient origins.

#bibliography("refs.bib")

#heading[Conclusion]

Typst allows math, logic, and structure to blend seamlessly. From inline formulas like $x^2$ to reusable functions and clean layout tools, Typst simplifies scientific writing.
```

Edit :  refs.bib
```BibTeX 
@book{euclid,
  author    = {Euclid},
  title     = {Elements},
  year      = {300 BC},
  publisher = {Ancient Greece}
}
```
copy some png file as triangle.png 

Compile to PDF:

```bash 
$ ls -l
total 16
-rw-r--r-- 1 daybian daybian 1713 May 25 08:31 ex1.typ
-rw-r--r-- 1 daybian daybian  121 May 25 08:31 refs.bib
-rw-r--r-- 1 daybian daybian 5004 May 25 08:30 triangle.png

$ typst compile ex1.typ

$ xpdf ex1.pdf
```
