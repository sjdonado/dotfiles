local Remap = require("sjdonado.keymap")
local nnoremap = Remap.nnoremap

nnoremap("<leader>e", ":NvimTreeFindFileToggle<CR>", { silent = true })
