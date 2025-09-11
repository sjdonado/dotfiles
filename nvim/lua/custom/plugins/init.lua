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
    keys = {
      -- Will use Telescope if installed or a vim.ui.select picker otherwise
      { "<leader>wr", "<cmd>AutoSession search<CR>", desc = "Session search" },
      { "<leader>ws", "<cmd>AutoSession save<CR>",   desc = "Save session" },
      { "<leader>wa", "<cmd>AutoSession toggle<CR>", desc = "Toggle autosave" },
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
    keys = {
      { '<leader>gc', '<cmd>botright vertical Git commit<CR>',         desc = 'Git Commit' },
      { '<leader>gC', '<cmd>botright vertical Git commit --amend<CR>', desc = 'Git Commit Amend' },
    },
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
        merge_tool = {
          layout = 'diff3_mixed',
        },
      },
    },
    keys = {
      { '<leader>tg', '<cmd>DiffviewOpen<CR>',          desc = 'Open DiffView' },
      { '<leader>hf', '<cmd>DiffviewFileHistory %<CR>', desc = 'File Diff View History' },
      { '<leader>hd', '<cmd>DiffviewFileHistory .<CR>', desc = 'Dir Diff View History' },
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
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    keys = {
      { "<C-\\>",     "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        mode = "v",                  desc = "Send to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
      },
      -- Diff management
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
    },
    opts = {
      terminal = {
        snacks_win_opts = {
          position = "right",
          keys = {
            claude_hide = {
              "<C-\\>",
              function(self)
                self:hide()
              end,
              mode = "t",
              desc = "Hide",
            },
            claude_unfocus = {
              "<C-h>",
              function(self)
                vim.cmd("wincmd h")
              end,
              mode = "t",
              desc = "Move to left panel",
            },
            claude_scroll = {
              "<C-n>",
              function(self)
                vim.cmd("stopinsert")
              end,
              mode = "t",
              desc = "Enter scroll mode",
            },
            claude_insert = {
              "<C-n>",
              function(self)
                vim.cmd("startinsert")
              end,
              mode = "n",
              desc = "Return to insert mode",
            },
          },
        },
      },
    },
  }
}
