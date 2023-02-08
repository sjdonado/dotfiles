local Remap = require('sjdonado.keymap')
local nnoremap = Remap.nnoremap
local vnoremap = Remap.vnoremap
local inoremap = Remap.inoremap
local xnoremap = Remap.xnoremap

-- Copy to clipboard
nnoremap('<leader>y', '\"+y')
vnoremap('<leader>y', '\"+y')

-- Copy text from current line to the end of the line
nnoremap('Y', 'yg$')

-- Join multiple lines
nnoremap('J', 'mzJ`z')

-- Move line up or down
vnoremap('J', ":m '>+1<CR>gv=gv")
vnoremap('K', ":m '<-2<CR>gv=gv")

-- Search and replace word under cursor
nnoremap('<leader>sr', ':%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>')

-- Navigate in quickfix window
nnoremap('<C-k>', '<cmd>cnext<CR>zz')
nnoremap('<C-j>', '<cmd>cprev<CR>zz')
nnoremap('<leader>k', '<cmd>lnext<CR>zz')
nnoremap('<leader>j', '<cmd>lprev<CR>zz')

-- Keep it centered when navigate
nnoremap('*', '*zz')
nnoremap('#', '#zz')

nnoremap('<C-y>', '6kzz')
nnoremap('<C-e>', '6jzz')
vnoremap('<C-y>', '6kzz')
vnoremap('<C-e>', '6jzz')

nnoremap('<C-o>', '<C-o>zz')
nnoremap('<C-i>', '<C-i>zz')

-- Keep it centered when searching
nnoremap('n', 'nzzzv')
nnoremap('N', 'Nzzzv')

-- Insert an empty new line without entering insert mode
nnoremap('<Leader>o', 'o<Esc>0"_D')
nnoremap('<Leader>O', 'O<Esc>0"_D')

-- Save changes
nnoremap('<C-s>', ':w<CR>')
inoremap('<C-s>', '<Esc>:w<CR>')

-- Buffers navigation
nnoremap('<C-w>d', ':bd!<CR>', { silent = true })
nnoremap('<C-w>x', ':bufdo bd<CR> set noim<CR>', { silent = true})
