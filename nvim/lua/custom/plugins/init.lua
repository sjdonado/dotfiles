return {
  { 'vim-crystal/vim-crystal' },
  { 'amadeus/vim-mjml' },
  { 'wsdjeg/vim-fetch' },
  {
    'chrisgrieser/nvim-various-textobjs',
    event = 'VeryLazy',
    opts = {
      keymaps = {
        useDefaults = true,
      },
    },
  },
  {
    'f-person/auto-dark-mode.nvim',
    dependencies = {
      'projekt0n/github-nvim-theme',
    },
    lazy = false,
    opts = {
      set_dark_mode = function()
        vim.cmd.colorscheme 'github_dark_default'
      end,
      set_light_mode = function()
        vim.cmd.colorscheme 'github_light_default'
      end,
      update_interval = 500,
    },
  },
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    'rmagatti/auto-session',
    lazy = false,
    opts = {
      auto_session_suppress_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
    },
    keys = {
      -- Will use Telescope if installed or a vim.ui.select picker otherwise
      { '<leader>wr', '<cmd>AutoSession search<CR>', desc = 'Session search' },
      { '<leader>ws', '<cmd>AutoSession save<CR>', desc = 'Save session' },
      { '<leader>wa', '<cmd>AutoSession toggle<CR>', desc = 'Toggle autosave' },
    },
  },
  {
    'arnamak/stay-centered.nvim',
    lazy = false,
    opts = {
      enabled = true,
      allow_scroll_move = false,
    },
  },
  {
    'tpope/vim-fugitive',
    lazy = false,
    keys = {
      { '<leader>gc', '<cmd>botright vertical Git commit<CR>', desc = 'Git Commit' },
      { '<leader>gC', '<cmd>botright vertical Git commit --amend<CR>', desc = 'Git Commit Amend' },
    },
  },
  { 'akinsho/git-conflict.nvim', version = '*', config = true },
  {
    'sindrets/diffview.nvim',
    lazy = true,
    opts = {
      use_icons = vim.g.have_nerd_font,
      view = {
        default = {
          winbar_info = true,
        },
        merge_tool = {
          layout = 'diff3_mixed',
        },
      },
    },
    keys = {
      { '<leader>gs', '<cmd>DiffviewOpen<CR>', desc = 'Open DiffView with Git Status' },
      { '<leader>gl', '<cmd>DiffviewFileHistory <CR>', desc = 'Open DiffView with Git Log' },
      { '<leader>gf', '<cmd>DiffviewFileHistory %<CR>', desc = 'Open DiffView with Git File History' },
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
    lazy = true,
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
    'linw1995/nvim-mcp',
    build = 'cargo install --path .',
    opts = {},
  },
}
