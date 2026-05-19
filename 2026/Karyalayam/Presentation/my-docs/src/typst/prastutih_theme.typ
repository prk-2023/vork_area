// ── IMPORTS ──────────────────────────────────────────────────────────────────
// Touying is the core framework for slides in Typst
#import "@preview/touying:0.7.1": *
// Metropolis is the specific theme logic (colors, layouts, title slides)
#import themes.metropolis: *
// Numbly helps with custom heading numbering (e.g., "1.1")
#import "@preview/numbly:0.1.0": numbly
// Mermaid allows for rendering diagrams/flowcharts within slides
#import "@preview/mmdr:0.2.2": mermaid

// ── COLOR PALETTE ────────────────────────────────────────────────────────────
// Defining brand-specific colors here ensures consistency across all slides
#let rust-red     = rgb("#CE422B")
#let rust-dark    = rgb("#1A1A1A")
#let safe-green   = rgb("#2D6A4F")
#let warn-amber   = rgb("#B5460F")
#let ref-blue     = rgb("#1B4F8A")
#let code-bg      = rgb("#1E1E2E") // Background for dark mode code blocks
#let code-fg      = rgb("#CDD6F4")
#let kw-color     = rgb("#CBA6F7")
#let cm-color     = rgb("#6C7086")
#let st-color     = rgb("#A6E3A1")
#let er-color     = rgb("#F38BA8")
#let hi-color     = rgb("#FAB387")
#let skyblue      = rgb("#40A3FF")

// ── UI COMPONENTS & HELPERS ──────────────────────────────────────────────────

// Callout: A box with a thick left border for highlighting important notes
#let callout(body, color: rust-red) = block(
  fill: color.lighten(90%),
  stroke: (left: 3pt + color),
  inset: (left: 10pt, top: 7pt, bottom: 7pt, right: 9pt),
  radius: (right: 4pt),
  width: 100%,
  body,
)

// Ref-badge: A small pill-shaped label for academic or technical citations
#let ref-badge(body) = box(
  fill: ref-blue.lighten(88%),
  stroke: 0.4pt + ref-blue,
  inset: (x: 6pt, y: 2pt),
  radius: 3pt,
  text(fill: ref-blue, size: 0.6em, style: "italic", body)
)

// Cols: Simplifies side-by-side content (left/right columns)
#let cols(left, right, ratio: (1fr, 1fr)) = grid(
  columns: ratio,
  gutter: 1.2em,
  left, right,
)

// Codeblock: A stylized container for raw code with an optional header label
#let codeblock(body, title: none) = {
  // If a title is provided, create a small header tab above the code
  if title != none {
    block(
      fill: rust-red.lighten(88%),
      inset: (x: 10pt, y: 4pt),
      radius: (top: 5pt),
      width: 100%,
      text(size: 0.65em, weight: "bold", fill: rust-red, title)
    )
  }
  // The main code body with specific monospaced font stack
  block(
    fill: code-bg,
    radius: if title != none { (bottom: 5pt) } else { 5pt },
    inset: 12pt,
    width: 100%,
    //text(font: ("Noto Sans","JetBrains Mono","Liberation Mono"), fill: code-fg, size: 0.72em, body)
    text(fill: code-fg, size: 0.72em, body)
  )
}

#let pipe-box(n, title, body, color: ebpf-teal) = block(
  fill:   color.lighten(90%),
  stroke: 0.5pt + color,
  radius: 6pt,
  inset:  10pt,
  width:  100%,
  stack(dir: ltr, spacing: 8pt,
    circle(fill: color, radius: 9pt,
      align(center + horizon,
        text(fill: white, size: 0.65em, weight: "bold", str(n)))),
    stack(dir: ttb, spacing: 3pt,
      text(size: 0.75em, weight: "bold", fill: color, title),
      text(size: 0.68em, fill: luma(40%), body),
    ),
  ),
)
// Inline syntax highlighting helpers (usage: #kw[fn], #cm_[// comment])
#let kw(t)  = text(fill: kw-color,  raw(t))
#let cm_(t) = text(fill: cm-color,  raw(t))
#let st_(t) = text(fill: st-color,  raw(t))
#let ok_(t) = text(fill: st-color,  t)
#let er_(t) = text(fill: er-color,  t)
#let hi_(t) = text(fill: hi-color,  t)

