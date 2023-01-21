return require('packer').startup(function(use)
  -- core
  use 'wbthomason/packer.nvim'
  use 'nvim-lua/plenary.nvim'

  -- telescope
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-dap.nvim'

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
  use { 'projekt0n/github-nvim-theme', tag = 'v0.0.5' }
  use 'nvim-tree/nvim-web-devicons'
  use {
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      require('indent_blankline').setup()
    end
  }

  use 'feline-nvim/feline.nvim'

  -- navigation
  use {'akinsho/bufferline.nvim', tag = 'v3.*'}
  use 'nvim-tree/nvim-tree.lua'

  use { 'akinsho/toggleterm.nvim', tag = '*' }
  use 'nyngwang/NeoZoom.lua'
  use 'wsdjeg/vim-fetch'

  -- lsp
  use 'neovim/nvim-lspconfig'
  use 'onsails/lspkind.nvim'

  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'saadparwaiz1/cmp_luasnip'

  -- dap
  use 'mfussenegger/nvim-dap'
  use { 'rcarriga/nvim-dap-ui', tag = '*' }

  -- dap typescript
  use 'mxsdev/nvim-dap-vscode-js'
  use {
    'microsoft/vscode-js-debug',
    opt = true,
    run = 'npm install --legacy-peer-deps && npm run compile',
    tag = '*'
  }

  -- editor
  use { 'Shatur/neovim-session-manager'}
  use {
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup()
    end
  }
  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  }
  use 'justinmk/vim-sneak'
  use 'editorconfig/editorconfig-vim'

  -- utils
  use { 'rest-nvim/rest.nvim', tag = '*' }

  -- js
  use 'David-Kunz/jester'

  -- go
  use 'fatih/vim-go'
end)
