#import  "prastutih_theme.typ": *

// Global Configuration:
#show: doc => setup-presentation(
  title: [Introduction to Rust & eBPF with Rust],
  author: [ Pulumati Ram ],
  institution: [ RealTek Semiconductor Corporation ],
  logo: [ "rust.png" ],
  doc
)

// Renders the automatic title slide based on the config-info in your theme
#title-slide()
// Focus slides are specialized Metropolis layouts for big, centered text
#focus-slide[
  #text(size: 1.2em, weight: "bold")[
    #underline(stroke: 1pt + rust-red)[> Disclaimer <]
  ]

  #v(0.8em)

  #text(fill: rgb("#f66"))[
    Focus on systems evolution, not a language war
  ]
  
  #line(length: 63%, stroke: 1pt + rust-red)
  #v(0.5em)

  - Rust in the Linux kernel - #linebreak()
  - Direction and practical utility - 
]

// Another focus slide using the 'fancy-block' helper defined in theme.typ
#focus-slide[
  #v(0.3em)

  #fancy-block("Part #1", "Rust as a systems programming language","zero-cost abstraction, Borrow checker, memory layout ctrl, Fearless concurrency" )

  #v(0.3em)

  #fancy-block("Part #2", "Rust in the Linux kernel", "chronological update, build, adoption map")

  #v(0.3em)

  #fancy-block("Part #3", "eBPF programming with Rust","Aya framework, observability case study")
]

// A Top-level heading (=) creates a Section Divider slide in Metropolis
= Why Rust : A Systems Programmer's Perspective:

#text(fill: black)[`Memory Safety`]
#text(fill: black)[· `Compiler Guarantees`]
#text(fill: black)[· `Modern Concepts`]
#text(fill: black)[· `performance`]

// A double heading (==) creates a standard slide with a title at the top
== The eternal memory bug

// Using the 'cols' helper for side-by-side layout
#cols[
  *The numbers haven't moved in 20 years*

  - *~70 %* of Microsoft CVEs are memory safety bugs
    #ref-badge[Microsoft Security Response Centre, 2019] // Using our custom ref-badge
    
  - *~67 %* of Linux kernel CVEs are memory safety violations
    #ref-badge[Gaynor & Thomas, 2019]

  // Using our custom callout box with the accent bar
  #callout[
    The only way to eliminate a class of bugs is to make them unrepresentable in the type system.
  ]
][
  *The root causes*

  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.4pt + gray.lighten(40%)),
    inset: (y: 6pt, x: 4pt),
    [*Cause*], [*C has no protection against...*],
    [Use-after-free], [accessing freed memory via a dangling pointer],
    [Buffer overflow], [writing past the end of an allocation],
    [Data race], [two threads accessing shared memory without synchronisation],
  )
]

// Three dashes (---) create a new slide while keeping the same title
---

#cols[
  // Overriding the default color of the callout
  #callout(color: safe-green)[
    Rust *eliminates every row in this table* at compile time, with zero runtime overhead.
  ]
][
  #table(
    columns: (auto, 1fr),
    stroke: (x: none, y: 0.4pt + gray.lighten(40%)),
    inset: (left: 1pt, top: 1pt, bottom: 7pt, right: 0pt),
    [*Cause*], [*C has no protection against...*],
    [Use-after-free], [accessing freed memory via a dangling pointer],
    [Buffer overflow], [writing past the end of an allocation],
  )
]
