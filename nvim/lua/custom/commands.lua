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

-- Yank file location (Cmd+Shift+Y via Ghostty: \x01\x19)
local function yank_location(visual)
  local path = vim.fn.fnamemodify(vim.fn.expand '%', ':~:.')
  local location
  if visual then
    local start = vim.fn.line 'v'
    local finish = vim.fn.line '.'
    location = path .. ':' .. start .. '-' .. finish
  else
    location = path .. ':' .. vim.fn.line '.'
  end
  vim.fn.setreg('+', location)
  vim.notify(location)
end

vim.keymap.set('n', '\x01\x19', function() yank_location(false) end, { desc = 'Yank file location' })
vim.keymap.set('v', '\x01\x19', function() yank_location(true) end, { desc = 'Yank file location' })
