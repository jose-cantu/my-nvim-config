--──────────────────────────────────────────────────────────────────────────────
-- init.lua  ·  Neovim ≥ 0.11  (lazy.nvim + Mason v2 + full IDE stack)
--──────────────────────────────────────────────────────────────────────────────

-- 1) BOOTSTRAP lazy.nvim ------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2) EARLY GLOBAL OPTIONS ------------------------------------------------------
vim.g.loaded_netrw, vim.g.loaded_netrwPlugin = 1, 1     -- nuke netrw (NvimTree owns it)

-- Prefer active venv/conda interpreter for :Python3 --------------------------------
do
  local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
  if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
    vim.g.python3_host_prog = venv .. "/bin/python"
  else
    vim.g.python3_host_prog = vim.fn.exepath("python3")
  end
end

-- 3) LSP helper – highlight references under cursor ---------------------------
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

-- 4) PLUGINS ------------------------------------------------------------------
require("lazy").setup({
  spec = {
    ------------------------------------------------------------------------
    -- UX BASICS
    ------------------------------------------------------------------------
    { "folke/which-key.nvim", priority = 900,
      config = function() require("which-key").setup({}) end },

    { "nvim-tree/nvim-web-devicons", lazy = true },
    { "echasnovski/mini.nvim",       version = false },

    ------------------------------------------------------------------------
    -- VISUALS
    ------------------------------------------------------------------------
    { "ellisonleao/gruvbox.nvim", name = "gruvbox", priority = 1000,
      config = function()
        require("gruvbox").setup({ contrast = "soft", bold = true })
        vim.cmd.colorscheme("gruvbox")
      end },

    -- Indent guides à la VS Code
    { "lukas-reineke/indent-blankline.nvim",
      main = "ibl",
      event = "BufReadPost",
      opts = {
        indent = { char = "│" },
        scope  = { enabled = true, show_start = false, show_end = false },
        whitespace = { remove_blankline_trail = false },
        exclude = { filetypes = { "help", "NvimTree" } },
      },
    },

    ------------------------------------------------------------------------
    -- COMPLETION & SNIPPETS
    ------------------------------------------------------------------------
    { "hrsh7th/nvim-cmp", event = "InsertEnter", priority = 800,
      dependencies = {
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "rafamadriz/friendly-snippets",
      },
      config = function()
        local cmp, luasnip = require("cmp"), require("luasnip")
        require("luasnip.loaders.from_vscode").lazy_load()
        cmp.setup({
          completion   = { autocomplete = false },  -- only on demand (C‑Space)
          experimental = { ghost_text = false },
          snippet      = { expand = function(args) luasnip.lsp_expand(args.body) end },
          mapping = cmp.mapping.preset.insert({
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"]     = cmp.mapping.abort(),
            ["<CR>"]      = cmp.mapping.confirm({ select = false }),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" }, { name = "luasnip" },
            { name = "buffer"   }, { name = "path"   },
          }),
        })
      end },

    ------------------------------------------------------------------------
    -- FILETYPE GOODIES
    ------------------------------------------------------------------------
    { "cameron-wags/rainbow_csv.nvim", ft = { "csv", "tsv", "csv_semicolon", "csv_pipe" },
      opts = { separators = { ",", "\t", ";" } },
      config = function(_, opts)
        require("rainbow_csv").setup(opts)
        vim.api.nvim_create_autocmd("BufReadPost", {
          pattern = { "*.csv", "*.tsv" },
          callback = function() vim.cmd("RainbowAlign") end,
        })
      end },

    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = { "lua", "vim", "python", "bash", "rust" },
          highlight        = { enable = true },
        })
      end },

    ------------------------------------------------------------------------
    -- LSP & TOOLS (Mason v2)
    ------------------------------------------------------------------------
    { "williamboman/mason.nvim", build = ":MasonUpdate", config = true },

    { "williamboman/mason-lspconfig.nvim",
      dependencies = { "neovim/nvim-lspconfig", "hrsh7th/nvim-cmp" },
      config = function()
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        require("mason-lspconfig").setup({
          ensure_installed       = { "pyright", "bashls", "rust_analyzer" },
          automatic_installation = false, -- keep manual control
          handlers = {
            function(server)
              require("lspconfig")[server].setup({
                on_attach    = lsp_highlight_on_attach,
                capabilities = capabilities,
              })
            end,
            pyright = function()
              require("lspconfig").pyright.setup({
                on_attach    = lsp_highlight_on_attach,
                capabilities = capabilities,
                settings = {
                  python = {
                    pythonPath = vim.g.python3_host_prog,
                    analysis = {
                      extraPaths      = { vim.fn.getcwd() .. "/src" },
                      autoSearchPaths = true,
                      useLibraryCodeForTypes = true,
                    },
                  },
                },
              })
            end,
          },
        })
      end },

    { "mfussenegger/nvim-lint", event = { "BufReadPost", "BufWritePost" },
      config = function()
        local lint = require("lint")
        lint.linters_by_ft = { python = { "flake8" } }
        vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
          callback = function() lint.try_lint() end,
        })
      end },

    ------------------------------------------------------------------------
    -- NAVIGATION / UTIL
    ------------------------------------------------------------------------
    { "nvim-telescope/telescope.nvim", dependencies = "nvim-lua/plenary.nvim",
      config = function() require("telescope").setup({}) end },

    { "folke/flash.nvim", event = "VeryLazy", opts = {},
      keys = {
        { "<leader>s", mode = { "n", "x", "o" },
          function() require("flash").jump() end, desc = "Flash jump" },
      } },

    { "RRethy/vim-illuminate", event = "BufReadPost",
      config = function() require("illuminate").configure({ delay = 120 }) end },

    { "numToStr/Comment.nvim",
      keys = { { "gc", mode = { "n", "x" } } }, config = true },

    { "nvim-tree/nvim-tree.lua", dependencies = "nvim-tree/nvim-web-devicons",
      config = function()
        require("nvim-tree").setup({
          sort_by = "case_sensitive",
          view = { width = 30, side = "left" },
          renderer = { group_empty = true },
          filters = { dotfiles = false },
          on_attach = function(bufnr)
            local api = require("nvim-tree.api")
            api.config.mappings.default_on_attach(bufnr)
            vim.keymap.set("n", "?", api.tree.toggle_help, { buffer = bufnr, desc = "NvimTree Help" })
          end,
        })
      end },

    { import = "plugins" }, -- your optional extra plugin modules
  },
})

-- 5) GLOBAL OPTIONS -----------------------------------------------------------
vim.opt.number      = true
vim.opt.mouse       = "a"
vim.opt.clipboard   = "unnamedplus"
vim.opt.completeopt = { "menuone", "noselect", "noinsert" }

-- 6) KEYMAPS ------------------------------------------------------------------
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })
vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Comment line" })
vim.keymap.set("v", "<leader>/", "gc",  { remap = true, desc = "Comment block" })
vim.keymap.set("n", "<leader>ca", "<cmd>RainbowAlign<CR>", { desc = "CSV align" })
vim.keymap.set("n", "<leader>cs", "<cmd>RCsvSort<CR>",     { desc = "CSV sort col" })

-- 7) WHICH‑KEY HELP TREE ------------------------------------------------------
local wk = require("which-key")
wk.add({
  { "<leader>h",  group = "+help" },
  { "<leader>hh", "<cmd>Telescope help_tags<CR>", desc = "Help search" },
  { "<leader>hk", "<cmd>Telescope keymaps<CR>",   desc = "Keymap search" },
  { "<leader>ht", "<cmd>WhichKey<CR>",            desc = "Which‑key" },
}, { mode = "n", silent = true })

