require('neo-zoom').setup({
  top_ratio = -1,
  left_ratio = 0.05,
  width_ratio = 0.96,
  height_ratio = 0.92,
  popup = {
    enabled = false,
  }
})

vim.keymap.set('n', '<leader>z', require("neo-zoom").neo_zoom, { silent = true, nowait = true })
