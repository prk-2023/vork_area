# Typst: ( Documentation system )

Refs: 
    - https://typst.app/docs/tutorial/writing-in-typst/

- It's a Markup-based typesetting system for Sciences, evolved out to make it simple to use then LaTeX. 

- The best way to start with formatting documents in Typst is by using the app ( https://typst.app/ )
  requires a free sign-up and can be used as google doc's to create online.

- Other way is to install typst ( cargo install typst-cli ), there are many other crates at crates.io that
  can be installed later after exploring further.

## Intro:

- Typst is a markup language for typesetting documents. Designed to easy to learn, fast and versatile.

- "typst" take's text file as input and generate them and outputs PDFs.

- Best for easy, articles, scientific papers, books, reports and homework assignments. Great fir for any
  documents containing mathematical notations, such as paper in math, physics, and engineering fields. 
  Due to its strong styling and automation features, it's a good choice for any set of documents that share
  a common style.

- Install nvim typst-preview plugin ( sync our git hub nvim configuration )

- $ typst --version 
  typst 0.13.1 (unknown hash)

- All of Typst has been designed with three key goals in mind: 
    Power, 
    simplicity, and 
    performance. 

  Developers think it's time for a system that matches the power of LaTeX, is easy to learn and use, 
  all while being fast enough to realize instant preview. 

### Writing in Typst:

- Create a typst document and compile into a PDF:

    #Creates `file.pdf` in working directory.
    $ typst compile file.typ
    
    #Creates PDF file at the desired path.
    typst compile path/to/source.typ path/to/output.pdf

    this will generate mydoc.typ  in the same folder.

- To automatically recompile your document whenever you make changes:

    $typst watch document.typ 

  This command will keep the terminal open and recompile the document whenever it's saved.
  This approch is faster then compiling from scratch each time as "typst" supports incremental compilation.

- Add custom font paths for your proj and list all of the fonts it discovered:

    #Adds additional directories to search for fonts.
    $typst compile --font-path path/to/fonts file.typ

    #Lists all of the discovered fonts in the system and the given directory.
    $typst fonts --font-path path/to/fonts
    
    #Or via environment variable (Linux syntax).
    TYPST_FONT_PATHS=path/to/fonts typst fonts

- $typst help
  Typst 0.13.1 (unknown hash)
  Usage: typst [OPTIONS] <COMMAND>
  Commands:
    compile  Compiles an input file into a supported output format [aliases: c]
    watch    Watches an input file and recompiles on changes [aliases: w]
    init     Initializes a new project from a template
    query    Processes an input file to extract provided metadata
    fonts    Lists all discovered fonts in system and custom font paths
    help     Print this message or the help of the given subcommand(s)

  Options:
      --color <COLOR>  Whether to use color. When set to `auto` if the terminal
                       to supports it [default: auto] [possible values: auto,
                       always, never]
      --cert <CERT>    Path to a custom CA certificate to use when making
                       network requests [env: TYPST_CERT=]
    -h, --help           Print help
    -V, --version        Print version

  Resources:
    Tutorial:                 https://typst.app/docs/tutorial/
    Reference documentation:  https://typst.app/docs/reference/
    Templates & Packages:     https://typst.app/universe/
    Forum for questions:      https://forum.typst.app/

- subtopic help

    $typst help watch


## Writing in Typst:

Specific symbols called "markups" have special meanings in typst. 
Having a symbol for every thing can make the typst document complex and cryptic, so typst reserves markup,
symbols only for the most common things every thing else is inserted into the document via functions.

- Header:

    = Title 1 ( header 1 )
    == Title 2 ( header 2 )
    === Title 1 ( header 3 )
    ==== Title 1 ( header 4 )
    ===== Title 1 ( header 5 )

- Numbered List:

    + Item 1            1. Item 1
    + Item 2    =>      2. Item 2
    + Item 1            3. Item 3

- bullets:

    - Item 1            * Item 1
    - Item 2    =>      * Item 2
    - Item 1            * Item 3

- Mix above 

    + Item 1            1. Item 1
        - subItem 1         * subItem 1
        - subItem 2         * subItem 2
    + Item 2    =>      2. Item 2
    + Item 1            3. Item 3

- Italics:

    Prefix and suffix (_) to a word to get italics words, This _example_ is simple 

- Bold:

    Prefix and suffix * to a word to get italics words, This *example* is simple 

- Insert Image:

    - To insert image in typst we use the typst markup function as below:

        #image("rust_crab.png")
        #image("rust_crab.png", width: 50%)
        #image("rust_crab.png", width: 5cm)
        #image("rust_crab.png", width: 2.5in)


- Figure with caption:

        #figure (
            image("rust_crab.png", width: 50%)
            caption: [_rust programming language logo is red _crab_ ],
        )

