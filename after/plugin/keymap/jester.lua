local Remap = require("sjdonado.keymap")
local nnoremap = Remap.nnoremap

nnoremap("<leader>rt", function() require"jester".run() end)
nnoremap("<leader>ra", function() require"jester".run_file() end)
nnoremap("<leader>lt", function() require"jester".run_last() end)
nnoremap("<leader>td", function() require"jester".debug() end)
nnoremap("<leader>ld", function() require"jester".debug_last() end)
