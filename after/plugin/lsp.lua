local lspconfig = require("lspconfig")

local Remap = require("sjdonado.keymap")
local nnoremap = Remap.nnoremap
local inoremap = Remap.inoremap

local cmp = require("cmp")
local lspkind = require("lspkind")

-- Setup nvim-cmp.
local source_mapping = {
	buffer = "[Buffer]",
	nvim_lsp = "[LSP]",
	path = "[Path]",
}

cmp.setup({
	mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
	}),

	formatting = {
		format = function(entry, vim_item)
			vim_item.kind = lspkind.presets.default[vim_item.kind]
			local menu = source_mapping[entry.source.name]
			vim_item.menu = menu
			return vim_item
		end,
	},

	sources = {
		{ name = "nvim_lsp" },
		{ name = "buffer" },
	},
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

local function lsp_keymap()
  nnoremap("gd", function() vim.lsp.buf.definition() end)
  nnoremap("K", function() vim.lsp.buf.hover() end)
  nnoremap("<leader>vws", function() vim.lsp.buf.workspace_symbol() end)
  nnoremap("<leader>vd", function() vim.diagnostic.open_float() end)
  nnoremap("[d", function() vim.diagnostic.goto_next() end)
  nnoremap("]d", function() vim.diagnostic.goto_prev() end)
  nnoremap("<leader>vca", function() vim.lsp.buf.code_action() end)
  nnoremap("<leader>vrr", function() vim.lsp.buf.references() end)
  nnoremap("<leader>vrn", function() vim.lsp.buf.rename() end)
  inoremap("<C-h>", function() vim.lsp.buf.signature_help() end)
end

local function config(_config)
	return vim.tbl_deep_extend("force", {
		capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities()),
		on_attach = function()
      lsp_keymap()
		end,
	}, _config or {})
end

lspconfig.zls.setup(config())

lspconfig.tsserver.setup(config())

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

lspconfig.eslint.setup(config({
  on_attach = function(client)
    lsp_keymap()

    client.server_capabilities.document_formatting = true

    local autogroup_eslint_lsp = vim.api.nvim_create_augroup("eslint_lsp", { clear = true })

    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { '*.tsx', '*.ts', '*.jsx', '*.js' },
      command = "EslintFixAll",
      group = autogroup_eslint_lsp,
    })
  end
}))

lspconfig.jsonls.setup(config())
lspconfig.yamlls.setup(config())

lspconfig.ccls.setup(config())
lspconfig.cssls.setup(config())
