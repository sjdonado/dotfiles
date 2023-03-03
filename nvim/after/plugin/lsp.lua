local lspconfig = require("lspconfig")

local Remap = require("sjdonado.keymap")
local nnoremap = Remap.nnoremap

local cmp = require("cmp")
local lspkind = require("lspkind")
local lsp_signature = require("lsp_signature")

-- Setup nvim-cmp.
local source_mapping = {
	buffer = "[Buffer]",
	nvim_lsp = "[LSP]",
	luasnip = "[Snippet]",
	path = "[Path]",
	copilot = "[Copilot]",
}

cmp.setup({
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	formatting = {
		format = function(entry, vim_item)
			local menu = source_mapping[entry.source.name]
			vim_item.kind = lspkind.presets.default[vim_item.kind]
			vim_item.menu = menu
			return vim_item
		end,
	},
	sources = {
		{ name = "nvim_lsp" },
		{ name = "buffer" },
		{ name = "luasnip" },
		{ name = "path" },
	},
})

local lsp_signature_cfg = {
	hint_enable = false,
}

local function config(_config)
	return vim.tbl_deep_extend("force", {
		capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities()),
		on_attach = function(client, bufnr)
			lsp_signature.setup(lsp_signature_cfg, bufnr)

			nnoremap("vh", function()
				vim.lsp.buf.hover()
			end)
			nnoremap("vs", function()
				vim.lsp.buf.signature_help()
			end)
			nnoremap("vd", function()
				vim.diagnostic.open_float()
			end)
			nnoremap("gd", function()
				vim.lsp.buf.definition()
			end)
			nnoremap("[d", function()
				vim.diagnostic.goto_next()
			end)
			nnoremap("]d", function()
				vim.diagnostic.goto_prev()
			end)
			nnoremap("<leader>vws", function()
				vim.lsp.buf.workspace_symbol()
			end)
			nnoremap("<leader>vca", function()
				vim.lsp.buf.code_action()
			end)
			nnoremap("<leader>vrr", function()
				vim.lsp.buf.references()
			end)
			nnoremap("<leader>vrn", function()
				vim.lsp.buf.rename()
			end)
		end,
	}, _config or {})
end

lspconfig.tsserver.setup(config())

lspconfig.jsonls.setup(config())
lspconfig.yamlls.setup(config())

lspconfig.ccls.setup(config())
lspconfig.cssls.setup(config())

lspconfig.gopls.setup(config({
	cmd = { "gopls", "serve" },
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
		},
	},
}))

lspconfig.lua_ls.setup(config({
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			},
			telemetry = {
				enable = false,
			},
		},
	},
}))

lspconfig.astro.setup(config())
