local glance = require("glance")
local actions = glance.actions

glance.setup({
  border = {
    enable = true,
  },
  mappings = {
    list = {
      ["<C-y>"] = actions.preview_scroll_win(5),
      ["<C-e>"] = actions.preview_scroll_win(-5),
    },
  },
})