- Refer to the above Figure in the following text can be done using "@label", this requires the above figure
  to set label that can be referred. 

    ```
    Crab as shown in @rust_logo is the logo used to represent the rust file or folder:
    
    #figure (
            image("rust_crab.png", width: 50%)
            caption: [_rust programming language logo is red _crab_ ],
        ) <rust_logo>

    ```
- Bibliography : To add Bibliography to document with bibliography function. This function expects a path 
  to a bibliography file.
  For compatibility you can also use BibLaTeX files.
  Once the document contains a bibliography, you can start citing from it. 
  Citations use the same syntax as references to a label. 
  As soon as you cite a source for the first time, it will appear in the bibliography section of your doc. 
  Typst supports different citation and bibliography styles.

    ```
    = Methods
    We follow the glacier melting models
    established in @glacier-melt.
    #bibliography("works.bib")
    ```

- Math:

- Typst has built in mathematical typesetting and uses its own notations.

- A equation is wrap it in $ signs to let Typst know it should be expect a mathematical equation.

    => Inline mathematical expression on same line ( no space after starting $ and ending $)
        - The equation $Q = rho A v + C$ 
          defines the glacial flow rate.

    => Equation on new line add a space after $ as below:

        - The flow rate of a glacier is
          defined by the following equation:   $ Q = rho A v + C $

- Math mode will always show single letters verbatim. 
  Multiple letters, however, are interpreted as symbols, variables, or function names.

  => To imply a multiplication between single letters, put spaces between them:
  If you want to have a variable that consists of multiple letters, you can enclose it in quotes:

    - The flow rate of a glacier is given
      by the following equation:
      $ Q = rho A v + "time offset" $

- sum formula in your document.
  Use the sum symbol and then specify the range of the summation in sub- and superscripts:

    - Total displaced soil by glacial flow:
      $ 7.32 beta +
       sum_(i=0)^nabla Q_i / 2 $
   
- Add subscript to a symbol or variable, type a "_" character and then the subscript. This is similar to the
  power "^" character for a superscript. If the sub- and superscript consists of multiple things you must
  enclose them in round parentheses. 

  => Total displaced soil by glacial flow:
  ```
  $ 7.32 beta +
  sum_(i=0)^nabla
  (Q_i (a_i - epsilon)) / 2 $
  ```

- Fractions: use / between numerator and denominator. Typst will automatically turn it into a fraction.
  Parentheses are smartly resolved, so you can enter your expression as you would into a calculator and
  Typst will replace parenthesized sub-expression as you would  into a calculator and Typs will replace
  parenthesized sub-expression with the appropriate notation.

  => refer to above example.

- functions for math: Not all math constructs have special syntax and typst instead uses "functions" similar
  to images, figures in the above but unlike those functions the math functions do not require "#" in
  starting of the function.

  => to insert a column vector, we can use the vec function. 
  Within math mode, function calls don't need to start with the # character.

  ```
  $ v := vec(x_1, x_2, x_3) $
  ```

- Some functions are only available in math mode. 
  Ex: the "cal" function which is used to typeset calligraphic letters commonly used for sets. 
  The math section of the reference (https://typst.app/docs/reference/math/) has all complete list of all
  functions that math mode make available.


- Arrows: Many symbols such as the arrow have a lot of variants, You can select among these variants by
  appending a dor and a modifier name to a symbol's name.

  Ex: $ a arrow.squiggly b $

  This above notation is also available in the markup mode, but the symbol name should be preceded with the
  #sym 

  A list of available symbols:
  https://typst.app/docs/reference/symbols/sym/

