return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-dap.nvim'

  use 'ThePrimeagen/harpoon'

  use("nvim-treesitter/nvim-treesitter", {
    run = ":TSUpdate"
  })
  use 'nvim-treesitter/nvim-treesitter-context'
  use 'editorconfig/editorconfig-vim'

  use 'projekt0n/github-nvim-theme'
  use 'nvim-tree/nvim-tree.lua'

  use 'feline-nvim/feline.nvim'
  use 'nvim-tree/nvim-web-devicons'

  use 'lewis6991/gitsigns.nvim'

  use 'neovim/nvim-lspconfig'
  use 'onsails/lspkind.nvim'

  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'saadparwaiz1/cmp_luasnip'

  use 'mfussenegger/nvim-dap'
  use 'rcarriga/nvim-dap-ui'
  use 'mxsdev/nvim-dap-vscode-js'
  use {
    "microsoft/vscode-js-debug",
    opt = true,
    run = "npm install --legacy-peer-deps && npm run compile"
  }
  use 'David-Kunz/jester'

  use 'nyngwang/NeoZoom.lua'

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
end)
