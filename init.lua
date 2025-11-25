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

-- 3) LSP helper – highlight references under cursor + keymaps ---------------------------
local function lsp_on_attach(client, bufnr)
  -- (1) highlight references under cursor
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

  -- (2) LSP keymaps scoped to this buffer
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- Hover docs (normal mode)
  map("n", "K", vim.lsp.buf.hover, "LSP hover docs")
  -- Signature help (insert/normal) – useful when inside call parentheses
  map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, "LSP signature help")

  -- A few high‑leverage navs that pair well with hover
  map("n", "gd", vim.lsp.buf.definition,        "LSP go to definition")
  map("n", "gr", vim.lsp.buf.references,        "LSP references")
  map("n", "gi", vim.lsp.buf.implementation,    "LSP implementations")
  map("n", "gD", vim.lsp.buf.declaration,       "LSP declaration")
  map("n", "<leader>lr", vim.lsp.buf.rename,    "LSP rename")        -- in +lsp group
  map({ "n","v" }, "<leader>la", vim.lsp.buf.code_action, "LSP code action")
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
        scope  = { enabled = false }, 
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

	    -- plain indentation / insert literal tab 
	    ["<Tab>"] = function(fallback) fallback() end,
	    ["<S-Tab>"] = function(fallback) fallback() end,
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
          ensure_installed = { "lua", "vim", "python", "bash", "rust", "markdown", "markdown_inline" },
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
                on_attach    = lsp_on_attach,
                capabilities = capabilities,
              })
            end,
            pyright = function()
              require("lspconfig").pyright.setup({
                on_attach    = lsp_on_attach,
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
        lint.linters_by_ft = { python = { "ruff" } }
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

    ----------------------------------------------------------------------
    --- GIT PLUGINS 
    ----------------------------------------------------------------------
    { "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = {
	add          = { text = "▎" },
	change       = { text = "▎" },
	delete       = { text = "▁" },
	topdelete    = { text = "▔" },
	changedelete = { text = "▎" },
	untracked    = { text = "▎" },
      },
      word_diff = true,
      attach_to_untracked = true,
      preview_config = { border = "rounded" },

      -- Off by default; toggle when needed to reduce noise
      current_line_blame = false,
      current_line_blame_opts = { delay = 400, virt_text_pos = "eol" },

      on_attach = function(bufnr)
	local gs = package.loaded.gitsigns
	local map = function(m, l, r, d) vim.keymap.set(m, l, r, { buffer = bufnr, desc = d }) end

	-- Hunk nav
	map("n", "]h", gs.next_hunk, "Next hunk")
	map("n", "[h", gs.prev_hunk, "Prev hunk")

	-- Stage / reset (works in visual mode for a selection)
	map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
	map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
	map("n", "<leader>gS", gs.stage_buffer,                     "Stage buffer")
	map("n", "<leader>gu", gs.undo_stage_hunk,                  "Undo stage")

	-- Review
	map("n", "<leader>gp", gs.preview_hunk_inline,              "Preview hunk")
	map("n", "<leader>gb", gs.toggle_current_line_blame,        "Toggle blame")
	map("n", "<leader>gd", gs.toggle_deleted,                   "Show deletions")
	map("n", "<leader>gD", function() gs.diffthis("HEAD") end,  "Diff vs HEAD")

	-- Which‑key group
	local ok, wk = pcall(require, "which-key")
	if ok then wk.add({ { "<leader>g", group = "+git" } }, { buffer = bufnr }) end
      end,
    },
  },

      -- Multi-file diffs, history, and conflict resolution
	{
	  "sindrets/diffview.nvim",
	  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
	  dependencies = { "nvim-lua/plenary.nvim" },
	  opts = {
	    enhanced_diff_hl = true,     -- better hunk highlighting in diffs
	    use_icons        = true,     -- works with nvim-web-devicons
	    view = { default = { winbar_info = true } },
	    file_panel = { win_config = { position = "left", width = 35 } },
	  },
	  keys = {
	    { "<leader>dv", "<cmd>DiffviewOpen<CR>",             desc = "Diffview: Open (vs HEAD)" },
	    { "<leader>dx", "<cmd>DiffviewClose<CR>",            desc = "Diffview: Close" },
	    { "<leader>df", "<cmd>DiffviewFileHistory %<CR>",    desc = "Diffview: File history (current file)" },
	    { "<leader>dF", "<cmd>DiffviewFileHistory<CR>",      desc = "Diffview: Repo history" },
	    { "<leader>dt", "<cmd>DiffviewToggleFiles<CR>",      desc = "Diffview: Toggle files panel" },
	    { "<leader>d;", "<cmd>DiffviewFocusFiles<CR>",       desc = "Diffview: Focus files panel" },
	  },
	}, 


    { import = "plugins" }, -- your optional extra plugin modules
  },
})


-- 4.5) DIAGNOSTICS UI ---------------------------------------------------------
vim.diagnostic.config({
  virtual_text   = { spacing = 2, prefix = "●" },
  signs          = true,
  underline      = true,
  update_in_insert = false,
  severity_sort  = true,
})
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false, border = "rounded" })
  end,
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
vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })
-- heavy analyzers on demand only for linters  
vim.keymap.set("n", "<leader>lp", function() require("lint").try_lint({ "pylint" }) end, { desc = "Deep Qt/GUI lint (pylint-pyqt) for PySide6 aware semantic checks signal/slot, enum useage etc." }) 

vim.keymap.set("n", "<leader>lm", function() require("lint").try_lint({ "mypy" }) end, { desc = "Static type-check (mypy) validation type hints for longevity of tool" })

-- 7) WHICH‑KEY HELP TREE ------------------------------------------------------
local wk = require("which-key")
wk.add({
  { "<leader>h",  group = "+help" },
  { "<leader>l",  group = "+lsp"  },
  { "<leader>ld", "<cmd>lua vim.diagnostic.open_float()<CR>", desc = "Line diagnostics" }, 
  { "<leader>hh", "<cmd>Telescope help_tags<CR>", desc = "Help search" },
  { "<leader>hk", "<cmd>Telescope keymaps<CR>",   desc = "Keymap search" },
  { "<leader>ht", "<cmd>WhichKey<CR>",            desc = "Which‑key" },
  { "<leader>d", group = "+diff" },
}, { mode = "n", silent = true })

