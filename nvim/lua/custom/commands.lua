local theme_file = vim.fn.stdpath('state') .. '/current_theme'

local function initialize_theme()
  if vim.loop.fs_stat(theme_file) then
    local theme = vim.fn.readfile(theme_file)[1]
    if theme and (theme == 'dark' or theme == 'light') then
      vim.api.nvim_set_option_value('background', theme, {})
    end
  end
end

vim.schedule(initialize_theme)

-- Watch for changes in the theme file
local fs_event = vim.loop.new_fs_event()
if fs_event then
  fs_event:start(theme_file, {}, function()
    vim.schedule(function()
      -- Read the current theme safely inside the scheduled block
      local updated_theme = vim.fn.readfile(theme_file)[1]
      if updated_theme and vim.o.background ~= updated_theme then
        vim.api.nvim_set_option_value('background', updated_theme, {})
      end
    end)
  end)
end

-- Command to toggle the appearance and update the theme file
vim.api.nvim_create_user_command('ToggleAppearance', function()
  local new_theme = vim.o.background == 'dark' and 'light' or 'dark'

  vim.api.nvim_set_option_value('background', new_theme, {})

  local command = string.format([[~/.config/dotfiles/bin/update_alacritty_theme.sh "%s"]], new_theme)
  vim.fn.system(command)

  vim.fn.writefile({ new_theme }, theme_file)
end, {
  desc = 'Toggle between dark and light themes for Neovim and Alacritty, and sync across instances',
})

-- Dedicated isolated node version for neovim
vim.g.node_host_prog = vim.fn.expand("~/.local/share/nvim/node/bin/node")
vim.env.PATH = vim.fn.expand("~/.local/share/nvim/node/bin") .. ":" .. vim.env.PATH
vim.api.nvim_create_user_command("CheckNode", function()
  print("Node version: " .. vim.fn.system(vim.g.node_host_prog .. " -v"))
end, {})
