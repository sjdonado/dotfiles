return require('packer').startup(function(use)
  -- core
  use 'wbthomason/packer.nvim'
  use 'nvim-lua/plenary.nvim'

  -- telescope
  use 'nvim-telescope/telescope.nvim'

  use 'nvim-telescope/telescope-dap.nvim'

  -- treesitter
  use("nvim-treesitter/nvim-treesitter", {
    run = ":TSUpdate"
  })
  use 'nvim-treesitter/nvim-treesitter-context'

  -- git
  use 'tpope/vim-fugitive'
  use { 'akinsho/git-conflict.nvim', tag = '*' }
  use 'lewis6991/gitsigns.nvim'

  -- apparence
  use 'projekt0n/github-nvim-theme'
  use 'nvim-tree/nvim-web-devicons'
  use 'feline-nvim/feline.nvim'

  -- navigation
  use 'ThePrimeagen/harpoon'
  use 'nvim-tree/nvim-tree.lua'

  use { "akinsho/toggleterm.nvim", tag = '*' }
  use 'nyngwang/NeoZoom.lua'

  -- lsp
  use 'neovim/nvim-lspconfig'
  use 'onsails/lspkind.nvim'

  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'saadparwaiz1/cmp_luasnip'

  -- dap
  use 'mfussenegger/nvim-dap'
  use 'rcarriga/nvim-dap-ui'

  use 'mxsdev/nvim-dap-vscode-js'
  use {
    "microsoft/vscode-js-debug",
    opt = true,
    run = "npm install --legacy-peer-deps && npm run compile"
  }

  -- editor
  use 'justinmk/vim-sneak'
  use {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup()
    end
  }

  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  }

  use 'editorconfig/editorconfig-vim'

  -- js
  use 'David-Kunz/jester'
end)
