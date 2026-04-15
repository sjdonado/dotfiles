return {
  {
    'hinell/lsp-timeout.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    event = 'LspAttach',
    init = function()
      vim.g.lspTimeoutConfig = {
        stopTimeout = 1000 * 60 * 1, -- 1 min idle → stop servers
        startTimeout = 1000 * 10, -- 10 sec after focus → restart
        silent = true,
      }
    end,
  },
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
    'f-person/auto-dark-mode.nvim',
    priority = 1000,
    opts = {
      update_interval = 300,
      set_dark_mode = function()
        vim.cmd.colorscheme 'sjdonado_dark'
      end,
      set_light_mode = function()
        vim.cmd.colorscheme 'sjdonado_light'
      end,
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
    'norcalli/nvim-colorizer.lua',
    opts = {
      '*',
      '!vim',
    },
  },
}
