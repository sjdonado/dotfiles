local nnoremap = require("sjdonado.keymap").nnoremap

local silent = { silent = true }

nnoremap("<leader>a", function() require("harpoon.mark").add_file() end, silent)
nnoremap("<C-e>", function() require("harpoon.ui").toggle_quick_menu() end, silent)

--[[ nnoremap("<C-h>", function() require("harpoon.ui").nav_file(1) end, silent)
nnoremap("<C-j>", function() require("harpoon.ui").nav_file(2) end, silent)
nnoremap("<C-k>", function() require("harpoon.ui").nav_file(3) end, silent)
nnoremap("<C-l>", function() require("harpoon.ui").nav_file(4) end, silent) ]]

