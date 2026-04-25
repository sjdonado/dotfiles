-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

-- Enable mouse mode
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Set tab width to 2 spaces visually
vim.opt.tabstop = 2 -- Width of a tab character
vim.opt.shiftwidth = 2 -- Width for autoindent
vim.opt.softtabstop = 2 -- Width when hitting tab key

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Always show tabline
vim.opt.showtabline = 2

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.opt.confirm = true

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<C-e>', '4j', { desc = 'Scroll down 4 lines' })
vim.keymap.set('n', '<C-y>', '4k', { desc = 'Scroll up 4 lines' })

for _, mode in ipairs { 'n', 'i', 'v', 'x', 's', 'o', 'c', 't' } do
  vim.keymap.set(mode, '<ScrollWheelLeft>', '<Nop>', {})
  vim.keymap.set(mode, '<ScrollWheelRight>', '<Nop>', {})
end

-- Map Ctrl+S to save (which tmux will send when Cmd+S is pressed)
vim.keymap.set('n', '<C-s>', ':w<CR>', { silent = true, desc = 'Save file' })
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>a', { silent = true, desc = 'Save file in insert mode' })

-- Recommended by rmagatti/auto-session
vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- [[ Custom settings ]]
vim.opt.foldmethod = 'manual'
-- Unified statusbar
vim.opt.laststatus = 3

-- Disable Netrw on Startup
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable 24-bit colour
vim.opt.termguicolors = true

-- [[ Custom Keymaps ]]
vim.keymap.set('n', '<Leader>tc', function() require('mini.bufremove').delete() end, { desc = '[T]ab [C]lose buffer' })
vim.keymap.set('n', '<Leader>tn', '<cmd>enew<CR>', { desc = '[T]ab [N]ew buffer' })
vim.keymap.set('n', 'gt', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', 'gT', '<cmd>bprev<CR>', { desc = 'Previous buffer' })

require('lazy').setup({
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically (not required if .editorconfig)

  -- See `:help gitsigns` to understand what the configuration keys do
  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      -- this setting is independent of vim.opt.timeoutlen
      delay = 0,
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>g', group = '[G]it' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      --  :Telescope help_tags

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        defaults = vim.tbl_extend('force', require('telescope.themes').get_dropdown(), {
          mappings = {
            i = {
              ['<esc>'] = require('telescope.actions').close,
              ['<C-y>'] = require('telescope.actions').preview_scrolling_up,
              ['<C-e>'] = require('telescope.actions').preview_scrolling_down,
              ['<C-t>'] = require('telescope.actions').delete_buffer,
              ['<C-q>'] = require('telescope.actions').send_to_qflist + require('telescope.actions').open_qflist,
            },
          },
          layout_config = {
            height = 0.2,
            width = function(_, max_columns, _)
              return math.min(max_columns, 110)
            end,
          },
          file_ignore_patterns = { '.git/', 'node_modules/', 'build/', 'dist/', '*.min' },
        }),

        pickers = {
          find_files = {
            hidden = true,
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })

      vim.keymap.set('n', '<leader>p', function()
        builtin.find_files {
          hidden = true, -- Search hidden files (respects .gitignore)
        }
      end, { desc = '[S]earch [F]iles' })

      vim.keymap.set('n', 'g/', function()
        builtin.live_grep {
          additional_args = { '--fixed-strings' },
        }
      end, { desc = '[S]earch by [G]rep' })

      vim.keymap.set('v', 'g/', function()
        builtin.grep_string {
          additional_args = { '--hidden', '--fixed-strings' },
        }
      end, { desc = '[S]earch current [W]ord' })

      vim.keymap.set('n', '<leader>sa', function()
        local exclude = {
          'node_modules',
          'dist',
          '.astro',
          '.svelte-kit',
          '*.min.*',
          '*lock.*',
        }

        local args = { '--hidden', '-u', '--fixed-strings' }
        for _, pat in ipairs(exclude) do
          table.insert(args, '--glob')
          table.insert(args, '!' .. pat)
        end

        builtin.live_grep { additional_args = args }
      end, { desc = '[S]earch [All] by Grep' })

      vim.keymap.set('n', '<leader>sg', function()
        builtin.grep_string {
          search = vim.fn.input 'Grep For > ',
          use_regex = true,
          additional_args = { '--hidden' },
        }
      end, { desc = '[S]earch by [E]xpand Grep' })

      -- vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>ss', builtin.resume, { desc = '[S]earch Resume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      -- vim.keymap.set('n', '<leader>s/', function()
      --   builtin.live_grep {
      --     grep_open_files = true,
      --     prompt_title = 'Live Grep in Open Files',
      --   }
      -- end, { desc = '[S]earch [/] in Open Files' })
    end,
  },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Buffer tabline (VSCode-like tabs)
      require('mini.tabline').setup()

      -- Clean buffer removal without breaking layout
      require('mini.bufremove').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        local line = vim.fn.line '.'
        local col = vim.fn.col '.'
        local zen_indicator = vim.g.zen_mode_active and ' Z' or ''
        return line .. ':' .. col .. zen_indicator
      end

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },

  { -- Syntax highlighting via treesitter
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = 'all',
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
      ignore_install = { 'haskell', 'ipkg' },
    },
  },
  require 'kickstart.plugins.indent_line',
  require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.nvim-tree',
  require 'kickstart.plugins.git',

  { import = 'custom.plugins' },
}, {
  ui = {
    -- default lazy.nvim defined Nerd Font icons
    icons = {},
  },
})

require 'custom.commands'

vim.cmd.colorscheme 'sjdonado_dark'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
