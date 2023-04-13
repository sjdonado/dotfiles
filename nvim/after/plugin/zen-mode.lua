local zenmode = require("zen-mode")

local nnoremap = require("sjdonado.keymap").nnoremap

zenmode.setup({
  window = {
    width = 1,
  },
})

function _G.exit_zenmode_if_needed()
  if require("zen-mode.view").is_open() then
    zenmode.close()
  end
end

nnoremap("<leader>z", ":ZenMode<CR>", { silent = true })
