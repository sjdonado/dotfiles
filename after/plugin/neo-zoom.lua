local neozoom = require('neo-zoom')

neozoom.setup({
  top_ratio = -1,
  left_ratio = 0.05,
  width_ratio = 0.96,
  height_ratio = 0.92,
  highlight_overrides = {
    bg = 'none',
  },
  popup = {
    enabled = false,
  },
})

vim.keymap.set('n', '<leader>z', neozoom.neo_zoom, { silent = true, nowait = true })
