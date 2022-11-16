require('neo-zoom').setup()

local NOREF_NOERR_TRUNC = { silent = true, nowait = true }
vim.keymap.set('n', '<leader>z', require("neo-zoom").neo_zoom, NOREF_NOERR_TRUNC)
