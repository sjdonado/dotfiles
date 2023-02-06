return require('packer').startup(function(use)
  -- core
  use 'wbthomason/packer.nvim'
  use 'nvim-lua/plenary.nvim'

  -- telescope
  use { 'nvim-telescope/telescope.nvim', tag = '*' }
  use 'nvim-telescope/telescope-dap.nvim'
  use 'stevearc/dressing.nvim'

  -- treesitter
  use('nvim-treesitter/nvim-treesitter', {
    run = ':TSUpdate'
  })
  use 'nvim-treesitter/nvim-treesitter-context'

  -- git
  use 'tpope/vim-fugitive'
  use { 'akinsho/git-conflict.nvim', tag = '*' }
  use 'lewis6991/gitsigns.nvim'

  -- apparence
  use 'f-person/auto-dark-mode.nvim'
  use 'nvim-tree/nvim-web-devicons'
  use 'projekt0n/github-nvim-theme'
  use {
    'lukas-reineke/indent-blankline.nvim',
    config = function() require('indent_blankline').setup() end
  }

  -- statusline
  use 'feline-nvim/feline.nvim'

  -- navigation
  use 'nvim-tree/nvim-tree.lua'

  use { 'akinsho/toggleterm.nvim', tag = '*' }
  use 'sjdonado/NeoZoom.lua'
  -- use 'nyngwang/NeoZoom.lua'
  use 'wsdjeg/vim-fetch'

  -- lsp + dap + linter package manager
  use 'williamboman/mason.nvim'
  use 'WhoIsSethDaniel/mason-tool-installer.nvim'

  -- lsp
  use 'neovim/nvim-lspconfig'
  use 'onsails/lspkind.nvim'

  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'

  -- dap
  use { 'mfussenegger/nvim-dap', tag = '*' }
  use { 'rcarriga/nvim-dap-ui', tag = 'v2*' }

  use { 'mxsdev/nvim-dap-vscode-js', tag = '*' }

  -- editor
  use 'Shatur/neovim-session-manager'
  use {
    'windwp/nvim-autopairs',
    config = function() require('nvim-autopairs').setup() end
  }
  use {
    'numToStr/Comment.nvim',
    config = function() require('Comment').setup() end
  }
  use 'justinmk/vim-sneak'
  use 'editorconfig/editorconfig-vim'
  use {
    'norcalli/nvim-colorizer.lua',
    config = function() require('colorizer').setup() end
  }

  -- js
  use 'David-Kunz/jester'

  -- go
  use 'fatih/vim-go'
end)
