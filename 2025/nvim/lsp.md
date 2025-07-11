# LSP:

Introduction to *LSP (Language Server Protocol)* in the context of learning *Neovim* and *Vim*:

---

### 🔧 What is LSP?

*Language Server Protocol (LSP)* is a protocol developed by *microsoft* that standardizes communication 
between *code editors (IDE's)* (like Neovim or VS Code) and *language-specific servers* (like Pyright for 
        Python, tsserver for TypeScript, rust-analyzer for rust...).

Its purpose is to provide *rich IDE-like features* —such as:

* Code completion
* Go to definition
* Hover documentation
* Rename symbols
    * Code formatting
* Diagnostics (errors, warnings)

    ...without the editor needing to implement language-specific logic.

    ---

### 🧠 Why LSP Matters for Vim/Neovim?

    Vim and Neovim are traditionally minimal editors. 
    Out-of-the-box, they lack IDE features like IntelliSense, error linting, etc. With LSP integration, you 
    can transform Vim/Neovim into a powerful editor while still keeping its speed and customization.

    ---

### ✨ Neovim vs Vim: LSP Support

    * *Neovim (v0.5+)* has built-in support for LSP via the `:help lsp` client.
    * *Vim* does *not* have native LSP support so it needs an external plugins like
    [coc.nvim](https://github.com/neoclide/coc.nvim) (which uses Node.js).

    So if you're starting from scratch and want easy LSP integration, *Neovim is the better choice*.

    ---

### 🚀 How LSP Works in Neovim

    Neovim communicates with an external *Language Server* over a JSON-RPC connection. 

    Here’s a simplified flow:

    1. You open a file (e.g. `main.py`).
    2. Neovim launches the configured *language server* (e.g. Pyright).
    3. As you type or trigger commands, Neovim sends requests like "what symbols are here?" to the server.
    4. The language server replies with info (e.g. "this is a function", or "there's an error on line 5").
    5. Neovim shows you that info (e.g. through floating windows or underlines).

    [ Refer to diagnostics.lua @ nvim configuration ]

    Since neovim 0.11+ the default mode of displaying this information via floating windows can change from
    its older versions.
    To display the current setting issue the below command:
    ```lua 
    :lua print(vim.inspect(vim.diagnostic.config()))
    ```
---
{
    float = {
        border = "rounded",
        source = "always"
    },
          jump = {
              float = false,
              wrap = true
          },
          severity_sort = false,
          signs = true,
          underline = true,
          update_in_insert = false,
          virtual_lines = false,
          virtual_text = false
}
---

### 🧰 Popular Plugins to Use LSP in Neovim

1. *Native LSP* (built into Neovim 0.5+)

    * Configure servers with `lspconfig`: [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)

    2. *Completion*

    * [nvim-cmp](https://github.com/hrsh7th/nvim-cmp): Completion engine

    . *UI Enhancements*

    * [lspsaga.nvim](https://github.com/nvimdev/lspsaga.nvim): UI for LSP actions
    * [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim): Fuzzy finding LSP results
    * [trouble.nvim](https://github.com/folke/trouble.nvim): Display diagnostics

---

### 🛠️ Getting Started

    To start using LSP in Neovim:

    1. Install Neovim 0.5+ (latest is better).
    2. Use a plugin manager like `lazy.nvim`, `packer.nvim`, or `vim-plug`.
    3. Install `nvim-lspconfig`.
    4. Set up a language server (e.g., Pyright for Python).
    5. Optional: Add completion and UI plugins.

    ---

### 🧪 Example Setup (Lua, for Neovim)

    ```lua
    -- Install nvim-lspconfig via plugin manager
    require('lspconfig').pyright.setup{}
    ```

    You now get diagnostics, go-to definition, hover docs, and more for Python!

    ---

### 🧩 Summary

    | Feature         | Vim                 | Neovim (0.5+)                    |
    | --------------- | ------------------- | -------------------------------- |
    | Native LSP      | ❌                   | ✅                                |
    | LSP via Plugins | ✅ (with `coc.nvim`) | ✅ (`nvim-lspconfig`, `nvim-cmp`) |


---


