-- ~/.config/nvim/lua/plugins/rustlings.lua
return {
  ---------------------------------------------------------------------------
  -- 1. rust-tools (inlay hints, runnables picker) ---------------------------
  ---------------------------------------------------------------------------
  {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    dependencies = "neovim/nvim-lspconfig",
    config = function()
      require("rust-tools").setup({
        server = {
          on_attach = function(_, bufnr)
            vim.keymap.set("n", "<leader>rr", "<cmd>RustRunnables<CR>",
              { buffer = bufnr, silent = true })
          end,
          settings = {
            ["rust-analyzer"] = { check = { command = "clippy" } },
          },
        },
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- 2. completion (nvim-cmp + LuaSnip) -------------------------------------
  ---------------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp, ls = require("cmp"), require("luasnip")
      cmp.setup({
        snippet = { expand = function(a) ls.lsp_expand(a.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = { { name = "nvim_lsp" }, { name = "luasnip" } },
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- 3. floating Rustlings watcher (cargo-watch) -----------------------------
  ---------------------------------------------------------------------------
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = { { "<leader>tw", desc = "Rustlings watch (float)" } },
    config = function()
      require("toggleterm").setup({ direction = "float", size = 20 })
      local Term  = require("toggleterm.terminal").Terminal
      local watch = Term:new({
        dir = "~/rustlings-new",                -- repo root
        cmd = "cargo watch -q -x check",        -- fast compile-check
        hidden = true,
      })
      vim.keymap.set("n", "<leader>tw", function() watch:toggle() end,
        { desc = "Rustlings watch (float)" })
    end,
  },
}

