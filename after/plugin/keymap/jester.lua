local jester = require('jester')

local Remap = require('sjdonado.keymap')
local nnoremap = Remap.nnoremap

nnoremap('<leader>jr', function() jester.run() end)
nnoremap('<leader>jl', function() jester.run_last() end)
nnoremap('<leader>ja', function() jester.run_file() end)
nnoremap('<leader>jd', function() jester.debug() end)
nnoremap('<leader>jdl', function() jester.debug_last() end)
