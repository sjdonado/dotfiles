local nnoremap = require("sjdonado.keymap").nnoremap

nnoremap("<leader>a", function()
  require("harpoon.mark").add_file()
end, { silent = true })

nnoremap("<leader><Tab>", function()
  require("harpoon.ui").toggle_quick_menu()
end, { silent = true })

nnoremap("<leader>1", function()
  require("harpoon.ui").nav_file(1)
end, { silent = true })

nnoremap("<leader>2", function()
  require("harpoon.ui").nav_file(2)
end, { silent = true })

nnoremap("<leader>3", function()
  require("harpoon.ui").nav_file(3)
end, { silent = true })

nnoremap("<leader>4", function()
  require("harpoon.ui").nav_file(4)
end, { silent = true })

nnoremap("<leader>5", function()
  require("harpoon.ui").nav_file(5)
end, { silent = true })
