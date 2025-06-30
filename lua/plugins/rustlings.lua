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
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local ls  = require("luasnip")

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args) ls.lsp_expand(args.body) end,
        },

        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif ls.expand_or_jumpable() then
              ls.expand_or_jump()
            elseif vim.fn.col(".") > 1 then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif ls.jumpable(-1) then
              ls.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),

        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip"   },
          { name = "buffer"    },
          { name = "path"      },
        }),

        completion   = { completeopt = "menu,menuone,noinsert" },
        experimental = { ghost_text = true },
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

