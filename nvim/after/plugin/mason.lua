local mason = require("mason")
local masontoolinstaller = require("mason-tool-installer")

mason.setup({
	ui = {
		border = "double",
	},
})

masontoolinstaller.setup({
	ensure_installed = {
		"astro-language-server",
		"cpplint",
		"css-lsp",
		"delve",
		"eslint_d",
		"fixjson",
		"gopls",
		"js-debug-adapter",
		"lua-language-server",
		"prettierd",
		"staticcheck",
		"stylua",
		"typescript-language-server",
		"yaml-language-server",
	},
	run_on_start = false,
})
