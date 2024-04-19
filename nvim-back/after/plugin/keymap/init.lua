local map = require("sjdonado.keymap").map
local nnoremap = require("sjdonado.keymap").nnoremap
local vnoremap = require("sjdonado.keymap").vnoremap
local inoremap = require("sjdonado.keymap").inoremap
local tnoremap = require("sjdonado.keymap").tnoremap

-- Copy to clipboard
map({ "n", "v" }, "<leader>y", '"+y')

-- Copy text from the first character to the last character of the line
nnoremap("Y", '^"+yg_')

-- Join multiple lines
nnoremap("J", "mzJ`z")

-- Move line up or down
vnoremap("J", ":m '>+1<CR>gv=gv")
vnoremap("K", ":m '<-2<CR>gv=gv")

-- Insert an empty new line without entering insert mode
nnoremap("<leader>o", 'o<Esc>0"_D')
nnoremap("<leader>O", 'O<Esc>0"_D')

-- Search and replace word under cursor
nnoremap("<leader>sr", ":%s/\\<<C-r><C-w>\\>")

-- Toggle search and highlight word under cursor
nnoremap("<leader>ss", ":set hlsearch!<CR>:let @/='\\<<C-r><C-w>\\>'<CR>", { silent = true })

-- Navigate in quickfix window
nnoremap("<C-k>", "<cmd>cnext<CR>zz")
nnoremap("<C-j>", "<cmd>cprev<CR>zz")
nnoremap("<leader>k", "<cmd>lnext<CR>zz")
nnoremap("<leader>j", "<cmd>lprev<CR>zz")

-- Buffers scrolling
map({ "n", "v" }, "<C-y>", "6<C-y>")
map({ "n", "v" }, "<C-e>", "6<C-e>")
map({ "n", "v" }, "<C-l>", "12zl")
map({ "n", "v" }, "<C-h>", "12zh")

-- Move to buffer
nnoremap("<leader>b", ":b<space>")
vnoremap("<leader>b", ":b<space>")

-- Navigate between windows
nnoremap("<leader>tp", ":tabp<CR>", { silent = true })
nnoremap("<leader>tn", ":tabn<CR>", { silent = true })

-- Save changes
nnoremap("<C-s>", ":w<CR>")
inoremap("<C-s>", "<Esc>:w<CR>")

-- Close buffers
map(
  { "n", "v" },
  "<leader>q",
  ":Bdelete!<CR>",
  { silent = true, desc = "Force delete buffer without changing window layout" }
)
map(
  { "n", "v" },
  "<leader>Q",
  ":bd!<CR>",
  { silent = true, desc = "Delete buffer regardless of window layout" }
)
nnoremap("<C-w>a", ":%bd<CR><C-O>:bd!<CR>", { silent = true, desc = "Delete all buffers and exit" })
