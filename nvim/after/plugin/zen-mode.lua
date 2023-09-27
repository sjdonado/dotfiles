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
  on_open = function(win)
    vim.g.zen_mode = true
  end,
  on_close = function()
    vim.g.zen_mode = false
  end,
})

nnoremap("<leader>z", ":ZenMode<CR>", { silent = true })
