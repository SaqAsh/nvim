-- init.lua

-- 1. Bootstrap packer.nvim (plugin manager)
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  print("Installing packer…")
  fn.system({
    'git','clone','--depth','1',
    'https://github.com/wbthomason/packer.nvim', install_path,
  })
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

-- 3. Plugins
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  use 'neovim/nvim-lspconfig'

  use {
    'williamboman/mason.nvim',
    run = function() pcall(vim.cmd, 'MasonUpdate') end
  }
  use 'williamboman/mason-lspconfig.nvim'

  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'L3MON4D3/LuaSnip'
  use 'rafamadriz/friendly-snippets'

  use 'windwp/nvim-autopairs'
  use 'akinsho/toggleterm.nvim'
  use 'tpope/vim-commentary'

  use {
    'nvim-tree/nvim-tree.lua',
    requires = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup {}
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true })
    end,
  }

  use {
    'folke/tokyonight.nvim',
    config = function()
      require('tokyonight').setup({
        style = "night",
        transparent = false,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { bold = true },
        },
      })
      vim.cmd("colorscheme tokyonight")
    end
  }

  use {
    'nvimtools/none-ls.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      'nvimtools/none-ls-extras.nvim',
    },
    config = function()
      local null_ls = require('null-ls')
      local aug = vim.api.nvim_create_augroup("LspFormatting", { clear = true })

      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.prettier,
          null_ls.builtins.formatting.clang_format,
          null_ls.builtins.formatting.google_java_format,
          -- removed: require("none-ls.diagnostics.eslint_d"),
        },
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = aug, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = aug,
              buffer = bufnr,
              callback = function() vim.lsp.buf.format() end,
            })
          end
        end,
      })
    end,
  }
end)

-- 4. Treesitter setup
require('nvim-treesitter.configs').setup {
  ensure_installed = {
    'c','cpp',
    'javascript','typescript','tsx',
    'html','css','json',
    'java',
    'lua','bash',
  },
  highlight = { enable = true },
  indent    = { enable = true },
}

-- 5. Mason & LSP setup
 require('mason').setup()
 require('mason-lspconfig').setup {
   ensure_installed = {
     'clangd',
    'ts_ls',
    'jdtls',
    'html',
    'cssls',
    'jsonls',
  },
}
-- 5b. Enhance LSP capabilities for nvim-cmp
local capabilities = require('cmp_nvim_lsp').default_capabilities()

 local lspconfig = require('lspconfig')
lspconfig.clangd.setup    { capabilities = capabilities }
-- lspconfig.ts_ls.setup  {
  -- capabilities = capabilities,
   -- on_attach = function(client)
     -- client.server_capabilities.documentFormattingProvider = false
   -- end
  -- }
lspconfig.jdtls.setup     { capabilities = capabilities }
lspconfig.html.setup      { capabilities = capabilities }
lspconfig.cssls.setup     { capabilities = capabilities }
lspconfig.jsonls.setup    { capabilities = capabilities }

-- 6. Completion (nvim-cmp) + snippets
local cmp     = require('cmp')
local luasnip = require('luasnip')
require('luasnip.loaders.from_vscode').lazy_load()

cmp.setup{
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>']     = cmp.mapping.confirm({ select = true }),
    ['<Tab>']    = cmp.mapping(function(fallback)
                      if cmp.visible() then cmp.select_next_item()
                      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
                      else fallback()
                      end
                    end, {'i','s'}),
    ['<S-Tab>']  = cmp.mapping(function(fallback)
                      if cmp.visible() then cmp.select_prev_item()
                      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
                      else fallback()
                      end
                    end, {'i','s'}),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip'  },
  },
}

-- 7. Auto-pairs
require('nvim-autopairs').setup{}

-- 8. ToggleTerm for building & running
require('toggleterm').setup{
  size = 15,
  direction = 'horizontal',
}

vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
vim.keymap.set('n','<F5>', function()
  local f = vim.fn.expand("%:t:r")
  vim.cmd('TermExec cmd="gcc % -o '..f..' && ./'..f..'"')
end, {desc = "Compile & run C"})
vim.keymap.set('n','<F6>', function()
  vim.cmd('TermExec cmd="python3 -m http.server --bind 127.0.0.1 8000"')
end, {desc = "Start simple HTTP server"})

-- 9. Filetype-specific indentation
vim.api.nvim_create_autocmd("FileType", {
  pattern = "c",
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop    = 4
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "html",
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop    = 2
  end,
})

-- 🔧 Show diagnostic messages under squiggles
vim.diagnostic.config({
  virtual_text = {
    prefix = "●",
    spacing = 2,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.cmd [[
  autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false })
]]
vim.api.nvim_set_keymap('n', '<C-z>', 'u', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-z>', ':echo "Ctrl+Z is disabled for suspend"<CR>', { noremap = true, silent = true })
