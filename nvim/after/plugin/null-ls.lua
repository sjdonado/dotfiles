local null_ls = require("null-ls")

local nnoremap = require("sjdonado.keymap").nnoremap
local file_helper = require("sjdonado.helpers.file")

local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })

local eslint_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "vue",
}

null_ls.setup({
  sources = {
    null_ls.builtins.diagnostics.shellcheck,
    null_ls.builtins.diagnostics.cpplint,
    null_ls.builtins.diagnostics.staticcheck,
    null_ls.builtins.diagnostics.eslint_d.with({ filetypes = eslint_filetypes }),
    null_ls.builtins.formatting.eslint_d.with({ filetypes = eslint_filetypes }),
    null_ls.builtins.formatting.prettierd,
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.formatting.fixjson,
    null_ls.builtins.formatting.rustfmt,
    null_ls.builtins.formatting.taplo,
    null_ls.builtins.formatting.ruff,
  },
  on_attach = function(client, bufnr)
    if
      client.supports_method("textDocument/formatting")
      or client.supports_method("textDocument/rangeFormatting")
    then
      nnoremap("<leader>f", function()
        vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
      end, { buffer = bufnr, desc = "[LSP] Format" })

      vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        group = group,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr, async = false })
        end,
        desc = "[LSP] Format on save",
      })
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    if not file_helper.root_has_file("{.prettier*,*prettier*}") then
      null_ls.disable({ name = "prettierd" })
    end

    if not file_helper.root_has_file("{.eslint*,*eslint*}") then
      null_ls.disable({ name = "eslint_d" })
    end
  end,
})
