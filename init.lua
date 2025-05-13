--------------------------------------------------------------------------------
-- init.lua (Fresh Minimal Config – corrected)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) BOOTSTRAP lazy.nvim -------------------------------------------------------
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------
-- 2) EARLY OPTIONS & GLOBALS ---------------------------------------------------
--------------------------------------------------------------------------------
-- Disable netrw so nvim-tree can own file‑explorer duties
vim.g.loaded_netrw       = 1

-- Point Neovim’s Python host to the MicroSeq conda env
vim.g.python3_host_prog = "/home/jason/anaconda3/envs/MicroSeq/bin/python"

--------------------------------------------------------------------------------
-- 3) LSP HELPER ----------------------------------------------------------------
--------------------------------------------------------------------------------
-- Highlight all references to symbol under cursor while you pause
local function lsp_highlight_on_attach(client, bufnr)
  if client.server_capabilities.documentHighlightProvider then
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end 
end



--------------------------------------------------------------------------------
-- 4) PLUGINS VIA lazy.nvim -----------------------------------------------------
--------------------------------------------------------------------------------
require("lazy").setup({

  {
    "folke/which-key.nvim",
    priority = 900,
    config   = function() require("which-key").setup({}) end,
  },

-- == THEME: Gruvbox ==
  {
    "ellisonleao/gruvbox.nvim",
    name     = "gruvbox",
    priority = 1000, -- Load first so colors apply correctly
    config = function()
      require("gruvbox").setup({ contrast = "soft", bold = true })
      vim.cmd.colorscheme("gruvbox")
    end,
  },

  -- == TREESITTER (Syntax Highlighting) ==
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "python", "bash", "rust" },
        highlight        = { enable = true },
      })
    end,
  },

  -- == MASON (binary manager) ==
  { "williamboman/mason.nvim", build = ":MasonUpdate", config = true },

  -- == MASON‑LSPCONFIG (bridge) ==
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright", "bashls", "rust_analyzer" },
      })

      require("mason-lspconfig").setup_handlers({
        -- default for every server
        function(server)
          require("lspconfig")[server].setup({ on_attach = lsp_highlight_on_attach })
        end,

        -- Pyright override
        ["pyright"] = function()
          require("lspconfig").pyright.setup({
            on_attach  = lsp_highlight_on_attach,
            pythonPath = vim.g.python3_host_prog,
            settings   = {
              python = {
                analysis = {
                  extraPaths         = { vim.fn.getcwd() .. "/src" },
                  autoSearchPaths    = true,
                  useLibraryCodeForTypes = true,
                },
              },
            },
          })
        end,

        -- Rust analyzer override
        ["rust_analyzer"] = function()
          require("lspconfig").rust_analyzer.setup({ on_attach = lsp_highlight_on_attach })
        end,
      })
    end,
  },

  -- == COMPLETION (nvim‑cmp + sources) ==
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-path", "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp, luasnip = require("cmp"), require("luasnip")
      cmp.setup({
        snippet = { expand = function(a) luasnip.lsp_expand(a.body) end },
        mapping = {
          ["<Tab>"]   = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<CR>"]    = cmp.mapping.confirm({ select = true }),
        },
        sources = {
          { name = "nvim_lsp" }, { name = "luasnip" },
          { name = "path" },      { name = "buffer" },
        },
      })
    end,
  },

  -- == RUST TOOLS (Optional) ==
  {
    "simrat39/rust-tools.nvim",
    ft = { "rust" },
    dependencies = "neovim/nvim-lspconfig",
    config = function()
      require("rust-tools").setup({ server = { on_attach = lsp_highlight_on_attach } })
    end,
  },

  -- == TELESCOPE (Fuzzy Finder) ==
  {
    "nvim-telescope/telescope.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    config = function() require("telescope").setup({}) end,
  },

  -- == FLASH (quick jump / better search) ==
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts  = {},
    keys  = {
      { "<leader>s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
    },
  },

  -- == VIM‑ILLUMINATE (highlight references) ==
  { "RRethy/vim-illuminate", event = "BufReadPost", opts = { delay = 120 } },

  -- == COMMENT.NVIM (toggle comments) ==
  { "numToStr/Comment.nvim", keys = { { "gc", mode = { "n", "x" } } }, config = true },

  -- == nvim-tree.lua (file explorer) ==
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-tree").setup({
        sort_by  = "case_sensitive",
        view     = { width = 30, side = "left" },
        renderer = { group_empty = true },
        filters  = { dotfiles = false },
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.set("n", "?", api.tree.toggle_help, { buffer = bufnr, desc = "NvimTree Help" })
        end,
      })
    end,
  },
})

--------------------------------------------------------------------------------
-- 5) GLOBAL KEYMAPS & MISC OPTIONS -------------------------------------------
--------------------------------------------------------------------------------
vim.opt.number    = true
vim.opt.mouse     = "a"
vim.opt.clipboard = "unnamedplus"

-- Toggle file explorer
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })

-- VS‑Code style comment toggles via Comment.nvim
vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment line" })
vim.keymap.set("v", "<leader>/", "gc",  { remap = true, desc = "Toggle comment block" })

-- 6) HELP SYSTEM (which-key integration) -------------------------------------
--------------------------------------------------------------------------------
local wk = require("which-key")

wk.register({
  ["<leader>"] = {
    -- Help section grouped under "h"
    h = {
      name = "+help",  -- Shows "h +help" as a sub-menu
      h = { "<cmd>Telescope help_tags<CR>", "Search :help (Telescope)" },  -- Open Telescope help tags
      t = { "<cmd>WhichKey<CR>", "Show which-key pop-up" },  -- Show keybinding cheat sheet
      k = { "<cmd>NvimTreeToggle<CR>", "Toggle NvimTree (File Explorer)" },  -- Example: Toggle file explorer
    },
  },
})
