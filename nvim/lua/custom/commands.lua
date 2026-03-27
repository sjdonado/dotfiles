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

-- Dedicated isolated node version for neovim LSP servers
vim.env.PATH = vim.fn.expand '~/.local/share/nvim/node/bin' .. ':' .. vim.env.PATH
vim.env.NODE_OPTIONS = '--max-old-space-size=4096'

-- LSP manual toggle (disabled by default)
local lsp_disabled = true

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach-guard', { clear = true }),
  callback = function(args)
    local should_detach = lsp_disabled or not vim.bo[args.buf].modifiable
    if should_detach then
      vim.schedule(function()
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
          if lsp_disabled then
            client:stop()
          else
            vim.lsp.buf_detach_client(args.buf, client.id)
          end
        end
      end)
    end
  end,
})

vim.api.nvim_create_user_command('LspToggle', function()
  if lsp_disabled then
    vim.cmd 'LspStart'
    lsp_disabled = false
    vim.notify('LSP servers started', vim.log.levels.INFO)
  else
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop()
    end
    lsp_disabled = true
    vim.notify('LSP servers stopped', vim.log.levels.INFO)
  end
end, { desc = 'Toggle all LSP servers' })

vim.keymap.set('n', '<leader>tl', '<cmd>LspToggle<CR>', { desc = '[T]oggle [L]SP servers' })

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
