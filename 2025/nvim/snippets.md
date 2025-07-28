# Nvim Snippets:

In *NeoVim text*, *snippets* are predefined templates or chunks of code/text that can be inserted quickly in to your file to speed your workflow.
They're useful for repetitive patterns like function definitions, HTML tags, boilerplate code, etc.
---

### What Are Snippets?

A *snippet* is a small template that may include placeholders, variables, and optional text. 

For example, a snippet for a Python function might look like this:

```python
def ${1:function_name}(${2:args}):
    ${0:pass}
```

* `${1:function_name}` – First placeholder.
* `${2:args}` – Second placeholder.
* `${0:pass}` – Final position (cursor ends here after filling others).

---

### How to Use Snippets in Neovim

Neovim doesn’t support snippets out of the box, but you can add snippet support using *plugins*.

The most common setup includes:

#### 1. *Install a Snippet Engine*

The two most popular snippet engines for Neovim are:

* [`Luasnip`](https://github.com/L3MON4D3/LuaSnip) (Lua-based, modern, fast)
* [`Ultisnips`](https://github.com/SirVer/ultisnips) (Python-based, used with vim-snippets)

*Luasnip is recommended* for Lua-based Neovim configs.

##### Example using `lazy.nvim` (plugin manager):

```lua
{
  'L3MON4D3/LuaSnip',
  dependencies = { 'rafamadriz/friendly-snippets' }, -- optional snippets
  config = function()
    require("luasnip.loaders.from_vscode").lazy_load()
  end,
}
```

---

#### 2. *Use Snippets in Insert Mode*

Once installed and configured:

* Type a *trigger word* (like `func`).
* Press the *expand key* (usually `<Tab>`).
* Use `<Tab>` and `<Shift-Tab>` to move between fields.

Example:

```lua
-- Trigger "fn" expands into a function snippet
fn<Tab>
-- Output:
function name(args)
  -- body
end
```

---

### Creating Your Own Snippets (with LuaSnip)

```lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("lua", {
  s("fn", {
    t("function "), i(1, "name"), t("("), i(2, "args"), t({")", "\t"}), i(0), t({"", "end"}),
  }),
})
```

---

### Community Snippets

Install `rafamadriz/friendly-snippets` for prebuilt snippets for many languages.

---

### Key Mappings (optional but helpful)

Example Lua mappings:

```lua
vim.keymap.set({"i", "s"}, "<Tab>", function()
  return require("luasnip").expand_or_jumpable() and "<Plug>luasnip-expand-or-jump" or "<Tab>"
end, {expr = true})

vim.keymap.set({"i", "s"}, "<S-Tab>", function()
  return require("luasnip").jumpable(-1) and "<Plug>luasnip-jump-prev" or "<S-Tab>"
end, {expr = true})
```

---

### Summary

| Task                        | Tool                     |
| --------------------------- | ------------------------ |
| Snippet engine              | `Luasnip` or `Ultisnips` |
| Prebuilt snippets           | `friendly-snippets`      |
| Triggering snippets         | `<Tab>` in insert mode   |
| Moving between placeholders | `<Tab>` / `<Shift-Tab>`  |

Would you like a minimal config snippet to try this out directly?
