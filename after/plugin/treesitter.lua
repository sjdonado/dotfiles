require'nvim-treesitter.configs'.setup {
  ensure_installed = { 'javascript', 'html', 'toml', 'yaml', 'dockerfile' },
    sync_install = false,

    highlight = {
      disable = { "lua", "rust" },
      enable = true,
      additional_vim_regex_highlighting = false,
    },
}

