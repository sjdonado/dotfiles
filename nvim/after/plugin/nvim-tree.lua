require("nvim-tree").setup({
  actions = {
    open_file = {
      quit_on_open = true,
    },
  },
  view = {
    width = 60,
    mappings = {
      custom_only = true,
      list = {
        { key = { "<CR>", "o", "<2-LeftMouse>" }, action = "edit" },
        { key = "I", action = "toggle_git_ignored" },
        { key = "H", action = "toggle_dotfiles" },
        { key = "U", action = "toggle_custom" },
        { key = "R", action = "refresh" },
        { key = "a", action = "create" },
        { key = "d", action = "remove" },
        { key = "D", action = "trash" },
        { key = "r", action = "rename" },
        { key = "x", action = "cut" },
        { key = "c", action = "copy" },
        { key = "p", action = "paste" },
        { key = "y", action = "copy_name" },
        { key = "Y", action = "copy_path" },
        { key = "gy", action = "copy_absolute_path" },
        { key = "W", action = "collapse_all" },
        { key = "E", action = "expand_all" },
        { key = "q", action = "close" },
        { key = "g?", action = "toggle_help" },
      },
    },
  },
})

-- nvim tree config
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
