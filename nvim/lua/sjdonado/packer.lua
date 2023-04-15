return require("packer").startup(function(use)
  -- core
  use("wbthomason/packer.nvim")
  use("nvim-lua/plenary.nvim")

  -- telescope
  use({ "nvim-telescope/telescope.nvim", tag = "*" })
  use("nvim-telescope/telescope-dap.nvim")
  use("stevearc/dressing.nvim")

  -- treesitter
  use("nvim-treesitter/nvim-treesitter", {
    run = ":TSUpdate",
  })
  use("nvim-treesitter/nvim-treesitter-context")

  -- git
  use("kdheepak/lazygit.nvim")
  use("lewis6991/gitsigns.nvim")

  -- apparence
  use("nvim-tree/nvim-web-devicons")
  use("Mofiqul/vscode.nvim")
  use({
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require("indent_blankline").setup()
    end,
  })

  -- statusline
  use("nvim-lualine/lualine.nvim")

  -- navigation
  use("nvim-tree/nvim-tree.lua")

  use({ "akinsho/toggleterm.nvim" })
  use("wsdjeg/vim-fetch")

  -- lsp + dap + linter package manager
  use("williamboman/mason.nvim")
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
  use("folke/neodev.nvim")

  use({
    "L3MON4D3/LuaSnip",
    tag = "v<CurrentMajor>.*",
    run = "make install_jsregexp",
  })
  use("saadparwaiz1/cmp_luasnip")

  -- dap
  use({ lazy = true, "mfussenegger/nvim-dap" })
  use({ lazy = true, "rcarriga/nvim-dap-ui", tag = "*" })
  use({ lazy = true, "theHamsta/nvim-dap-virtual-text" })

  use({ "mxsdev/nvim-dap-vscode-js", tag = "*" })

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

  -- copilot
  use({
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        panel = { enabled = false },
        suggestion = { auto_trigger = true },
        copilot_node_command = "/opt/homebrew/bin/node",
      })
    end,
  })

  -- testing
  use("David-Kunz/jester")
end)
