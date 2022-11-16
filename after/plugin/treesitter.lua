require'nvim-treesitter.configs'.setup {
  ensure_installed = { 'javascript', 'html', 'toml', 'yaml', 'dockerfile' },
  ignore_install = { 'rust', 'markdown' },

  sync_install = false,

  highlight = {
    enable = true,
    disable = { 'lua', 'help' },
    additional_vim_regex_highlighting = false,
  },
}
