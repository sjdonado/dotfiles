local Remap = require("sjdonado.keymap")
local nnoremap = Remap.nnoremap
local vnoremap = Remap.vnoremap
local inoremap = Remap.inoremap
local xnoremap = Remap.xnoremap

-- Copy to clipboard
nnoremap("<leader>y", "\"+y")
vnoremap("<leader>y", "\"+y")

-- Keep it centered when searching
nnoremap("n", "nzzzv")
nnoremap("N", "Nzzzv")

-- Copy text from current line to the end of the line
nnoremap("Y", "yg$")

-- Join multiple lines
nnoremap("J", "mzJ`z")

-- Move line up or down
vnoremap("J", ":m '>+1<CR>gv=gv")
vnoremap("K", ":m '<-2<CR>gv=gv")

-- Search and replace word under cursor
nnoremap("<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

-- Navigate in quickfix window
nnoremap("<C-k>", "<cmd>cnext<CR>zz")
nnoremap("<C-j>", "<cmd>cprev<CR>zz")
nnoremap("<leader>k", "<cmd>lnext<CR>zz")
nnoremap("<leader>j", "<cmd>lprev<CR>zz")

-- Navigate between blank lines centered
nnoremap("(", "(zz")
nnoremap(")", ")zz")

-- Navigate smothly
nnoremap("{", "5kzz")
nnoremap("}", "5jzz")

-- Insert an empty new line without entering insert mode
nnoremap("<Leader>o", 'o<Esc>0"_D')
nnoremap("<Leader>O", 'O<Esc>0"_D')

