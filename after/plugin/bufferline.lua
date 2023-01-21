require('bufferline').setup({
  options = {
    show_buffer_close_icons = false,
    show_close_icon = false,
    hover = {
      enabled = false
    }
  }
})

local nnoremap = require('sjdonado.keymap').nnoremap
local silent = { silent = true }

nnoremap('<C-w>d', ':bd!<CR>', silent)
nnoremap('<C-w>x', ':bufdo bd<CR> set noim<CR>', silent)
nnoremap('<C-w>p', ':BufferLineCycleNext<CR>', silent)
nnoremap('<C-w>o', ':BufferLineCyclePrev<CR>', silent)
