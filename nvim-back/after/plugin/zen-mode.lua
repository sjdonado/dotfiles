local zenmode = require("zen-mode")

local nnoremap = require("sjdonado.keymap").nnoremap

zenmode.setup({
  window = {
    width = 1,
  },
  plugins = {
    options = {
      laststatus = 3,
    },
  },
})

nnoremap("<leader>z", ":ZenMode<CR>", { silent = true })
