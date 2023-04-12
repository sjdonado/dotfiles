local zenmode = require("zen-mode")

zenmode.setup({
  window = {
    width = 1,
  },
})

vim.keymap.set("n", "<leader>z", ":ZenMode<CR>", { silent = true })
