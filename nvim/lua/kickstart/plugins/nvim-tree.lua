return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    renderer = {
      hidden_display = 'simple',
      icons = {
        show = {
          file = vim.g.have_nerd_font,
          folder = vim.g.have_nerd_font,
        },
      },
      indent_markers = {
        enable = true,
      },
    },
    disable_netrw = true,
    hijack_netrw = false,
    actions = {
      open_file = {
        quit_on_open = true,
      },
    },
    view = {
      width = 50,
    },
    notify = {
      threshold = vim.log.levels.ERROR,
    },
    on_attach = function(bufnr)
      local api = require 'nvim-tree.api'

      local function opts(desc)
        return {
          desc = 'Nvim Tree: ' .. desc,
          buffer = bufnr,
          noremap = true,
          silent = true,
          nowait = true,
        }
      end

      vim.keymap.set('n', '<CR>', api.node.open.edit, opts 'Open')
      vim.keymap.set('n', 'o', api.node.open.edit, opts 'Open')
      vim.keymap.set('n', 'I', api.tree.toggle_gitignore_filter, opts 'Toggle Git Ignore')
      vim.keymap.set('n', 'H', api.tree.toggle_hidden_filter, opts 'Toggle Dotfiles')
      vim.keymap.set('n', 'U', api.tree.toggle_custom_filter, opts 'Toggle Hidden')
      vim.keymap.set('n', 'R', api.tree.reload, opts 'Refresh')
      vim.keymap.set('n', 'a', api.fs.create, opts 'Create')
      vim.keymap.set('n', 'd', api.fs.remove, opts 'Delete')
      vim.keymap.set('n', 'D', api.fs.trash, opts 'Trash')
      vim.keymap.set('n', 'r', api.fs.rename, opts 'Rename')
      vim.keymap.set('n', 'x', api.fs.cut, opts 'Cut')
      vim.keymap.set('n', 'c', api.fs.copy.node, opts 'Copy')
      vim.keymap.set('n', 'p', api.fs.paste, opts 'Paste')
      vim.keymap.set('n', 'y', api.fs.copy.filename, opts 'Copy Name')
      vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts 'Copy Relative Path')
      vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, opts 'Copy Absolute Path')
      vim.keymap.set('n', 'W', api.tree.collapse_all, opts 'Collapse')
      vim.keymap.set('n', 'E', api.tree.expand_all, opts 'Expand All')
      vim.keymap.set('n', 'q', api.tree.close, opts 'Close')
      vim.keymap.set('n', 'g?', api.tree.toggle_help, opts 'Help')
    end,
  },
  keys = {
    { '<leader>e', '<cmd>NvimTreeFindFileToggle<CR>', { desc = 'Toggle Nvim Tree' } },
  },
}
