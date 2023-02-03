local session_manager = require('session_manager')

local nnoremap = require('sjdonado.keymap').nnoremap

session_manager.setup({
  autoload_mode = require('session_manager.config').AutoloadMode.CurrentDir,
})

local custom_session_manager_group = vim.api.nvim_create_augroup('CustomSessionManager', { clear = true })

vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = 'global',
  group = custom_session_manager_group,
  callback = function ()
    if vim.bo.filetype ~= 'git'
      and not vim.bo.filetype ~= 'gitcommit'
      then session_manager.save_current_session() end
  end
})

vim.api.nvim_create_autocmd('DirChangedPre', {
  pattern = 'global',
  group = custom_session_manager_group,
  callback = function ()
    if vim.fn.argc() == 0 -- not git
      and not vim.v.event.changed_window -- it's cd
      then session_manager.save_current_session() end
  end
})

vim.api.nvim_create_autocmd('DirChanged', {
  pattern = 'global',
  group = custom_session_manager_group,
  callback = function ()
    if vim.fn.argc() == 0 -- not git
      and not vim.v.event.changed_window -- it's cd
      then session_manager.load_current_dir_session() end
    end
})

nnoremap('<leader>ls', session_manager.load_current_dir_session, { silent = true })
