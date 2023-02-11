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
	use("tpope/vim-fugitive")
	use({ "akinsho/git-conflict.nvim", tag = "*" })
	use("lewis6991/gitsigns.nvim")

	-- apparence
	use("f-person/auto-dark-mode.nvim")
	use("nvim-tree/nvim-web-devicons")
	use("projekt0n/github-nvim-theme")
	use({
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("indent_blankline").setup()
		end,
	})

	-- statusline
	use("feline-nvim/feline.nvim")

	-- navigation
	use("nvim-tree/nvim-tree.lua")

	use({ "akinsho/toggleterm.nvim", tag = "*" })
	use("wsdjeg/vim-fetch")

	-- lsp + dap + linter package manager
	use("williamboman/mason.nvim")
	use("WhoIsSethDaniel/mason-tool-installer.nvim")

	-- lsp
	use("neovim/nvim-lspconfig")
	use("onsails/lspkind.nvim")
	use("jose-elias-alvarez/null-ls.nvim")

	use("hrsh7th/nvim-cmp")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-nvim-lsp-signature-help")
	use("hrsh7th/cmp-path")

	use({
		"L3MON4D3/LuaSnip",
		tag = "v<CurrentMajor>.*",
		run = "make install_jsregexp",
	})
	use("saadparwaiz1/cmp_luasnip")

	-- dap
	use({ "mfussenegger/nvim-dap" })
	use({ "rcarriga/nvim-dap-ui", tag = "v3.4.0" })

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
	use({ "folke/zen-mode.nvim" })

	-- copilot
	use({
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
				copilot_node_command = vim.fn.expand("$HOME") .. "/.nvm/versions/node/v18.*/bin/node",
			})
		end,
	})
	use({
		"zbirenbaum/copilot-cmp",
		after = { "copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	})

	-- js
	use("David-Kunz/jester")
end)
