-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- [[ Custom Autocommands ]]

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ 'VimResized' }, {
  group = vim.api.nvim_create_augroup('kickstart-custom-auto-resize', { clear = true }),
  callback = function()
    vim.cmd 'tabdo wincmd ='
  end,
})

-- Dedicated isolated node version for neovim
vim.g.node_host_prog = vim.fn.expand '~/.local/share/nvim/node/bin/node'
vim.env.PATH = vim.fn.expand '~/.local/share/nvim/node/bin' .. ':' .. vim.env.PATH
vim.api.nvim_create_user_command('CheckNode', function()
  print('Node version: ' .. vim.fn.system(vim.g.node_host_prog .. ' -v'))
end, {})
