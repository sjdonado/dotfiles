-- This file can be loaded by calling `lua require('plugins')` from your init.vim

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-telescope/telescope-dap.nvim'

  use 'ThePrimeagen/harpoon'

  use("nvim-treesitter/nvim-treesitter", {
      run = ":TSUpdate"
  })
  use 'nvim-treesitter/nvim-treesitter-context'

  use 'projekt0n/github-nvim-theme'
  use 'lewis6991/gitsigns.nvim'
  use 'mattkubej/jest.nvim'

  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  }

  use 'neovim/nvim-lspconfig'
  use 'onsails/lspkind.nvim'
  use 'simrat39/symbols-outline.nvim'

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

  use 'feline-nvim/feline.nvim'
  use 'nvim-tree/nvim-web-devicons'

  use 'nyngwang/NeoZoom.lua'
end)

