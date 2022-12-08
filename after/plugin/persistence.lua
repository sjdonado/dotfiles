local persistence = require('persistence')

persistence.setup()

local nnoremap = require('sjdonado.keymap').nnoremap
local silent = { silent = true }

nnoremap('<leader>qs', function()
  persistence.load()
end, silent)
