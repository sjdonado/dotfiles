local Remap = require("sjdonado.keymap")
local nnoremap = Remap.nnoremap

nnoremap("<leader>jr", function() require"jester".run() end)
nnoremap("<leader>ja", function() require"jester".run_file() end)
nnoremap("<leader>jl", function() require"jester".run_last() end)
nnoremap("<leader>jd", function() require"jester".debug() end)
nnoremap("<leader>jdl", function() require"jester".debug_last() end)
