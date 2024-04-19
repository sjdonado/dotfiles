local inoremap = require("sjdonado.keymap").inoremap
local map = require("sjdonado.keymap").map

local opts = { expr = true }

inoremap("<tab>", function()
  return vim.fn["codeium#Accept"]()
end, opts)

inoremap("<C-u>,", function()
  return vim.fn["codeium#CycleCompletions"](1)
end, opts)

inoremap("<C-u>.", function()
  return vim.fn["codeium#CycleCompletions"](-1)
end, opts)

inoremap("<C-u>x", function()
  return vim.fn["codeium#Clear"]()
end, opts)

map({ "n", "v" }, "<C-u>t", function()
  local current_value = vim.g.codeium_enabled
  vim.g.codeium_enabled = not current_value
end)
