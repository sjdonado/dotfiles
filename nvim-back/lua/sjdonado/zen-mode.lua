local M = {}

function M.exit_zenmode_if_open()
  if require("zen-mode.view").is_open() then
    require("zen-mode").close()
  end
end

return M
