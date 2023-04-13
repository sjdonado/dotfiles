local nnoremap = require("sjdonado.keymap").nnoremap
local tnoremap = require("sjdonado.keymap").tnoremap

require("toggleterm").setup({
  size = 25,
})

function _G.toggle_toggleterm()
  require("dapui").close({ "all" })
  exit_zenmode_if_needed()

  vim.cmd(":ToggleTerm<CR>")
end

local function set_terminal_keymaps()
  local opts = { buffer = 0, silent = true }
  tnoremap("<leader>;", "<C-\\><C-n><cmd>lua toggle_toggleterm()<CR>", opts)
end

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*toggleterm#*",
  callback = function()
    set_terminal_keymaps()
  end,
})

nnoremap("<leader>;", "<cmd>lua toggle_toggleterm()<CR><cmd>startinsert!<CR>")
