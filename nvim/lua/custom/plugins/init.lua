return {
  { 'wsdjeg/vim-fetch' },
  { 'vim-crystal/vim-crystal' },
  { 'amadeus/vim-mjml' },
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
  {
    'f-person/auto-dark-mode.nvim',
    lazy = false,
    dependencies = {
      'lunacookies/vim-colors-xcode',
    },
    opts = {
      set_dark_mode = function()
        vim.cmd 'colorscheme xcodedarkhc'
        -- vim.api.nvim_set_option_value('background', 'dark', {})
      end,
      set_light_mode = function()
        vim.cmd 'colorscheme xcodelighthc'
        -- vim.api.nvim_set_option_value('background', 'light', {})
      end,
      update_interval = 3000,
      fallback = 'dark',
    },
  },
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
  {
    'tpope/vim-fugitive',
    keys = {
      { '<leader>gs', '<cmd>tab Git<CR>', desc = 'Git Status' },
      { '<leader>gb', '<cmd>Git blame<CR>', desc = 'Git Blame' },
      { '<leader>gl', '<cmd>botright vertical Git log<CR>', desc = 'Git Log' },
      { '<leader>gP', '<cmd>Git push<CR>', desc = 'Git Push' },
      { '<leader>gp', '<cmd>Git pull<CR>', desc = 'Git Pull' },
      { '<leader>gc', '<cmd>botright vertical Git commit<CR>', desc = 'Git Commit' },
      { '<leader>gC', '<cmd>botright vertical Git commit --amend<CR>', desc = 'Git Commit Amend' },
      { '<leader>ga', '<cmd>Git add %<CR>', desc = 'Git Add Current File' },
      { '<leader>gA', '<cmd>Git add .<CR>', desc = 'Git Add All' },
    },
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'fugitive', 'git' },
        callback = function(event)
          vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = event.buf, desc = 'Close fugitive window' })
        end,
      })
    end,
  },
  { 'akinsho/git-conflict.nvim', version = '*', config = true },
  {
    'sindrets/diffview.nvim',
    lazy = false,
    opts = {
      use_icons = vim.g.have_nerd_font,
      view = {
        default = {
          winbar_info = true,
        },
        file_history = {
          layout = 'diff2_vertical',
        },
        merge_tool = {
          layout = 'diff3_mixed',
        },
      },
    },
    keys = {
      { '<C-g>', '<cmd>DiffviewOpen<CR>', desc = 'Open DiffView' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = 'File Diff View History' },
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
    'justinmk/vim-sneak',
    keys = {
      { 'f', '<Plug>Sneak_s', desc = 'Jump to any location specified by two charakters' },
      { 'F', '<Plug>Sneak_S', desc = 'Jump to any location specified by two characters (reverse)' },
    },
  },
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
}
