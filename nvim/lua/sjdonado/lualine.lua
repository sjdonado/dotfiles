local lualine = require("lualine")
local nvimwebdevicons = require("nvim-web-devicons")

local null_ls_helper = require("sjdonado.helpers.null-ls")
local table_helper = require("sjdonado.helpers.table")

nvimwebdevicons.setup({
  color_icons = true,
})

local function lsp_clients(msg)
  msg = msg or ""
  local buf_clients = vim.lsp.get_active_clients()
  if next(buf_clients) == nil then
    if type(msg) == "boolean" or #msg == 0 then
      return ""
    end
    return msg
  end

  local buf_ft = vim.bo.filetype
  local buf_client_names = {}

  for _, client in pairs(buf_clients) do
    if client.name ~= "null-ls" then
      table.insert(buf_client_names, client.name)
    end
  end

  local supported_formatters = null_ls_helper.registered_formatters(buf_ft)
  vim.list_extend(buf_client_names, supported_formatters)

  local supported_linters = null_ls_helper.registered_linters(buf_ft)
  vim.list_extend(buf_client_names, supported_linters)

  local supported_hovers = null_ls_helper.registered_hovers(buf_ft)
  vim.list_extend(buf_client_names, supported_hovers)

  return table.concat(table_helper.remove_duplicates(buf_client_names), " ")
end

local function zen_mode_status()
  return vim.g.zen_mode and "🔎 zen_mode ON" or ""
end

local sections = {
  lualine_a = { "mode" },
  lualine_b = { "branch", "diff" },
  lualine_c = {
    { "%=", separator = "" },
    { "filetype", icon_only = true, separator = "", padding = { right = 0, left = 1 } },
    {
      "filename",
      path = 1,
      symbols = { modified = "●", readonly = "", unnamed = "[No Name]", newfile = "[New]" },
    },
  },
  lualine_x = {
    { "searchCount" },
    { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } },
    {
      lsp_clients,
      icon = " ",
      color = { gui = "bold" },
    },
    {
      "codeium#GetStatusString",
      icon = "🤖",
      color = { gui = "bold" },
    },
    { zen_mode_status, color = { gui = "bold" } },
    { "encoding" },
  },
  lualine_y = { "progress" },
  lualine_z = { "location" },
}

local inactive_sections = {
  lualine_x = { "location" },
}

local M = {}

M.load = function()
  lualine.setup({
    sections = sections,
    inactive_sections = inactive_sections,
  })
end

return M
