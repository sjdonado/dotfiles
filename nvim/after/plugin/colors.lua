local vscode = require("vscode")
local c = require("vscode.colors").get_colors()

local lualine = require("sjdonado.lualine")

vscode.setup({
  group_overrides = {
    ["@variable.builtin.typescript"] = { fg = c.vscBlue, bg = "NONE" },
    ["@property.method.typescript"] = { fg = c.vscYellow, bg = "NONE" },
    ["@constructor.typescript"] = { fg = c.vscBlue, bg = "NONE" },
    ["@keyword.typescript"] = { fg = c.vscBlue, bg = "NONE" },
    ["@keyword.return.typescript"] = { fg = c.vscPink, bg = "NONE" },
  },
})
vscode.load()

lualine.load()
