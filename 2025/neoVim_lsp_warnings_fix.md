# LSP Warnings for custom code:

When developing applications using Neo-vim that have the required plugin's configured.

Warnings appear for variables as they are located in non standard locations, causing lsp to 
spit out warning in the editors.

The trouble happens when a project is under development:

### ✅ Best Solution for Development: `.clangd` File

You can instruct `clangd` to always include FFmpeg headers (and any others) by creating a `.clangd` config file in your project root.

#### 🔧 Step-by-step:

1. **Create a `.clangd` file** in the project root:

   ```bash
   touch .clangd
   ```

2. **Edit it** to include FFmpeg headers explicitly:

   ```yaml
   CompileFlags:
     Add: 
       - -I/usr/include/ffmpeg
       - -I.
   ```

3. **Restart clangd** in Neovim (or just restart Neovim entirely).

This will tell `clangd` to always look in `/usr/include/ffmpeg` and the current directory for headers — **even if the file doesn’t compile yet**.

---

### 🔁 Alternative: Use `compile_flags.txt`

If you prefer a simpler route (or want to support other tools like `YouCompleteMe`), you can also create a `compile_flags.txt` file in your project root:

#### Contents of `compile_flags.txt`:

```
-I/usr/include/ffmpeg
-I.
```

This is automatically picked up by `clangd` if `compile_commands.json` is missing.

---

### 🚀 Summary

| Tool                             | Purpose                                |
| -------------------------------- | -------------------------------------- |
| `.clangd` file                   | Persistent flags during development    |
| `compile_flags.txt`              | Simpler alternative to `.clangd`       |
| `bear` + `compile_commands.json` | Accurate flags once the project builds |

---

# **Neovim with LSP (Language Server Protocol)** for C/C++ (typically via **clangd**), you may get warnings:

example : 
```
use of undeclared identifier 'AVMEDIA_TYPE_VIDEO'
```

even though you've included FFmpeg headers correctly in your code.

This usually happens because the LSP **doesn't know where to find the FFmpeg headers and libraries**, as 
it **does not automatically use your Makefile or build system configuration** unless told explicitly.

---

### ✅ Solution: Use `compile_commands.json`

The **standard way** to inform `clangd` (or any LSP using the C/C++ language server) about include paths and 
build flags is via a `compile_commands.json` file, which is a **JSON database of compilation commands**.

#### Step 1: Install `bear` (Build EAR)

This tool generates `compile_commands.json` automatically from your `make` run.

```bash
sudo apt install bear  # on Debian/Ubuntu
```

#### Step 2: Generate `compile_commands.json`

Run:

```bash
bear -- make clean && make
```

This wraps the build and produces `compile_commands.json` in your project root.

---

#### Step 3: Ensure `clangd` uses it

Make sure your Neovim LSP setup for C/C++ (typically in `init.lua` or `coc-settings.json`, depending on 
your plugin) uses `clangd` **with the working directory that contains** `compile_commands.json`.

If you're using `nvim-lspconfig`:

```lua
require('lspconfig').clangd.setup({
    cmd = { "clangd", "--compile-commands-dir=." }
})
```

This tells `clangd` to look for `compile_commands.json` in the current directory.

---

### ✅ Optional: FFmpeg-specific include paths

If you still want to hardcode paths temporarily (e.g. until `bear` works), you can create a `.clangd` config 
file:

```yaml
CompileFlags:
  Add: [-I/usr/include/ffmpeg]
```

Place this in your project root. `clangd` will use it automatically.

---

### Summary

| Step                       | What to do                               |
| -------------------------- | ---------------------------------------- |
| 🛠️ Install `bear`         | `sudo apt install bear`                  |
| 🏗️ Generate build DB      | `bear -- make clean && make`             |
| 📂 Confirm file            | Check `compile_commands.json` is created |
| 🧠 Tell `clangd` to use it | Set `--compile-commands-dir=.` in config |
| ✅ Done!                    | LSP now sees FFmpeg headers              |

