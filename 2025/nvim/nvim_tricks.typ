//#set text(font: "VictorMono NF" , size: 10.8pt)
= Vim Motions and Tricks
#show outline.entry: it => link(
  it.element.location(),
  it.indented(it.prefix(), it.body()),
)
#set heading(numbering: "1.")
#line(length: 100%, stroke: (paint: blue, thickness: 2pt))
#outline()

#line(length: 100%, stroke: (paint: blue, thickness: 2pt))
#pagebreak()


- ZZ: Quick way to save and quit a file

- ZQ: Quite with out saving  ( my keybinging is ^q )

- vib: select contents inside {} or () or "" or ''

- cib: remove every thing inside parenthesis, and gets us to insert mode.

- Insert some text in the begining of the all the selected lines via visual mode.

  step1: select the first character using visual mode. 
         hello world 1231
         hello world  123123 123123 
         hello world  123 abc 
         hello world  123
  step2: move to the beginning of the line and press 'I' and type the text we wish for example
       
         <b>hello world 1231
         hello world  123123 123123
         hello world  123 abc 
         hello world  123
  here we inserted <b> now hit ESC the first the content gets inserted as below
         <b>hello world 1231
         <b>hello world  123123 123123 
         <b>hello world  123 abc 
         <b>hello world  123
  Make sure after selecting the text in visual mode use "I" not "i"

- now how to close all the lines with </b> as lengths of the lines are not same

    Step1: hit 'g v' this selects the first character "<"
         <b>hello world 1231
         <b>hello world  123123 123123 
         <b>hello world  123 abc 
         <b>hello world  123
    Step2: hit  '$' to move to the end of the line this makes the entire block in visual mode.
         <b>hello world 1231
         <b>hello world  123123 123123 
         <b>hello world  123 abc 
         <b>hello world  123 
    Step3: now we can append to the end by hitting "A" to append to all selected lines: and key in the
    closing tag </b> followed by ESC to make the append apply to all the selected lines.

         <b>hello world 1231</b>
         <b>hello world  123123 12312</b>
         <b>hello world  123 abc </b>
         <b>hello world  123 </b>

    Note: make sure you are not using 'g' for some keybinding
    You can check with :map g 

- Toggle a character to upper and lower case: using   ' ` '

- % : jump between matching pairs of parenthesis or brackets or pretty much anything
    This is useful to move to the starting of a block of code that runs over the screen to jump between 
    { and } to help know the code block inside those { }

- :mksession  save the current editing session (openfiles, window layout, working dir...)
  how to use 

  :mksession mysession.vim 
  ZZ
  this will create a mysession.vim and quits.

  Reopen the session 
  nvim 
  :source mysession.vim

- Open URL in browser:
    'g' is used as a prefix for various LSP keybindings (like 'gd', 'gi', etc.),
    so we avoid remapping 'gX'. Instead, we use 'xxG' as a custom keybinding
    to open the URL under the cursor in the default browser.
    vim.keymap.set('n', 'xxG', open_url_under_cursor, { desc = 'Open URL under cursor' })

- 'gf' opens directory or file in a new tab

- Mark a location and return to a mark:

  Step1: in Normal mode:
  m{a-z}  ex: ma  this will create a mark in the file. 
  Now navigate in the file and move any place. And when we wish to move to the marker 'a' that we set 
  step2: return to mark:
    `a 

- Marks across files

  Replace marker with captital {A-Z}

- list all marks:
  :marks 

- delete a mark 
  :delmark a 

- delete all marks:

  :delmarks!

- Join two lines on the same line

   hello 
   world

   go to line 1 and key "J" to join both lines and delete the below line


