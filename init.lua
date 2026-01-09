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
vim.o.termguicolors  = true
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

  -- Git Integration
  use 'lewis6991/gitsigns.nvim'
  use 'tpope/vim-fugitive'
  use 'kdheepak/lazygit.nvim'

  -- Better Navigation & UI
  use 'ThePrimeagen/harpoon'
  use { 'folke/trouble.nvim', requires = 'nvim-tree/nvim-web-devicons' }
  use { 'nvim-lualine/lualine.nvim', requires = { 'nvim-tree/nvim-web-devicons' } }
  use { 'akinsho/bufferline.nvim', tag = "*", requires = 'nvim-tree/nvim-web-devicons' }
  use 'lukas-reineke/indent-blankline.nvim'
  use 'norcalli/nvim-colorizer.lua'

  -- Debugging (DAP)
  use 'mfussenegger/nvim-dap'
  use { 'rcarriga/nvim-dap-ui', requires = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' } }
  use 'mfussenegger/nvim-dap-python'
  use { 'microsoft/vscode-js-debug', opt = true, run = 'npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out' }
  use 'mxsdev/nvim-dap-vscode-js'

  -- Additional LSP/Formatting
  use 'jose-elias-alvarez/typescript.nvim'
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
    pcall(function()
      vim.lsp.config(server, {
        capabilities = capabilities,
        root_markers = { '.git' },
      })
      vim.lsp.enable(server)
    end)
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

-- Git Integration (gitsigns)
setup_if_exists('gitsigns', function(gitsigns)
  gitsigns.setup {
    signs = {
      add          = { text = '│' },
      change       = { text = '│' },
      delete       = { text = '_' },
      topdelete    = { text = '‾' },
      changedelete = { text = '~' },
      untracked    = { text = '┆' },
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end
      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then return ']c' end
        vim.schedule(function() gs.next_hunk() end)
        return '<Ignore>'
      end, {expr=true, desc='Next hunk'})
      map('n', '[c', function()
        if vim.wo.diff then return '[c' end
        vim.schedule(function() gs.prev_hunk() end)
        return '<Ignore>'
      end, {expr=true, desc='Previous hunk'})
      -- Actions
      map('n', '<leader>gb', gs.toggle_current_line_blame, { desc = 'Toggle Git Blame' })
      map('n', '<leader>gd', gs.diffthis, { desc = 'Git Diff' })
      map('n', '<leader>gp', gs.preview_hunk, { desc = 'Preview Hunk' })
    end
  }
end)

-- Lazygit Integration
vim.keymap.set('n', '<leader>gg', ':LazyGit<CR>', { silent = true, desc = 'Open LazyGit' })

-- Harpoon for Quick File Navigation
setup_if_exists('harpoon', function()
  local mark = require('harpoon.mark')
  local ui = require('harpoon.ui')
  vim.keymap.set('n', '<leader>a', mark.add_file, { desc = 'Harpoon: Add File' })
  vim.keymap.set('n', '<C-e>', ui.toggle_quick_menu, { desc = 'Harpoon: Toggle Menu' })
  vim.keymap.set('n', '<C-h>', function() ui.nav_file(1) end, { desc = 'Harpoon: File 1' })
  vim.keymap.set('n', '<C-j>', function() ui.nav_file(2) end, { desc = 'Harpoon: File 2' })
  vim.keymap.set('n', '<C-k>', function() ui.nav_file(3) end, { desc = 'Harpoon: File 3' })
  vim.keymap.set('n', '<C-l>', function() ui.nav_file(4) end, { desc = 'Harpoon: File 4' })
end)

-- Trouble (Diagnostics Viewer)
setup_if_exists('trouble', function(trouble)
  trouble.setup{}
  vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'Diagnostics (Trouble)' })
  vim.keymap.set('n', '<leader>xd', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Buffer Diagnostics' })
  vim.keymap.set('n', '<leader>xl', '<cmd>Trouble loclist toggle<cr>', { desc = 'Location List' })
  vim.keymap.set('n', '<leader>xq', '<cmd>Trouble qflist toggle<cr>', { desc = 'Quickfix List' })
  vim.keymap.set('n', 'gr', '<cmd>Trouble lsp_references<cr>', { desc = 'LSP References' })
end)

