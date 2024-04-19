local M = {}

function M.remove_duplicates(t)
  local new_t = {}
  local seen = {}
  for _, v in ipairs(t) do
    if not seen[v] then
      table.insert(new_t, v)
      seen[v] = true
    end
  end
  return new_t
end

return M
