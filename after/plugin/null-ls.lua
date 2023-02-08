local null_ls = require("null-ls")

local Remap = require("sjdonado.keymap")
local nnoremap = Remap.nnoremap

local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })

null_ls.setup({
	sources = {
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.diagnostics.eslint,
	},
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			nnoremap("<leader>f", function()
				vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
			end, { buffer = bufnr, desc = "[LSP] Linter format" })

			-- format on save
			vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
			vim.api.nvim_create_autocmd("BufWritePre", {
				buffer = bufnr,
				group = group,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr, async = false })
				end,
				desc = "[LSP] format on save",
			})
		end

		if client.supports_method("textDocument/rangeFormatting") then
			nnoremap("<leader>f", function()
				vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
			end, { buffer = bufnr, desc = "[LSP] Linter format" })
		end
	end,
})

require("prettier").setup({
	bin = "prettier",
	filetypes = {
		"css",
		"graphql",
		"html",
		"javascript",
		"javascriptreact",
		"json",
		"less",
		"markdown",
		"scss",
		"typescript",
		"typescriptreact",
		"yaml",
	},
})
