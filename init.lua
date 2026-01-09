-- init.lua

-- 1. Bootstrap packer.nvim
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  print("Installing packer…")
  fn.system({'git','clone','--depth','1','https://github.com/wbthomason/packer.nvim', install_path})
  vim.cmd 'packadd packer.nvim'
end

-- 2. Global options
vim.g.mapleader = ' '
vim.opt.clipboard = "unnamedplus"
vim.o.number         = true
vim.o.relativenumber = true
vim.o.expandtab      = true
vim.o.shiftwidth     = 2
vim.o.tabstop        = 2
vim.o.cursorline     = true
vim.opt.conceallevel  = 2
vim.opt.concealcursor = "nc"

-- 3. Plugins List
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  
  -- TELESCOPE FIX: Removed the '0.1.x' tag to use the latest master branch for Nvim 0.11
  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use 'neovim/nvim-lspconfig'
  use { 'williamboman/mason.nvim', run = function() pcall(vim.cmd, 'MasonUpdate') end }
  use 'williamboman/mason-lspconfig.nvim'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'L3MON4D3/LuaSnip'
  use 'rafamadriz/friendly-snippets'
  use 'windwp/nvim-autopairs'
  use 'akinsho/toggleterm.nvim'
  use 'tpope/vim-commentary'
  use { 'nvim-tree/nvim-tree.lua', requires = { 'nvim-tree/nvim-web-devicons' } }
  use { 'folke/tokyonight.nvim', config = function() vim.cmd("colorscheme tokyonight") end }
  use { 'nvimtools/none-ls.nvim', requires = { 'nvim-lua/plenary.nvim' } }
end)

-- 4. Protected Configuration Section
local function setup_if_exists(module, callback)
  local status, lib = pcall(require, module)
  if status then callback(lib) end
end

-- Treesitter Setup
setup_if_exists('nvim-treesitter.configs', function(ts)
  ts.setup {
    ensure_installed = { 'c','cpp','javascript','typescript','tsx','html','css','json','java','lua','bash','python' },
    highlight = { enable = true },
    indent    = { enable = true },
  }
end)

-- Telescope Setup (Updated for Nvim 0.11)
setup_if_exists('telescope', function(telescope)
  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find Files" })
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Search Text" })
  vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "List Buffers" })
  
  telescope.setup{
    defaults = {
      -- This ensures we don't try to use broken Treesitter highlighters in previews
      preview = { treesitter = false } 
    }
  }
  pcall(telescope.load_extension, 'fzf')
end)

-- LSP Setup
setup_if_exists('mason-lspconfig', function(mlsp)
  require('mason').setup()
  mlsp.setup { ensure_installed = { 'clangd', 'ts_ls', 'jdtls', 'pyright' } }
  local capabilities = require('cmp_nvim_lsp').default_capabilities()
  local servers = { 'clangd', 'jdtls', 'html', 'cssls', 'jsonls', 'pyright' }
  for _, server in ipairs(servers) do
    pcall(function() require('lspconfig')[server].setup { capabilities = capabilities } end)
  end
end)

-- Nvim-Tree Setup
setup_if_exists('nvim-tree', function(tree)
  tree.setup{}
  vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true })
end)

-- Utilities
setup_if_exists('nvim-autopairs', function(ap) ap.setup{} end)
setup_if_exists('toggleterm', function(tt) 
  tt.setup{ size = 15, direction = 'horizontal' } 
  vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<cr>")
end)

-- UI
vim.diagnostic.config({ virtual_text = { prefix = "●" } })
vim.api.nvim_set_keymap('n', '<C-z>', 'u', { noremap = true, silent = true })
