# Neovim + Rustlings + Cargo‑Watch

End‑to‑end recipe for a zero‑click **green / red** feedback loop while working through the Rustlings exercises.

---

## 1  Install toolchain & helpers

```bash
# Rust toolchain (if not already)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update stable           # needs rustc ≥ 1.60 for rustlings 6+

# Cargo helpers
cargo install --locked cargo-watch       # file‑system watcher (v8.5+) — one‑time
```

---

\## 2  Clone or update Rustlings

```bash
# first‑time
git clone https://github.com/rust-lang/rustlings ~/rustlings
cd ~/rustlings

# or if you already cloned
cd ~/rustlings
git pull origin main
```

*(No need to build a custom **`rustlings`** binary; the CLI isn’t required for the live watcher.)*

---

\## 3  Add a one‑line wrapper script (optional but neat)
Create `~/rustlings/run_watch.sh`:

```bash
#!/usr/bin/env bash
cargo watch -c -x check   # clear screen & type‑check on every save
```

```bash
chmod +x ~/rustlings/run_watch.sh
```

> **Why ****`cargo check`****?** It runs the full borrow‑checker but skips codegen, giving the fastest green/red loop.
>
> Switch to `-x 'test -- --nocapture'` or `-x 'test -- --nocapture' -x run` if you prefer running tests or the full Rustlings CLI each time.

---

\## 4  Neovim plugin snippet (Lua)
Add this file to `~/.config/nvim/lua/plugins/rustlings.lua` (or slot the block into your plugin manager list):

```lua
local Term = require("toggleterm.terminal").Terminal
local watch = Term:new({
  dir = "~/rustlings",              -- repo root
  cmd = "~/rustlings/run_watch.sh", -- or direct cargo‑watch command
  hidden = true,
})

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<leader>tw", desc = "Rustlings watch" },
    },
    config = function()
      require("toggleterm").setup({ direction = "float", size = 20 })
      vim.keymap.set("n", "<leader>tw", function() watch:toggle() end,
        { desc = "Rustlings watch (float)" })
    end,
  },
  -- (optionally add rust-tools.lua, nvim-cmp, etc.)
}
```

---

\## 5  Sync plugins
Inside Neovim:

```vim
:source $MYVIMRC | Lazy sync    " or PackerSync / PlugInstall depending on manager
```

---

\## 6  Daily workflow

| Action                | Keystroke                                                          |
| --------------------- | ------------------------------------------------------------------ |
| Open any exercise     | `nvim ~/rustlings/exercises/...`                                   |
| Show / hide watcher   | `<leader>tw` (first press loads plugin, second opens)              |
| Save file             | `:w` – watcher clears, runs `cargo check`, prints green ✅ or red ❌ |
| Move to next exercise | In CLI pane: `n` or run `rustlings verify`                         |

---

\## 7  Troubleshooting

| Symptom                       | Fix                                                                                                           |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `cargo: command not found`    | Ensure Rust toolchain is installed (`rustup`) & `$HOME/.cargo/bin` is in `$PATH`.                             |
| Pane opens but nothing prints | Confirm Neovim’s CWD == `~/rustlings` *or* set `dir = "~/rustlings"` in the `Terminal:new` call.              |
| Pane closes instantly         | Remove `-q`/`-c` flags while debugging to view full output.                                                   |
| Key mapping missing           | Run `:verbose map <leader>tw` → should reference rustlings.lua; otherwise `:Lazy sync` or source your config. |

---

\## Appendix: Alternative watchers

* **Bacon** – actively maintained TUI. `cargo install bacon`; replace the script with `bacon --init-if-needed`.
* **`cargo watch -x test -x run`** – slower but runs unit tests and the interactive CLI each cycle.

