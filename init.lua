--------------------------------------------------------------------------------
-- init.lua (Fresh Minimal Config)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1) BOOTSTRAP lazy.nvim
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable", -- latest stable release
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------
-- 2) SETUP Plugins via lazy.nvim
--------------------------------------------------------------------------------
-- Puting these at near top of init.lua file (before calling lazy.setup())
vim.g.loaded_netrw = 1 
vim.g.loaded_netrwPlugin = 1 

require("lazy").setup({

  -- == THEME: Gruvbox ==
  {
    "ellisonleao/gruvbox.nvim",
    name = "gruvbox",
    priority = 1000, -- Load this first so colors apply correctly
    config = function()
      require("gruvbox").setup({
        undercurl = true,
        underline = true,
        bold = true,
        contrast = "soft", -- "hard" or "" also possible

        -- If you want coffee/golden overrides, uncomment & tweak:
        -- palette_overrides = {
        --   bright_green  = "#a5895b",
        --   bright_yellow = "#d9bc8c",
        -- },
      })
      vim.cmd("colorscheme gruvbox")
    end,
  },

  -- == TREESITTER (Syntax Highlighting) ==
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "python", "bash", "rust" },
        highlight = { enable = true },
      })
    end,
  },

  -- == MASON (Install External LSP/Formatters) ==
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate", -- recommended if Mason is new
    config = function()
      require("mason").setup()
    end,
  },

  -- == MASON-LSPCONFIG (Bridges Mason & lspconfig) ==
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright", "bashls", "rust_analyzer" },
      })

      -- Setup each server automatically
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({})
        end,

        -- Example: special config for Rust
        ["rust_analyzer"] = function()
          require("lspconfig").rust_analyzer.setup({})
        end,
      })
    end,
  },

  -- == COMPLETION (nvim-cmp + sources + snippets) ==
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",      -- LSP source
      "hrsh7th/cmp-path",          -- file paths
      "hrsh7th/cmp-buffer",        -- current buffer words
      "L3MON4D3/LuaSnip",          -- snippet engine
      "saadparwaiz1/cmp_luasnip",  -- snippet completions
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body) -- snippet expansion
          end,
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer" },
        }),
        mapping = {
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        },
      })
    end,
  },

  -- == RUST TOOLS (Optional) ==
  {
    "simrat39/rust-tools.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    ft = { "rust" },
    config = function()
      local rt = require("rust-tools")
      rt.setup({
        server = {
          on_attach = function(_, bufnr)
            -- put rust-specific keybinds here if desired
          end,
        },
      })
    end,
  },

  -- == TELESCOPE (Fuzzy Finder) ==
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          -- see :help telescope.setup
        },
      })
    end,
  },

  -- == nvim-tree.lua setup
  {
    "nvim-tree/nvim-tree.lua",
    -- OPTIONAL: for file icons
    dependencies = {
      "nvim-tree/nvim-web-devicons", 
    },
    config = function()
      -- See full list of options at: 
      -- https://github.com/nvim-tree/nvim-tree.lua/blob/master/doc/nvim-tree-lua.txt

      require("nvim-tree").setup({
        -- BEGIN default options
        sort_by = "case_sensitive",
        view = {
          width = 30,
          side = "left",
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
        },
        -- Here I add onn the on_attach function:
	on_attach = function(bufnr)
		local api = require("nvim-tree.api")
		-- Setup all of nvim-tree's default mappings 
		api.config.mappings.default_on_attach(bufnr)

		-- Force a custom mapping for "?"
		vim.keymap.set("n", "?", api.tree.toggle_help, {
			buffer = bufnr,
			desc   = "NvimTree Help",
      })
    end,
  })
  end 
  },
}) -- end of require("lazy").setup()

--------------------------------------------------------------------------------
-- 3) OPTIONAL NEOVIM SETTINGS
--------------------------------------------------------------------------------
vim.opt.number = true             -- line numbers
vim.opt.mouse = "a"               -- enable mouse
vim.opt.clipboard = "unnamedplus" -- use system clipboard
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = "Toggle NvimTree" })

