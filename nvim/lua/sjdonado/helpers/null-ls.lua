local diagnoistics = require("null-ls").methods.DIAGNOSTICS
local formatters = require("null-ls").methods.FORMATTING
local hovers = require("null-ls").methods.HOVER

local function list_registered_providers_names(filetype)
  local s = require("null-ls.sources")
  local available_sources = s.get_available(filetype)
  local registered = {}
  for _, source in ipairs(available_sources) do
    for method in pairs(source.methods) do
      registered[method] = registered[method] or {}
      table.insert(registered[method], source.name)
    end
  end
  return registered
end

local M = {}

function M.registered_linters(filetype)
  local registered_providers = list_registered_providers_names(filetype)
  return registered_providers[diagnoistics] or {}
end

function M.registered_formatters(filetype)
  local registered_providers = list_registered_providers_names(filetype)
  return registered_providers[formatters] or {}
end

function M.registered_hovers(filetype)
  local registered_providers = list_registered_providers_names(filetype)
  return registered_providers[hovers] or {}
end

return M