// Anno: Small italicized text usually used for section tags in corner
#let anno(body) = align(right, text(size: 0.6em, fill: gray.lighten(20%), style: "italic", body))

// Fancy-block: A modern card-style box for summarizing parts of a presentation
#let fancy-block(title, subtitle, pts) = box(
    fill: rgb("#2b2b2b"),
    stroke: none,
    radius: 12pt,
    inset: 12pt,
  )[
    #text(fill: rust-red, weight: "bold")[#title]
    #linebreak()
    #text(fill: rgb("#ccc"), size: 0.9em)[#subtitle]
    #linebreak()
    #text(fill: rgb("#999"), size: 0.63em)[#pts]
  ]

// ── MASTER THEME CONFIGURATION ──────────────────────────────────────────────
// This function wraps the entire document. When you call 'show: setup-presentation',
// all the logic inside here is applied to your slides.
#let setup-presentation(title: "", author: "", institution: "", doc) = {
  
  // Initialize the Metropolis theme logic
  show: metropolis-theme.with(
    aspect-ratio: "16-9",
    footer: self => self.info.institution, // Footer pulled from config-info

    config-colors(
      primary: rust-red,
      primary-dark: rust-red.darken(20%),
      primary-light: rust-red.lighten(55%),
      secondary: safe-green, //skyblue, //safe-green,
      neutral-lightest: rgb("#F9F8F6"),
      neutral-light: rgb("#EBEBEA"),
      neutral-dark: rgb("#3A3A3A"),
      neutral-darkest: rust-dark,
    ),
    
    // Slide metadata
    config-info(
      logo: image("./rust-r.png", height: 1.5em),
      title: title,
      author: author,
      date: datetime.today(),
      institution: institution,
    ),
  )
  // GLOBAL STYLING
  // Set the default sans-serif font stack for readability
  //set text(font: ("Noto Sans","Noto Sans","Liberation Sans"), size: 15pt)
  set text(size: 15pt)
  
  // Style all raw code blocks globally
  //show raw: set text(font: ("Noto Sans","JetBrains Mono","Liberation Mono"), size: 0.81em)
  show raw: set text(size: 0.81em)
  
  // Make links match the brand color
  show link: set text(fill: rust-red)
  
  // Use 'numbly' to format section headings (e.g., "1. Introduction")
  set heading(numbering: numbly("{1}.", default: "1.1"))
  
  // Return the document with all settings applied
  doc
}

#let hero-slide(
  img: none, topic-title: "", topic-subtitle: ""
) = {
  focus-slide[
    #place(
      top + left,
      dx: 0pt,
      dy: 0pt,
      image(
        img,
        width: 100%,
        height: 100%,
        fit: "stretch",
      )
    )

    // dark overlay
    // #place(
    //   top + left,
    //   rect(
    //     width: 100%,
    //     height: 100%,
    //     stroke: none,
    //   )
    // )

    #v(54%)

    #align(center)[
      #text(
        fill: white,
        size: 18pt,
        weight: "bold",
        style:"italic"
      )[
        #topic-title
      ]

      #text(
        fill: white,
        size: 12pt,
      )[
        #topic-subtitle
      ]
    ]
  ]
}

