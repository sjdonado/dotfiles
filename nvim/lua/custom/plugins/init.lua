return {
  { 'wsdjeg/vim-fetch' },
  { 'vim-crystal/vim-crystal' },
  { 'amadeus/vim-mjml' },
  {
    'folke/zen-mode.nvim',
    opts = {
      window = {
        width = 1,
      },
      on_open = function()
        vim.g.zen_mode_active = true
      end,
      on_close = function()
        vim.g.zen_mode_active = false
      end,
    },
    keys = {
      { '<C-w>z', '<cmd>ZenMode<CR>', desc = 'Toggle [Z]en Mode' },
    },
  },
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
    'catgoose/nvim-colorizer.lua',
    event = 'BufReadPre',
    opts = {
      filetypes = { '*', '!vim' },
    },
  },
}
