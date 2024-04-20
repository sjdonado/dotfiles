return {
  {
    'nvim-treesitter/nvim-treesitter-context',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      enable = true,
    },
  },
  {
    'akinsho/toggleterm.nvim',
    opts = {
      open_mapping = [[<c-\>]],
      on_create = function(term)
        vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], {
          buffer = term.bufnr,
          silent = true,
          desc = 'Exit terminal mode',
        })
        vim.keymap.set('t', '<C-w><C-h>', [[<Cmd>wincmd h<CR>]], {
          buffer = term.bufnr,
          silent = true,
          desc = 'Move focus to the left window',
        })
        vim.keymap.set('t', '<C-w><C-j>', [[<Cmd>wincmd j<CR>]], {
          buffer = term.bufnr,
          silent = true,
          desc = 'Move focus to the right window',
        })
        vim.keymap.set('t', '<C-w><C-k>', [[<Cmd>wincmd k<CR>]], {
          buffer = term.bufnr,
          silent = true,
          desc = 'Move focus to the lower window',
        })
        vim.keymap.set('t', '<C-w><C-l>', [[<Cmd>wincmd l<CR>]], {
          buffer = term.bufnr,
          silent = true,
          desc = 'Move focus to the upper window',
        })
      end,
      size = function(term)
        if term.direction == 'horizontal' then
          return 25
        elseif term.direction == 'vertical' then
          return vim.o.columns * 0.43
        end
      end,
    },
  },
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    opts = {
      signs = {
        item = { '', '' },
      },
      integrations = {
        telescope = nil,
      },
      mappings = {
        status = {
          [']x'] = 'GoToPreviousHunkHeader',
          ['[x'] = 'GoToNextHunkHeader',
        },
      },
    },
    keys = {
      { '<C-g>', '<cmd>Neogit<CR>', desc = 'Open Neogit' },
    },
  },
  {
    'olimorris/persisted.nvim',
    lazy = false, -- make sure the plugin is always loaded at startup
    opts = {
      autoload = true,
      on_autoload_no_session = function()
        vim.notify 'No existing session to load.'
      end,
    },
  },
  {
    'folke/zen-mode.nvim',
    opts = {
      window = {
        width = 1,
      },
    },
    keys = {
      { '<leader>z', '<cmd>ZenMode<CR>', desc = 'Toggle [Z]en Mode' },
    },
  },
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      disable_netrw = false,
      hijack_netrw = false,
      actions = {
        open_file = {
          quit_on_open = true,
        },
      },
      view = {
        width = 60,
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
  },
  {
    'akinsho/git-conflict.nvim',
    event = 'VimEnter',
    opts = {
      default_mappings = {
        ours = 'co',
        theirs = 'ct',
        none = 'c0',
        both = 'cb',
        prev = ']x',
        next = '[x',
      },
    },
  },
}
