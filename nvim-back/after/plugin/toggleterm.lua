local toggleterm = require("toggleterm")
local sjdonado_toggleterm = require("sjdonado.toggleterm")

toggleterm.setup({
  size = function(term)
    if term.direction == "horizontal" then
      return 25
    elseif term.direction == "vertical" then
      return vim.o.columns * 0.43
    end
  end,
})

sjdonado_toggleterm.create_terminal({
  direction = "horizontal",
  keymap = "<leader>;",
  count = 97,
})

sjdonado_toggleterm.create_terminal({
  direction = "vertical",
  keymap = "<leader>]",
  count = 98,
})
