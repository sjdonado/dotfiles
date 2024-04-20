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
