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

  -- editor
  use("Shatur/neovim-session-manager")
  use("JoosepAlviste/nvim-ts-context-commentstring")
  use({
    "numToStr/Comment.nvim",
    dependencies = "JoosepAlviste/nvim-ts-context-commentstring",
  })
  use("justinmk/vim-sneak")
  use("editorconfig/editorconfig-vim")
  use("folke/zen-mode.nvim")
  use("AndrewRadev/splitjoin.vim")
  use("moll/vim-bbye")
  use({
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end,
  })

  -- navigation
  use("nvim-tree/nvim-tree.lua")

  use("akinsho/toggleterm.nvim")
  use("wsdjeg/vim-fetch")

  use("ThePrimeagen/harpoon")
  use("kevinhwang91/nvim-bqf")

  -- treesitter
  use("nvim-treesitter/nvim-treesitter", {
    run = ":TSUpdate",
  })
  use("nvim-treesitter/nvim-treesitter-context")

  -- git
  use("NeogitOrg/neogit")
  use("lewis6991/gitsigns.nvim")
  use("almo7aya/openingh.nvim")
  use("akinsho/git-conflict.nvim")

  -- lsp
  use("neovim/nvim-lspconfig")
  use("nvimtools/none-ls.nvim")

  use("onsails/lspkind.nvim")
  use("ray-x/lsp_signature.nvim")

  use("hrsh7th/nvim-cmp")
  use("hrsh7th/cmp-nvim-lsp")
  use("hrsh7th/cmp-buffer")
  use("hrsh7th/cmp-path")

  use("dnlhc/glance.nvim")
  use({ lazy = true, "folke/neodev.nvim" })

  use({
    "L3MON4D3/LuaSnip",
    tag = "*",
    run = "make install_jsregexp",
    requires = { "saadparwaiz1/cmp_luasnip" },
  })

  -- apparence
  use("nvim-tree/nvim-web-devicons")
  use("folke/tokyonight.nvim")
  use("lukas-reineke/indent-blankline.nvim")
  use("nikvdp/ejs-syntax")
  use("tpope/vim-liquid")

  -- statusline
  use("nvim-lualine/lualine.nvim")

  -- package manager
  use({ lazy = true, "williamboman/mason.nvim", tag = "*" })
  use({ lazy = true, "WhoIsSethDaniel/mason-tool-installer.nvim" })

  -- dap
  use({ lazy = true, "mfussenegger/nvim-dap" })
  use({ lazy = true, "rcarriga/nvim-dap-ui" })
  use({ lazy = true, "theHamsta/nvim-dap-virtual-text" })

  -- testing
  use({ lazy = true, "sjdonado/jester" })
  use({ lazy = true, "klen/nvim-test" })

  -- AI Code Assistant
  use({ lazy = true, "Exafunction/codeium.vim", tag = "1.6.20" })

  -- utilities
  -- use({ lazy = true, "Dhanus3133/LeetBuddy.nvim" })
end)
