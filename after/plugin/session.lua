local session_manager = require('session_manager')

local nnoremap = require('sjdonado.keymap').nnoremap
local silent = { silent = true }

nnoremap('<leader>ls', session_manager.load_last_session, silent)
