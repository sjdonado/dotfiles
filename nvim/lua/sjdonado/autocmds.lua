local custom_autocmds_group = vim.api.nvim_create_augroup("CustomAutocmds", { clear = true })

-- check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = custom_autocmds_group,
  command = "checktime",
})

-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = custom_autocmds_group,
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = custom_autocmds_group,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- wrap and check for spell in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = custom_autocmds_group,
  pattern = { "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- hide CursorLine on leave window (ignore Floating windows)
vim.api.nvim_create_autocmd("WinEnter", {
  group = custom_autocmds_group,
  pattern = { "*", "*.git/*" },
  command = "setlocal cursorline",
})
vim.api.nvim_create_autocmd("WinLeave", {
  group = custom_autocmds_group,
  pattern = { "*", "*.git/*" },
  command = "setlocal nocursorline",
})
