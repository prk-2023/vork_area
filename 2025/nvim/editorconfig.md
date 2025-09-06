# Editors Config:

## What is editorconfig?

- .editorconfig is a standard configuration file used to define and maintain consistent coding styles between different editors and IDEs in a project. It helps enforce settings like indentation, line endings, and chatset.  

- As of NeoVim 0.9, .editorconfig is builtin, so you no longer need external plugins line editorconfig-vim to enable it.

## How to use .editorconfig with nvim?
1. create a .editorconfig file in the root directory of your project.
2. NeoVim will automatically detect and apply the settings from this file when you open or edit files in that project.
3. No plugin or manual configuration is needed if you're using neovim 0.9 or later

### Example .editorconfig file:
```ini 
# Root EditorConfig file
root = true

# All files
[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

# Python files
[*.py]
indent_size = 4

# Makefiles
[Makefile]
indent_style = tab
```
## How does this work?
- nvim reads the .editorconfig file from the project root (or parent directories)
- the setting are applied as you open files.
- common styles like `indent_style`, `indent_size` and `end_of_line` are respected automatically.

> This means developers can maintain consistent code formatting across different editors and team members without needing plugins. By placing a .editorconfig file in the root of a project, Neovim will automatically apply the defined settings such as indentation style, line endings, and charset to files in that project.
