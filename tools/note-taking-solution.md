# 1. "nb" a note-taking solution:


## Intro:
There are many note-taking systems and applications (everNote, OneNote, Apple Note, Obsidian..)

"nb" is for commandline and simple requirements:

    - open my notes in any text editor, or any operating system
    - organize them in any structure we wish for
    - search through using rg or grep
    - support version control (git) for syncronize between systemw under our control.
    - format them in markdown
    - encrypt using gpg or any other ( configurable )

"nb":  This is a note-taking tool for command line that meets many note-taking requirements.

"nb" is tiny but offers very powerful features.

"nb": "notebooks" are seperate git repos that can be synchronized either with seperate remotes
or as orphan branches on one remote. 
As its common with many to messup with the files and local repos, syncronize with a remote is better.
A good practice is to keep notebooks small as nb supports to keep arbitrary dir structure in the 
notebook you want.. so sub-dividing into notebook categories is a better approch.

---

# 2. "nb" Notebook Cheat Sheet :

## 1. Notebooks:

Add a notebook named Example:

- $ nb notebooks add Example

switch to the notebook named Example 
- $ nb use Example 

## 2. Notes:

create a new note with the filename test_file.md
- $ nb add test_file.md

New Note with the Title & Tag:
- $ nb add example.md --title "Tagged Example" --tags tag1, tag2

Edit note:
- $ nb edit example.md

## 3. Todo:

create a new todo title with "Example todo One"
- $ nb todo add "Example todo One"

create a new todo titled "ex todo two" with due date of 2024-07-31:
- $ nb todo add "ex todo two." --due "2024-07-31"

list todos in the current Notebook
- $ nb todos

list open todos in the current Notebook
- $ nb todos open 

list closed todos in the current Notebook
- $ nb todos close

mark todo 6 as done / closed.
- $ nb do 6 

mark todo 6 as un-done / open or reopen
- $ nb undo 6 


## 4. Bookmarks

create Bookmarks 
- $ nb www.github.com/prk-2023 

add a comment 
- nb www.github.com/prk-2023 --comment "personal, working and forked repos"

add tags
- $ nb www.github.com/prk-2023 --tags tag1,tag2 

search for tag 
- $ nb search --tag tag1 

list Bookmarks
- $ nb bookmarks list

view a bookmark 12 in browser links or w3m 
- BROWSER=links nb 12 peek 

view a bookmark 12 in gui web browser
- nb show 12 render

view a booksmak in terminal web browser 
- nb bookmark peek 2 

open bookmark in default web browser 
-nb bookmark open 2

## 5. git ( synchronization )

- Ex setup and synchronize with a remote server:

this can be setup on the remote side: or a similar repo can be used with github
```
mkdir nb
git init --bare nb/personal.git
git init --bare nb/work.git
```
On the local sidie:
```
nb notebook add personal
nb notebook add work
nb personal:remote set user@domain.com:/home/user/nb/personal.git
nb work:remote set user@domain.com:/home/user/nb/work/git.
```
- the next step is so enable auto-sync if we prefer.

- we can selectively choose which notebooks to sync on a per-machine basis. 

