local nnoremap = require("sjdonado.keymap").nnoremap

require("leetbuddy").setup({
  language = "cpp",
})

nnoremap("<leader>lq", ":LBQuestions<CR>", { silent = true, desc = "List Questions" })
nnoremap("<leader>ll", ":LBQuestion<CR>", { silent = true, desc = "View Question" })
nnoremap("<leader>lr", ":LBReset<CR>", { silent = true, desc = "Reset Code" })
nnoremap("<leader>lt", ":LBTest<CR>", { silent = true, desc = "Run Code" })
nnoremap("<leader>ls", ":LBSubmit<CR>", { silent = true, desc = "Submit Code" })
