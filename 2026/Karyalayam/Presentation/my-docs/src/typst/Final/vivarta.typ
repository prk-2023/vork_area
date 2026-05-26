// =============================================================================
// ── IMPORTS & EXTERNAL DEPENDENCIES ──────────────────────────────────────────
// =============================================================================

// Touying is the core framework used for rendering presentation slides in Typst.
#import "@preview/touying:0.7.1": *

// Metropolis provides the specific slide theme logic (layouts, palettes, headers).
#import themes.metropolis: *

// Numbly simplifies custom numbering configurations for section headings (e.g., "1.1").
#import "@preview/numbly:0.1.0": numbly

// NOTE: Mermaid diagram support via '@preview/mmdr:0.2.2' is currently disabled 
// due to immature upstream rendering behavior.


// =============================================================================
// ── BRAND COLOR PALETTE ──────────────────────────────────────────────────────
// =============================================================================

// Main Accent & UI Layout Colors
#let rust-red     = rgb("#CE422B") // Primary brand identity color
#let rust-dark    = rgb("#1A1A1A") // Deep dark neutral for text/backgrounds
#let safe-green   = rgb("#2D6A4F") // Success, validation, and safe state indicator
#let warn-amber   = rgb("#B5460F") // Warnings, attention grabbers, and minor alerts
#let ref-blue     = rgb("#1B4F8A") // Academic/technical citation badge color
#let skyblue      = rgb("#40A3FF") // Optional alternative secondary color

// Domain-Specific Theme Colors
#let ebpf-teal    = rgb("#0D7377") // Theme color for eBPF-related components
#let libbpf-blue  = rgb("#1565C0") // Theme color for libbpf-related components

// Syntax Highlighting Colors (Designed for light/dark code blocks)
#let code-bg      = rgb("#1E1E2E") // Background color for dark mode environments
#let code-fg      = rgb("#CDD6F4") // Default foreground color for dark code text
#let kw-color     = rgb("#CBA6F7") // Keywords
#let cm-color     = rgb("#6C7086") // Comments
#let st-color     = rgb("#A6E3A1") // Strings / Success syntax states
#let er-color     = rgb("#F38BA8") // Errors / Formally rejected tokens
#let hi-color     = rgb("#FAB387") // Highlights / Captured variables


// ── Helpers ───────────────────────────────────────────────────────────────────

// =============================================================================
// ── UI COMPONENTS & LAYOUT HELPERS ──────────────────────────────────────────
// =============================================================================

/// Renders a basic light-gray padded box container for organizing content.
/// - content (content): The text, code, or elements to wrap inside the box.
#let codebox(content) = rect(
  width: 100%,
  fill: rgb("#fff9f9"),
  stroke: 0.5pt + gray,
  radius: 3pt,
  inset: 10pt,
  content
)

/// Renders a 3-column horizontal grid comparing architecture stages or paradigms.
/// Intended for side-by-side framework performance or timeline analysis.
/// - stage (string|content): The category or timeline step being compared.
/// - c-col (string|content): Description for the "C / libbpf" column.
/// - rust-col (string|content): Description for the "Rust / eBPF" column.
#let vs-row(stage, c-col, rust-col) = {
  grid(
    columns: (1fr, 1fr, 1fr),
    gutter: 5pt,
    block(fill: luma(240), radius: 4pt, inset: (x:8pt, y:5pt), width: 100%,
      text(size: 0.68em, weight: "bold", stage)),
    block(fill: libbpf-blue.lighten(90%), radius: 4pt, inset: (x:8pt, y:5pt), width: 100%,
      text(size: 0.68em, fill: libbpf-blue.darken(20%), c-col)),
    block(fill: ebpf-teal.lighten(90%), radius: 4pt, inset: (x:8pt, y:5pt), width: 100%,
      text(size: 0.68em, fill: ebpf-teal.darken(10%), rust-col)),
  )
  v(1pt)
}

/// Creates a prominent callout/info box with a thick left-side border indicator.
/// - body (content): The main message or alert text.
/// - color (color): The identity color governing the background tint and left border.
#let callout(body, color: rust-red) = block(
  fill: color.lighten(90%),
  stroke: (left: 3pt + color),
  inset: (left: 10pt, top: 7pt, bottom: 7pt, right: 9pt),
  radius: (right: 4pt),
  width: 100%,
  body,
)

/// Renders a small, compact, pill-shaped label ideal for papers or bibliography index chips.
/// - body (content): The reference name, year, or index tag (e.g., "McSmith '24").
#let ref-badge(body) = box(
  fill: ref-blue.lighten(88%),
  stroke: 0.4pt + ref-blue,
  inset: (x: 6pt, y: 2pt),
  radius: 3pt,
  text(fill: ref-blue, size: 0.6em, style: "italic", body)
)

/// Simplifies layout distribution by organizing content side-by-side in columns.
/// - left (content): Node elements assigned to the left column.
/// - right (content): Node elements assigned to the right column.
/// - ratio (array): Sizing weights controlling column width splits. Defaults to equal space.
#let cols(left, right, ratio: (1fr, 1fr)) = grid(
  columns: ratio,
  gutter: 1.2em,
  left, right,
)

