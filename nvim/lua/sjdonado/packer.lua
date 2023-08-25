return require("packer").startup(function(use)
  -- core
  use("wbthomason/packer.nvim")
  use("nvim-lua/plenary.nvim")

  -- telescope
  use({
    "nvim-telescope/telescope.nvim",
    requires = {
      "nvim-telescope/telescope-dap.nvim",
      "stevearc/dressing.nvim",
    },
  })

  -- treesitter
  use("nvim-treesitter/nvim-treesitter", {
    run = ":TSUpdate",
  })
  use("nvim-treesitter/nvim-treesitter-context")

  -- git
  use("lewis6991/gitsigns.nvim")
  use("almo7aya/openingh.nvim")

  -- apparence
  use("nvim-tree/nvim-web-devicons")
  use("projekt0n/github-nvim-theme")
  use({
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require("indent_blankline").setup()
    end,
  })
  use("nikvdp/ejs-syntax")
  use("tpope/vim-liquid")

  -- statusline
  use("nvim-lualine/lualine.nvim")

  -- navigation
  use("nvim-tree/nvim-tree.lua")

  use("akinsho/toggleterm.nvim")
  use("wsdjeg/vim-fetch")

  use("ThePrimeagen/harpoon")

  -- lsp + dap + linter package manager
  use({ "williamboman/mason.nvim", tag = "*" })
  use("WhoIsSethDaniel/mason-tool-installer.nvim")

  -- lsp
  use("neovim/nvim-lspconfig")
  use("jose-elias-alvarez/null-ls.nvim")

  use("onsails/lspkind.nvim")
  use("ray-x/lsp_signature.nvim")

  use("hrsh7th/nvim-cmp")
  use("hrsh7th/cmp-nvim-lsp")
  use("hrsh7th/cmp-buffer")
  use("hrsh7th/cmp-path")

  use("dnlhc/glance.nvim")

  use("folke/neodev.nvim")

  use({
    "L3MON4D3/LuaSnip",
    tag = "*",
    run = "make install_jsregexp",
    requires = { "saadparwaiz1/cmp_luasnip" },
  })

  -- dap
  use({ lazy = true, "mfussenegger/nvim-dap" })
  use({ lazy = true, "rcarriga/nvim-dap-ui" })
  use({ lazy = true, "theHamsta/nvim-dap-virtual-text" })

  -- editor
  use("Shatur/neovim-session-manager")
  use("numToStr/Comment.nvim")
  use("justinmk/vim-sneak")
  use("editorconfig/editorconfig-vim")
  use({
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end,
  })
  use("folke/zen-mode.nvim")
  use("AndrewRadev/splitjoin.vim")

  -- AI Code Assistant
  use("Exafunction/codeium.vim")

  -- testing
  use("David-Kunz/jester")
end)
