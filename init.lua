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
  spec = {

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

  -- == Excel grid setup for neovim rainbow_csv == --
  {
    "cameron-wags/rainbow_csv.nvim",
    ft       = { "csv", "tsv", "csv_semicolon", "csv_pipe" }, -- lazy-load only for delimited files
    opts     = { separators = { ",", "\t", ";" } },           -- recognise commas, tabs *and* semicolons
    config   = function(_, opts)
      require("rainbow_csv").setup(opts)
      -- optional: auto-align as soon as you open the file
      vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = { "*.csv", "*.tsv" },
        callback = function() vim.cmd("RainbowAlign") end,
      })
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

  -- == MASON-LSPCONFIG (bridge) ==
  {
  "mason-org/mason-lspconfig.nvim",   -- ← new org name
  dependencies = "neovim/nvim-lspconfig",
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = { "pyright", "bashls", "rust_analyzer" },

      -- ⬇ disable ALL the new helpers safely
      automatic_enable  = { enable = false },
      automatic_install = { enable = false },
      automatic_setup   = { enable = false },

      handlers = {                      -- your custom setup
        function(server)
          require("lspconfig")[server].setup({ on_attach = lsp_highlight_on_attach })
        end,
        ["pyright"] = function()
          require("lspconfig").pyright.setup({
            on_attach  = lsp_highlight_on_attach,
            pythonPath = vim.g.python3_host_prog,
            settings = {
              python = {
                analysis = {
                  extraPaths      = { vim.fn.getcwd() .. "/src" },
                  autoSearchPaths = true,
                  useLibraryCodeForTypes = true,
                },
              },
            },
          })
        end,
        ["rust_analyzer"] = function()
          require("lspconfig").rust_analyzer.setup({ on_attach = lsp_highlight_on_attach })
        end,
      },
    })
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
  { "RRethy/vim-illuminate", event = "BufReadPost", 
  config = function()
	  require("illuminate").configure({ delay = 120 })
  end,
},

  -- == COMMENT.NVIM (toggle comments) ==
  { "numToStr/Comment.nvim", keys = { { "gc", mode = { "n", "x" } } }, config = true },

  -- == NVIM-LINT (Python linting) ==
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = { python = { "flake8" } }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
        callback = function() lint.try_lint() end,
      })
    end,
  },

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
  { import = "plugins" },   -- pulls in rustlings.lua
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

-- rainbow_csv common commands CSV/TSV helper
-- ALIGN / REALIGN your spreadsheet
vim.keymap.set(
  "n",
  "<leader>ca",
  "<cmd>RainbowAlign<CR>",
  { desc = "CSV/TSV: align columns" }
)

-- Sort by current column (header preserved)
vim.keymap.set(
  "n",
  "<leader>cs",
  "<cmd>RCsvSort<CR>",
  { desc = "CSV/TSV: sort by current column" }
)

-- 6) HELP SYSTEM (which-key integration) -------------------------------------
--------------------------------------------------------------------------------
local wk = require("which-key")

wk.add({                                -- <- prefer add() for v3 syntax sugar
  { "<leader>h",  group = "+help" },    -- banner for the whole subtree
  { "<leader>hh", "<cmd>Telescope help_tags<CR>", desc = "Search help tags" },
  { "<leader>hk", "<cmd>NvimTreeToggle<CR>",      desc = "Toggle file explorer" },
  { "<leader>ht", "<cmd>WhichKey<CR>",            desc = "Show which‑key popup" },
}, { mode = "n", silent = true })





