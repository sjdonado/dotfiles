local map = require("sjdonado.keymap").map

map({ "n", "v" }, "<leader>a", function()
  require("harpoon.mark").add_file()
end, { silent = true })

map({ "n", "v" }, "<leader><Tab>", function()
  require("harpoon.ui").toggle_quick_menu()
end, { silent = true })
