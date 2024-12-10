local function update_alacritty_theme(theme)
  local alacritty_config_path = os.getenv('HOME') .. '/.config/dotfiles/alacritty/alacritty.toml'
  local command = string.format(
    [[sed -i '/^import = / s#^import = .*#import = ["~/.config/alacritty/themes/%s.toml"]#' %s]],
    theme, alacritty_config_path
  )
  vim.fn.system(command)
end

vim.api.nvim_create_user_command('UpdateAlacrittyTheme', function(args)
  update_alacritty_theme(args.args)
end, { nargs = 1, desc = 'Update Alacritty theme (dark or light)' })
