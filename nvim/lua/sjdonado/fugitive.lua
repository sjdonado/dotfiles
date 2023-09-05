local function git_tab_exists()
  local tabs = vim.api.nvim_list_tabpages()
  for _, tab in ipairs(tabs) do
    local windows = vim.api.nvim_tabpage_list_wins(tab)
    for _, win in ipairs(windows) do
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.fn.bufname(buf)
      if name == "Git" then
        return tab
      end
    end
  end
  return nil
end

local function create_or_switch_to_git_tab()
  local existing_tab = git_tab_exists()
  if existing_tab then
    vim.api.nvim_set_current_tabpage(existing_tab)
  else
    vim.cmd("tab Git")
  end
end

local M = {}
M.create_or_switch_to_git_tab = create_or_switch_to_git_tab

return M
