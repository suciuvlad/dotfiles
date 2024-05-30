-- Define the installation path for packer.nvim
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

-- Check if packer.nvim is already installed
if fn.empty(fn.glob(install_path)) > 0 then
  -- Clone the packer.nvim repository from GitHub
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
  vim.cmd 'packadd packer.nvim'
end

-- Initialize and configure packer.nvim
return require('packer').startup(function(use)
  -- Let packer manage itself
  use { 'wbthomason/packer.nvim' }

  -- Vim Tmux Navigator
  use { 'christoomey/vim-tmux-navigator' }

  -- Catppuccin theme
  use {
    'catppuccin/nvim',
    as = 'catppuccin',
    config = function()
      require('user.plugins.catppuccin')
    end
  }

  -- Nvim Tree file explorer
  use {
    'kyazdani42/nvim-tree.lua',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function()
      require('user.plugins.nvim-tree')
    end
  }

  -- Vim Test plugin
  use {
    'vim-test/vim-test',
    config = function()
      require('user.plugins.vim-test')
    end
  }

  -- Floaterm plugin
  use {
    'voldikss/vim-floaterm',
    config = function()
      require('user.plugins.floaterm')
    end
  }

  -- Gitsigns plugin for Git integration
  use {
    'lewis6991/gitsigns.nvim',
    requires = 'nvim-lua/plenary.nvim',
    config = function()
      require('gitsigns').setup { sign_priority = 20 }
    end,
  }

  -- Trouble plugin for diagnostics
  use {
    'folke/trouble.nvim',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function()
      require('user.plugins.trouble')
      require('trouble').setup {}
    end
  }

  -- Mason and LSP configurations
  use {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
    config = function()
      require('user.plugins.lspconfig')
    end
  }

  -- Telescope for fuzzy finding
  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      { 'nvim-lua/plenary.nvim' },
      { 'kyazdani42/nvim-web-devicons' },
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
      { 'nvim-telescope/telescope-live-grep-raw.nvim' },
    },
    config = function()
      require('user.plugins.telescope')
    end
  }

  -- Splitjoin plugin
  use {
    'AndrewRadev/splitjoin.vim',
    config = function()
      require('user.plugins.splitjoin')
    end
  }

  -- Nvim-autopairs plugin
  use {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup()
    end
  }

  -- Neoscroll for smooth scrolling
  use {
    'karb94/neoscroll.nvim',
    config = function()
      require('user.plugins.neoscroll')
    end
  }

  -- Lualine statusline
  use {
    'nvim-lualine/lualine.nvim',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function()
      require('user.plugins.lualine')
    end
  }

  -- Nvim-lint for linting
  use {
    'mfussenegger/nvim-lint',
    config = function()
      require('user.plugins.nvim-lint')
    end
  }

  -- Fidget plugin for LSP progress
  use {
    'j-hui/fidget.nvim',
    config = function()
      require('fidget').setup{}
    end,
  }

  -- Vim Fugitive for Git
  use {
    'tpope/vim-fugitive',
    requires = 'tpope/vim-rhubarb',
    cmd = 'G',
  }

  -- Vim Pasta plugin
  use {
    'sickill/vim-pasta',
    config = function()
      require('user.plugins.pasta')
    end
  }

  -- Nvim CMP for completion
  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'saadparwaiz1/cmp_luasnip',
      'L3MON4D3/LuaSnip',
      'jessarcher/cmp-path',
      'hrsh7th/cmp-nvim-lua',
      'onsails/lspkind-nvim',
      'hrsh7th/cmp-nvim-lsp-signature-help',
    },
    config = function()
      require('user.plugins.cmp')
    end
  }

  -- LuaSnip snippet engine
  use {
    'L3MON4D3/LuaSnip',
    config = function()
      require('user.plugins.luasnip')
    end
  }

  -- Treesitter for syntax highlighting
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    requires = {
      'nvim-treesitter/playground',
      'nvim-treesitter/nvim-treesitter-textobjects',
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      require('user.plugins.treesitter')
      require('ts_context_commentstring').setup {}
      vim.g.skip_ts_context_commentstring_module = true
    end
  }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
