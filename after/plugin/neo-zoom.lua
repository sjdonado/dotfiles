local neo_zoom = require('neo-zoom')

neo_zoom.setup({
  top_ratio = -1,
  left_ratio = 0.05,
  width_ratio = 0.99,
  height_ratio = 0.92,
  callbacks = {
    function ()
      vim.api.nvim_set_hl(0, 'NormalFloat', {
        bg = 'none',
      })
    end,
  },
  popup = {
    enabled = false,
  },
})

vim.keymap.set('n', '<leader>z', neo_zoom.neo_zoom, { silent = true, nowait = true })