// How to use this theme: 
// Example file:  rust_intoduction.typ
//
// // ────────────────────────────────────────────────────────────────────────────
// // ── EXTERNAL TEMPLATE IMPORT ────────────────────────────────────────────────
// // This pulls in all your colors, logic, and metropolis settings from theme.typ
// #import "theme.typ": *
//
// // ── GLOBAL CONFIGURATION ───────────────────────────────────────────────────
// // This 'show' rule passes your content through the 'setup-presentation' 
// // function defined in theme.typ. This is where you set the metadata.
// #show: doc => setup-presentation(
//   title: [Introduction to Rust & eBPF with Rust],
//   author: [XYZ],
//   institution: [My Company],
//   background-img: "assets/background-texture.png",
//   doc
// )
//
// // ─────────────────────────────────────────────────────────────────────────────
// // START OF CONTENT
// // ─────────────────────────────────────────────────────────────────────────────
//
// // Renders the automatic title slide based on the config-info in your theme
// #title-slide()
//
// // Focus slides are specialized Metropolis layouts for big, centered text
// #focus-slide[
//   #text(size: 1.2em, weight: "bold")[
//     #underline(stroke: 1pt + rust-red)[> Disclaimer <]
//   ]
//
//   #v(0.8em)
//
//   #text(fill: rgb("#f66"))[
//     Focus on systems evolution, not a language war
//   ]
//   
//   #line(length: 63%, stroke: 1pt + rust-red)
//   #v(0.5em)
//
//   - Rust in the Linux kernel - #linebreak()
//   - Direction and practical utility - 
// ]
//
// // Another focus slide using the 'fancy-block' helper defined in theme.typ
// #focus-slide[
//   #v(0.3em)
//
//   #fancy-block("Part #1", "Rust as a systems programming language","zero-cost abstraction, Borrow checker, memory layout ctrl, Fearless concurrency" )
//
//   #v(0.3em)
//
//   #fancy-block("Part #2", "Rust in the Linux kernel", "chronological update, build, adoption map")
//
//   #v(0.3em)
//
//   #fancy-block("Part #3", "eBPF programming with Rust","Aya framework, observability case study")
// ]
//
// // A Top-level heading (=) creates a Section Divider slide in Metropolis
// = Why Rust : A Systems Programmer's Perspective:
//
// #text(fill: black)[`Memory Safety`]
// #text(fill: black)[· `Compiler Guarantees`]
// #text(fill: black)[· `Modern Concepts`]
// #text(fill: black)[· `performance`]
//
// // A double heading (==) creates a standard slide with a title at the top
// == The eternal memory bug
//
// // Using the 'cols' helper for side-by-side layout
// #cols[
//   *The numbers haven't moved in 20 years*
//
//   - *~70 %* of Microsoft CVEs are memory safety bugs
//     #ref-badge[Microsoft Security Response Centre, 2019] // Using our custom ref-badge
//     
//   - *~67 %* of Linux kernel CVEs are memory safety violations
//     #ref-badge[Gaynor & Thomas, 2019]
//
//   // Using our custom callout box with the accent bar
//   #callout[
//     The only way to eliminate a class of bugs is to make them unrepresentable in the type system.
//   ]
// ][
//   *The root causes*
//
//   #table(
//     columns: (auto, 1fr),
//     stroke: (x: none, y: 0.4pt + gray.lighten(40%)),
//     inset: (y: 6pt, x: 4pt),
//     [*Cause*], [*C has no protection against...*],
//     [Use-after-free], [accessing freed memory via a dangling pointer],
//     [Buffer overflow], [writing past the end of an allocation],
//     [Data race], [two threads accessing shared memory without synchronisation],
//   )
// ]
//
// // Three dashes (---) create a new slide while keeping the same title
// ---
//
// #cols[
//   // Overriding the default color of the callout
//   #callout(color: safe-green)[
//     Rust *eliminates every row in this table* at compile time, with zero runtime overhead.
//   ]
// ][
//   #table(
//     columns: (auto, 1fr),
//     stroke: (x: none, y: 0.4pt + gray.lighten(40%)),
//     inset: (left: 1pt, top: 1pt, bottom: 7pt, right: 0pt),
//     [*Cause*], [*C has no protection against...*],
//     [Use-after-free], [accessing freed memory via a dangling pointer],
//     [Buffer overflow], [writing past the end of an allocation],
//   )
// ]
