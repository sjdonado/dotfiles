return {
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
    'nvim-treesitter/nvim-treesitter-context',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      enable = true,
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
  {
    'wsdjeg/vim-fetch',
  },
  {
    'vim-crystal/vim-crystal',
  },
  -- {
  --   'ThePrimeagen/harpoon',
  --   branch = 'harpoon2',
  --   dependencies = { 'nvim-lua/plenary.nvim' },
  --   config = function()
  --     local harpoon = require 'harpoon'
  --     harpoon:setup()
  --
  --     vim.keymap.set('n', '<leader>a', function()
  --       harpoon:list():add()
  --     end, { noremap = false, desc = 'Harpoon: Append file to list' })
  --     vim.keymap.set('n', '<leader><tab>', function()
  --       harpoon.ui:toggle_quick_menu(harpoon:list())
  --     end, { noremap = false, desc = 'Harpoon: Toggle quick menu' })
  --   end,
  -- },
  {
    'norcalli/nvim-colorizer.lua',
    opts = {
      '*',
      '!vim',
    },
  },
  { 'akinsho/git-conflict.nvim', version = '*', config = true },
  {
    'zbirenbaum/copilot.lua',
    dependencies = {
      'hrsh7th/nvim-cmp',
    },
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        panel = {
          layout = {
            position = 'right',
          },
        },
        suggestion = {
          auto_trigger = false,
          keymap = {
            accept = '<Tab>',
          },
        },
      }
    end,
    keys = {
      {
        '<C-g>',
        function()
          require('cmp').close()
          require('copilot.suggestion').next()
        end,
        desc = 'Trigger [G]ithub Copilot suggestion',
        mode = { 'i', 's' },
      },
    },
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'canary',
    dependencies = {
      { 'zbirenbaum/copilot.lua' },
      { 'nvim-lua/plenary.nvim' },
    },
    build = 'make tiktoken',
    opts = {
      debug = true, -- Enable debugging
      window = {
        layout = 'float',
        height = 0.9,
      },
    },
    keys = {
      {
        '<leader>gg',
        function()
          require('CopilotChat').toggle {}
        end,
        desc = '[G]ithub Copilot - To[G]gle chat',
        mode = { 'n', 'v' },
      },
      -- {
      --   '<leader>ce',
      --   function()
      --     require('CopilotChat').open(require('CopilotChat').prompts().Explain)
      --   end,
      --   desc = 'CopilotChat - Explain chat',
      --   mode = { 'n', 'v' },
      -- },
      -- {
      --   '<leader>cr',
      --   function()
      --     require('CopilotChat').open(require('CopilotChat').prompts().Review)
      --   end,
      --   desc = 'CopilotChat - Review chat',
      --   mode = { 'n', 'v' },
      -- },
      {
        '<leader>gq',
        function()
          local input = vim.fn.input 'Quick Chat: '
          if input ~= '' then
            require('CopilotChat').ask(input, { selection = require('CopilotChat.select').visual })
          end
        end,
        desc = '[G]ithub Copilot - [Q]uick chat',
        mode = { 'n', 'v' },
      },
    },
  },
}
