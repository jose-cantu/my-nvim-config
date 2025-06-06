-- three plugin specs, returned as one table
return {
  {                                     -- rust-tools
    "simrat39/rust-tools.nvim",
    ft = "rust",
    dependencies = "neovim/nvim-lspconfig",
    config = function()
      require("rust-tools").setup({
        server = {
          settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
          on_attach = function(_, b)
            vim.keymap.set("n","<leader>rr","<cmd>RustRunnables<CR>",{buffer=b})
          end,
        },
      })
    end,
  },
  {                                     -- nvim-cmp (+ LuaSnip + LSP)
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local cmp, ls = require("cmp"), require("luasnip")
      cmp.setup({
        snippet = { expand = function(a) ls.lsp_expand(a.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"]   = cmp.mapping.confirm({ select = true }),
        }),
        sources = { { name="nvim_lsp" }, { name="luasnip" } },
      })
    end,
  },
  {                                       -- toggleterm watcher
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = { { "<leader>tw", desc = "Rustlings watch (float)" } },
    config = function()
      require("toggleterm").setup({ direction="float", size=20 })
      local Term  = require("toggleterm.terminal").Terminal
      local watch = Term:new({ cmd="rustlings watch", hidden=true })
      vim.keymap.set("n","<leader>tw",function() watch:toggle() end,
        { desc="Rustlings watch (float)" })
    end,
  },
}
