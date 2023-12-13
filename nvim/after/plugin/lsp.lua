local lspconfig = require("lspconfig")

local nnoremap = require("sjdonado.keymap").nnoremap

local cmp = require("cmp")
local lspkind = require("lspkind")
local lsp_signature = require("lsp_signature")
local neodev = require("neodev")

-- Setup nvim-cmp.
local source_mapping = {
  buffer = "[Buffer]",
  nvim_lsp = "[LSP]",
  luasnip = "[Snippet]",
  path = "[Path]",
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
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-y>"] = cmp.mapping.scroll_docs(4),
    ["<C-e>"] = cmp.mapping.scroll_docs(-4),
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

lsp_signature.setup({
  bind = true,
  handler_opts = {
    border = "single",
  },
  hint_enable = false,
})

local function config(_config)
  return vim.tbl_deep_extend("force", {
    capabilities = require("cmp_nvim_lsp").default_capabilities(
      vim.lsp.protocol.make_client_capabilities()
    ),
    on_attach = function(client, bufnr)
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
      nnoremap("]d", function()
        vim.diagnostic.goto_prev()
      end)
      nnoremap("[d", function()
        vim.diagnostic.goto_next()
      end)
      nnoremap("gA", function()
        vim.lsp.buf.code_action()
      end)
      nnoremap("gsr", function()
        vim.lsp.buf.rename()
      end)
    end,
  }, _config or {})
end

lspconfig.clangd.setup(config())

lspconfig.tsserver.setup(config())

lspconfig.jsonls.setup(config())
-- lspconfig.yamlls.setup(config())

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
      completion = {
        callSnippet = "Replace",
      },
    },
  },
}))

lspconfig.rust_analyzer.setup(config())

lspconfig.pylsp.setup(config())

lspconfig.theme_check.setup(config())

neodev.setup()
