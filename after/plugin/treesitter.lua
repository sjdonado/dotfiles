require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"javascript",
		"html",
		"toml",
		"yaml",
		"dockerfile",
		"http",
		"json",
		"lua",
		"rust",
		"go",
	},
	ignore_install = { "markdown" },
	sync_install = false,
	highlight = {
		enable = true,
		disable = { "help", "markdown" },
		additional_vim_regex_highlighting = false,
	},
})
