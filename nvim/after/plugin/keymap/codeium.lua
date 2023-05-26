local inoremap = require("sjdonado.keymap").inoremap
local map = require("sjdonado.keymap").map

local opts = { expr = true }

inoremap("<C-e>", function()
  return vim.fn["codeium#Accept"]()
end, opts)

inoremap("<C-u>n", function()
  return vim.fn["codeium#CycleCompletions"](1)
end, opts)

inoremap("<C-u>p", function()
  return vim.fn["codeium#CycleCompletions"](-1)
end, opts)

inoremap("<C-u>x", function()
  return vim.fn["codeium#Clear"]()
end, opts)

map({ "n", "v" }, "<C-u>t", function()
  local current_value = vim.g.codeium_manual
  vim.g.codeium_manual = not current_value
  vim.notify("Codeium toggle: " .. tostring(vim.g.codeium_manual))
end)
