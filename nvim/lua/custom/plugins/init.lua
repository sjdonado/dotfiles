return {
  { -- Smooth scroll
    'karb94/neoscroll.nvim',
    opts = {
      mappings = { -- Keys to be mapped to their corresponding default scrolling animation
        '<C-u>',
        '<C-d>',
        '<C-b>',
        '<C-f>',
        '<C-y>',
        '<C-e>',
        'zt',
        'zz',
        'zb',
      },
    },
  },
  { -- Color scheme
    'Mofiqul/vscode.nvim',
    config = function()
      local c = require('vscode.colors').get_colors()
      require('vscode').setup {
        -- style = 'light',
        disable_nvimtree_bg = true,
        group_overrides = {
          TelescopePromptBorder = { fg = c.vscCursorDark, bg = 'NONE' },
          TelescopeResultsBorder = { fg = c.vscCursorDark, bg = 'NONE' },
          TelescopePreviewBorder = { fg = c.vscCursorDark, bg = 'NONE' },
          DiagnosticHint = { fg = c.vscGray, bg = 'NONE' },
          DiagnosticUnderlineHint = { fg = 'NONE', bg = 'NONE', undercurl = true, sp = c.vscGray },
        },
      }
      vim.cmd.colorscheme 'vscode'
    end,
  },
  {
    'rmagatti/auto-session',
    lazy = false,
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
    opts = {
      auto_session_suppress_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
    },
  },
  { 'akinsho/git-conflict.nvim', version = '*', config = true },
  {
    'sindrets/diffview.nvim',
    lazy = false,
    keys = {
      { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = 'File Diff View History' },
      { '<leader>gm', '<cmd>DiffviewOpen --layout=diff1<CR>', desc = 'Merge Tool (Single Panel)' },
      { '<leader>gt', '<cmd>DiffviewToggle<CR>', desc = 'Toggle Diff View' },
      { '<leader>gc', '<cmd>DiffviewClose<CR>', desc = 'Close Diff View' },
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
      commit_editor = {
        staged_diff_split_kind = 'vsplit_left',
      },
    },
    keys = {
      { '<C-g>', '<cmd>Neogit<CR>', desc = 'Open Neogit' },
    },
  },
  {
    'folke/zen-mode.nvim',
    opts = {
      window = {
        width = 1,
      },
      on_open = function(win)
        vim.g.zen_mode_active = true
      end,
      on_close = function()
        vim.g.zen_mode_active = false
      end,
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
    'justinmk/vim-sneak',
    keys = {
      { 'f', '<Plug>Sneak_s', desc = 'Jump to any location specified by two charakters' },
      { 'F', '<Plug>Sneak_S', desc = 'Jump to any location specified by two characters (reverse)' },
    },
  },
  { 'wsdjeg/vim-fetch' },
  { 'vim-crystal/vim-crystal' },
  { 'amadeus/vim-mjml' },
  {
    'norcalli/nvim-colorizer.lua',
    opts = {
      '*',
      '!vim',
    },
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neotest/nvim-nio',
      'nvim-treesitter/nvim-treesitter',
      'marilari88/neotest-vitest',
    },
    config = function()
      local neotest = require 'neotest'

      neotest.setup {
        adapters = {
          require 'neotest-vitest' {},
        },
        output_panel = {
          enabled = true,
        },
      }

      vim.keymap.set('n', '<leader>tn', function()
        neotest.run.run()
      end, { desc = 'Run nearest test' })

      vim.keymap.set('n', '<leader>tf', function()
        neotest.run.run(vim.fn.expand '%')
      end, { desc = 'Run tests in file' })

      vim.keymap.set('n', '<leader>to', function()
        neotest.output.open()
      end, { desc = 'Toggle output panel' })
    end,
  },
  {
    'p-nerd/sr.nvim',
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('sr').setup {
        keymap = '<leader>s/',
        ignore_case = false,
        use_regex = false,
        preview_changes = true,
        live_preview = true,
      }
    end,
  },
  -- {
  --   'nvim-pack/nvim-spectre',
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --   },
  --   keys = {
  --     {
  --       '<leader>S',
  --       function()
  --         require('spectre').toggle()
  --       end,
  --       { desc = 'Toggle [S]pectre' },
  --     },
  --     {
  --       '<leader>sw',
  --       function()
  --         require('spectre').open_visual { select_word = true }
  --       end,
  --       { desc = '[S]earch current [W]ord' },
  --     },
  --     {
  --       '<leader>sp',
  --       function()
  --         require('spectre').open_file_search { select_word = true }
  --       end,
  --       { desc = '[S]earch on current File' },
  --     },
  --   },
  -- },
}