-- Lualine (Statusline)
setup_if_exists('lualine', function(lualine)
  lualine.setup {
    options = {
      theme = 'tokyonight',
      component_separators = '|',
      section_separators = '',
    },
  }
end)

-- Bufferline (Tab/Buffer Bar)
setup_if_exists('bufferline', function(bufferline)
  bufferline.setup {
    options = {
      numbers = "none",
      close_command = "bdelete! %d",
      diagnostics = "nvim_lsp",
      offsets = {
        { filetype = "NvimTree", text = "File Explorer", text_align = "left" }
      },
    }
  }
  vim.keymap.set('n', '<Tab>', ':BufferLineCycleNext<CR>', { silent = true, desc = 'Next Buffer' })
  vim.keymap.set('n', '<S-Tab>', ':BufferLineCyclePrev<CR>', { silent = true, desc = 'Previous Buffer' })
  vim.keymap.set('n', '<leader>bd', ':bdelete<CR>', { silent = true, desc = 'Close Buffer' })
end)

-- Indent Blankline
setup_if_exists('ibl', function(ibl)
  ibl.setup {
    indent = { char = "│" },
    scope = { enabled = false },
  }
end)

-- Colorizer (for CSS color preview)
setup_if_exists('colorizer', function(colorizer)
  colorizer.setup()
end)

-- Enhanced LSP Keybindings
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = 'Go to Definition' }))
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = 'Go to Declaration' }))
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover Documentation' }))
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, { desc = 'Go to Implementation' }))
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename Symbol' }))
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code Action' }))
    vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, vim.tbl_extend('force', opts, { desc = 'Format Document' }))
  end,
})

-- None-ls (Linting & Formatting)
setup_if_exists('null-ls', function(null_ls)
  local builtins = null_ls.builtins
  null_ls.setup {
    sources = {
      -- JavaScript/TypeScript
      builtins.formatting.prettier.with({
        extra_filetypes = { "svelte" },
      }),
      builtins.diagnostics.eslint_d,

      -- Python
      builtins.formatting.black,
      builtins.diagnostics.ruff,

      -- Lua
      builtins.formatting.stylua,
    },
  }
end)

-- TypeScript Enhanced Setup
setup_if_exists('typescript', function(typescript)
  typescript.setup({
    server = {
      name = 'ts_ls',
      capabilities = require('cmp_nvim_lsp').default_capabilities(),
      on_attach = function(client, bufnr)
        vim.keymap.set('n', '<leader>oi', ':TypescriptOrganizeImports<CR>', { buffer = bufnr, desc = 'Organize Imports' })
        vim.keymap.set('n', '<leader>ru', ':TypescriptRemoveUnused<CR>', { buffer = bufnr, desc = 'Remove Unused' })
      end,
    },
  })
end)

-- DAP (Debugger) Setup
setup_if_exists('dap', function(dap)
  -- Python DAP
  pcall(function()
    require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')
  end)

  -- JavaScript/TypeScript DAP
  pcall(function()
    require('dap-vscode-js').setup({
      debugger_path = vim.fn.stdpath('data') .. '/site/pack/packer/opt/vscode-js-debug',
      adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
    })
    for _, language in ipairs({ 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' }) do
      dap.configurations[language] = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
      }
    end
  end)

  -- DAP UI
  pcall(function()
    local dapui = require('dapui')
    dapui.setup()
    dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
    dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
    dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end
  end)

  -- DAP Keymaps
  vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Continue' })
  vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
  vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
  vim.keymap.set('n', '<F12>', dap.step_out, { desc = 'Debug: Step Out' })
  vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
  vim.keymap.set('n', '<leader>dr', dap.repl.open, { desc = 'Debug: Open REPL' })
end)
