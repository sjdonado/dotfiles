require('neo-zoom').setup({
  top_ratio = -1,
  left_ratio = 0.05,
  width_ratio = 0.96,
  height_ratio = 0.92,
})

local NOREF_NOERR_TRUNC = { silent = true, nowait = true }
vim.keymap.set('n', '<leader>z', require("neo-zoom").neo_zoom, NOREF_NOERR_TRUNC)
