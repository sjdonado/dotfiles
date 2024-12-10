local function update_alacritty_theme(theme)
  local command = string.format(
    [[~/.config/dotfiles/bin/update_alacritty_theme.sh "%s"]],
    theme
  )
  vim.fn.system(command)
end

vim.api.nvim_create_user_command('UpdateAlacrittyTheme', function(args)
  update_alacritty_theme(args.args)
end, { nargs = 1, desc = 'Update Alacritty theme (dark or light)' })
