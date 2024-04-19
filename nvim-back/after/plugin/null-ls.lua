local null_ls = require("null-ls")

local file_helper = require("sjdonado.helpers.file")

local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.clang_format,
    null_ls.builtins.diagnostics.staticcheck,
    null_ls.builtins.formatting.prettierd,
    null_ls.builtins.formatting.stylua,
  },
  on_attach = function(client, bufnr)
    if
      client.supports_method("textDocument/formatting")
      or client.supports_method("textDocument/rangeFormatting")
    then
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
    if not file_helper.root_has_file(".prettier*") then
      null_ls.disable({ name = "prettierd" })
    end

    if not file_helper.root_has_file(".editorconfig*") then
      null_ls.disable({ name = "editorconfig_checker" })
    end
  end,
})