/// Draws a stylized, bordered block structure for source code. Supports an optional upper tab header.
/// - body (content): The actual block of code (typically passed as a raw block).
/// - title (none|string): Optional descriptor text displayed on a colored header tab.
#let codeblock(body, title: none) = {
  if title != none {
    block(
      fill: rust-red.lighten(88%),
      inset: (x: 10pt, y: 4pt),
      radius: (top: 5pt),
      width: 100%,
      text(size: 0.65em, weight: "bold", fill: rust-red, title)
    )
  }
  block(
    fill: rgb("#fffbf9"),
    radius: if title != none { (bottom: 5pt) } else { 5pt },
    inset: 12pt,
    width: 100%,
    stroke: 0.5pt + gray,
    text(fill: code-bg, size: 0.72em, body)
  )
}

/// Generates a sequenced card structure featuring an anchored badge step index number.
/// Ideal for execution pathways, data lifecycles, or logical steps.
/// - n (int): Sequence position identifier number.
/// - title (string|content): Short heading name for the pipeline step.
/// - body (content): Description explaining operations executed during this step.
/// - color (color): Core theme modifier color for the bounding accents.
#let pipe-box(n, title, body, color: ebpf-teal) = block(
  fill:  color.lighten(90%),
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

// ── INLINE SYNTAX HIGHLIGHTING HELPERS ───────────────────────────────────────
// Inline wrappers matching code tokens. Usage examples: #kw[fn], #cm_[// text]
#let kw(t)  = text(fill: kw-color,  raw(t)) // Language Keywords
#let cm_(t) = text(fill: cm-color,  raw(t)) // Syntax Comments
#let st_(t) = text(fill: st-color,  raw(t)) // Hardcoded Strings
#let ok_(t) = text(fill: st-color,  t)      // Status OK indicators
#let er_(t) = text(fill: er-color,  t)      // Status Error indicators
#let hi_(t) = text(fill: hi-color,  t)      // Arbitrary textual highlights

/// Aligns a micro text annotation label to the upper/lower right corner margin.
/// - body (content): Label context details (e.g., target section paths).
#let anno(body) = align(right, text(size: 0.6em, fill: gray.lighten(20%), style: "italic", body))

/// Formats a dark, modern card asset to encapsulate summaries or key highlight achievements.
/// - title (string|content): Primary message banner.
/// - subtitle (string|content): Contextual elaboration text.
/// - pts (content): Supplemental bulleted items or body details.
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


// =============================================================================
// ── MASTER PRESENTATION ENVIRONMENT SETUP ────────────────────────────────────
// =============================================================================

/// This master configuration orchestrates the design rules across slides.
/// Apply globally via an initialization rule at the top of document execution:
/// `#show: setup-presentation.with(title: "My Title", author: "Name")`
///
/// - title (string): The presentation presentation title name.
/// - author (string): The author's name or publishing organization.
/// - institution (string): Institutional/corporate entity printed in the footer.
/// - doc (document): Caught inner slide engine elements target for theme conversion.
#let setup-presentation(title: "", author: "", institution: "", doc) = {
  
  // Configure Metropolis infrastructure layout metrics
  show: metropolis-theme.with(
    aspect-ratio: "16-9",
    footer: self => self.info.institution,

    config-colors(
      primary: rust-red,
      primary-dark: rust-red.darken(20%),
      primary-light: rust-red.lighten(55%),
      secondary: safe-green, 
      neutral-lightest: rgb("#F9F8F6"),
      neutral-light: rgb("#EBEBEA"),
      neutral-dark: rgb("#3A3A3A"),
      neutral-darkest: rust-dark,
    ),
    
    config-info(
      logo: image("./imgs/rust-r.png", height: 1.5em),
      title: title,
      author: author,
      date: datetime.today(),
      institution: institution,
    ),
  )

  // Configure Global Elements
  set text(size: 15pt)
  show raw: set text(size: 0.81em)
  show link: set text(fill: rust-red)
  
  // Enforce hierarchical heading structures using the custom Numbly patterns
  set heading(numbering: numbly("{1}.", default: "1.1"))
  
  doc
}


// =============================================================================
// ── PRESENTATION SLIDE TEMPLATES ─────────────────────────────────────────────
// =============================================================================

/// Generates an impactful full-screen image slide featuring a lower overlay message title.
/// Built over Touying's baseline `#focus-slide` environment.
/// - img (string): System filepath string positioning the primary backdrop image background.
/// - topic-title (string|content): Prominent stylized focus headline string.
/// - topic-subtitle (string|content): Secondary description copy text located directly beneath.
#let hero-slide(
  img: none, topic-title: "", topic-subtitle: ""
  ) = {
  focus-slide[
    // Backdrop Image Mapping
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

    // Optional Dark Overlay Block: Uncomment if background images conflict with text contrast
    // #place(
    //   top + left,
    //   rect(width: 100%, height: 100%, stroke: none, fill: rgb(0, 0, 0, 40%))
    // )

    // Push descriptive titles downward to prevent asset collisions
    #v(54%)

    #align(center)[
      #text(
        fill: white,
        size: 18pt,
        weight: "bold",
        style: "italic"
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
