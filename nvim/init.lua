-- ============================================================
-- SECTION 1: FOUNDATION
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ============================================================
do
  vim.loader.enable()

  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  vim.g.have_nerd_font = true

  vim.o.number = true
  vim.o.relativenumber = true
  vim.o.mouse = 'a'
  vim.o.showmode = false

  vim.schedule(function()
    vim.o.clipboard = 'unnamedplus'
    -- Over SSH (e.g. herdr on a remote box) there is no local clipboard tool,
    -- so route yank/paste through OSC52 to reach the attaching terminal.
    if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
      local osc52 = require 'vim.ui.clipboard.osc52'
      vim.g.clipboard = {
        name = 'OSC 52',
        copy = { ['+'] = osc52.copy '+', ['*'] = osc52.copy '*' },
        paste = { ['+'] = osc52.paste '+', ['*'] = osc52.paste '*' },
      }
    end
  end)

  vim.o.tabstop = 2
  vim.o.shiftwidth = 2
  vim.o.softtabstop = 2

  vim.o.breakindent = true
  vim.o.undofile = true
  vim.o.autoread = true
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.signcolumn = 'yes'
  vim.o.updatetime = 250
  vim.o.timeoutlen = 300
  vim.o.splitright = true
  vim.o.splitbelow = true
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
  vim.o.inccommand = 'split'
  vim.o.cursorline = true
  vim.o.scrolloff = 0
  vim.o.showtabline = 2
  vim.o.confirm = true
  vim.o.termguicolors = true
  vim.o.foldmethod = 'manual'
  vim.o.laststatus = 3
  vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'

  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },
    virtual_text = true,
    virtual_lines = false,
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false }
      end,
    },
  }

  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- Scroll viewport without moving the cursor (until scrolloff pushes it).
  vim.keymap.set('n', '<C-e>', '4<C-e>', { desc = 'Scroll down 4 lines' })
  vim.keymap.set('n', '<C-y>', '4<C-y>', { desc = 'Scroll up 4 lines' })

  for _, mode in ipairs { 'n', 'i', 'v', 'x', 's', 'o', 'c', 't' } do
    vim.keymap.set(mode, '<ScrollWheelLeft>', '<Nop>', {})
    vim.keymap.set(mode, '<ScrollWheelRight>', '<Nop>', {})
  end

  vim.keymap.set('n', '<C-s>', ':w<CR>', { silent = true, desc = 'Save file' })
  vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>a', { silent = true, desc = 'Save file in insert mode' })

  vim.keymap.set('n', '<Leader>tc', function()
    require('mini.bufremove').delete()
  end, { desc = '[T]ab [C]lose buffer' })
  vim.keymap.set('n', '<Leader>tn', '<cmd>enew<CR>', { desc = '[T]ab [N]ew buffer' })
  vim.keymap.set('n', 'gt', '<cmd>bnext<CR>', { desc = 'Next buffer' })
  vim.keymap.set('n', 'gT', '<cmd>bprev<CR>', { desc = 'Previous buffer' })

  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
      local hl_op = vim.hl.hl_op or vim.hl.on_yank
      hl_op()
    end,
  })

  vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('kickstart-custom-auto-resize', { clear = true }),
    callback = function()
      vim.cmd 'tabdo wincmd ='
    end,
  })

  vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
    desc = 'Reload files changed outside Neovim',
    group = vim.api.nvim_create_augroup('kickstart-checktime', { clear = true }),
    command = 'checktime',
  })
end

if not vim.pack then
  vim.notify(
    'This config requires Neovim >= 0.12 for vim.pack (currently '
      .. tostring(vim.version()) .. '). Run linux.sh --install (Linux) or the '
      .. 'macOS setup to fetch a current Neovim; skipping plugin setup.',
    vim.log.levels.ERROR
  )
  return
end

-- ============================================================
-- SECTION 2: PLUGIN MANAGER (vim.pack) BUILD HOOKS
-- ============================================================

-- vim.pack ships no user commands, so updating means typing
-- `:lua vim.pack.update()`. These are the two verbs lazy.nvim's `:Lazy` covered.
-- :PackUpdate opens the confirmation buffer (`:w` applies, `:q` denies, `]]`
-- and `[[` walk the plugin sections, `K` explains the change under the cursor);
-- with a bang it applies everything unattended. Args narrow it to named
-- plugins, completed from what is installed.
local function installed_names()
  return vim.tbl_map(function(p)
    return p.spec.name
  end, vim.pack.get())
end

vim.api.nvim_create_user_command('PackUpdate', function(ev)
  local names = #ev.fargs > 0 and ev.fargs or nil
  vim.pack.update(names, { force = ev.bang })
end, {
  bang = true,
  nargs = '*',
  desc = 'Update vim.pack plugins (! applies without confirmation)',
  complete = function(arg)
    return vim.tbl_filter(function(name)
      return vim.startswith(name, arg)
    end, installed_names())
  end,
})

vim.api.nvim_create_user_command('PackList', function()
  local lines = vim.tbl_map(function(p)
    return ('%-32s %s'):format(p.spec.name, (p.rev or ''):sub(1, 12))
  end, vim.pack.get())
  table.sort(lines)
  vim.notify(table.concat(lines, '\n'))
end, { desc = 'List installed vim.pack plugins and their revisions' })

do
  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then
        output = 'No output from build command.'
      end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then
        return
      end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then
          vim.cmd.packadd 'nvim-treesitter'
        end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

---@param repo string
---@return string
local function gh(repo)
  return 'https://github.com/' .. repo
end

-- ============================================================
-- SECTION 3: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini (+icons)
-- ============================================================
do
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    delay = 0,
    icons = {
      mappings = vim.g.have_nerd_font,
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
        Space = '<Space> ',
        Tab = '<Tab> ',
        BS = '<BS> ',
      },
    },
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>g', group = '[G]it' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      { '<leader>f', group = '[F]ormat' },
      { '<leader>w', group = '[W]orkspace/Session' },
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
    },
  }

  -- [[ Colorscheme ]]
  vim.pack.add { gh 'lunacookies/vim-colors-xcode' }

  -- Herdr reports its resolved pane background over OSC 11 and updates
  -- &background when the host appearance changes. Outside Herdr this remains
  -- the terminal's own resolved background.
  local function apply_xcode()
    pcall(vim.cmd.colorscheme, vim.o.background == 'light' and 'xcodelight' or 'xcodedark')
  end
  local xcode_theme = vim.api.nvim_create_augroup('xcode-theme', { clear = true })
  apply_xcode()
  vim.api.nvim_create_autocmd('TermResponse', {
    group = xcode_theme,
    callback = function(ev)
      local red, green, blue = ev.data.sequence:match('^\027%]11;rgb:(%x+)/(%x+)/(%x+)$')
      if not red then return end
      local function channel(value)
        return tonumber(value, 16) / (16 ^ #value - 1)
      end
      local luminance = 0.299 * channel(red) + 0.587 * channel(green) + 0.114 * channel(blue)
      vim.o.background = luminance < 0.5 and 'dark' or 'light'
      apply_xcode()
    end,
  })

  -- &background is otherwise resolved once, at startup, so a window opened while
  -- the pane was light stayed light after Herdr switched to dark: nothing re-asks.
  -- Re-issue the OSC 11 query on focus and let the handler above do the rest.
  -- Written to stderr rather than stdout so it does not interleave with the TUI's
  -- own output stream; both reach the terminal.
  local function query_background()
    pcall(vim.api.nvim_chan_send, vim.v.stderr, '\27]11;?\7')
  end
  vim.api.nvim_create_autocmd('FocusGained', { group = xcode_theme, callback = query_background })
  vim.api.nvim_create_user_command('ThemeSync', query_background, { desc = 'Re-query the terminal background' })

  -- Highlight TODO/NOTE/etc. in comments
  vim.pack.add { gh 'folke/todo-comments.nvim', gh 'nvim-lua/plenary.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  -- Icon provider (replaces nvim-web-devicons); mock so consumers
  -- (nvim-tree, telescope, ...) that require 'nvim-web-devicons' still work.
  require('mini.icons').setup()
  MiniIcons.mock_nvim_web_devicons()

  require('mini.ai').setup {
    mappings = { around_next = 'aa', inside_next = 'ii' },
    n_lines = 500,
  }
  require('mini.surround').setup()
  require('mini.tabline').setup()
  require('mini.bufremove').setup()

  local statusline = require 'mini.statusline'
  statusline.setup { use_icons = vim.g.have_nerd_font }
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function()
    local line = vim.fn.line '.'
    local col = vim.fn.col '.'
    local zen_indicator = vim.g.zen_mode_active and ' Z' or ''
    return line .. ':' .. col .. zen_indicator
  end

  -- Indent guides
  vim.pack.add { gh 'lukas-reineke/indent-blankline.nvim' }
  require('ibl').setup {
    indent = { char = '│', tab_char = '│' },
    scope = { show_start = false, show_end = false },
  }

  -- Per-buffer opt-outs for a file too big to be worth decorating. Indent guides
  -- are drawn per visible line and the scope lookup walks the buffer; treesitter
  -- highlighting starts on its own for the parsers Neovim bundles, so Section 9's
  -- guard is not enough to keep a parse off a 5MB Lua dump. Scheduled because this
  -- has to run after whichever FileType handler started them.
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('kickstart-bigfile', { clear = true }),
    callback = function(args)
      if not require('custom.bigfile').is_big(args.buf) then
        return
      end
      vim.schedule(function()
        pcall(vim.treesitter.stop, args.buf)
        pcall(require('ibl').setup_buffer, args.buf, { enabled = false })
      end)
    end,
  })

  -- Autopairs
  vim.pack.add { gh 'windwp/nvim-autopairs' }
  require('nvim-autopairs').setup {}

  -- Zen mode
  -- Configured on the first toggle rather than at startup: nothing about zen mode
  -- is observable until the key is pressed.
  vim.pack.add { gh 'folke/zen-mode.nvim' }
  vim.keymap.set('n', '<C-w>z', function()
    require('zen-mode').setup {
      window = { width = 1 },
      on_open = function()
        vim.g.zen_mode_active = true
      end,
      on_close = function()
        vim.g.zen_mode_active = false
      end,
    }
    require('zen-mode').toggle()
  end, { desc = 'Toggle [Z]en Mode' })

  -- Various text objects
  vim.pack.add { gh 'chrisgrieser/nvim-various-textobjs' }
  require('various-textobjs').setup { keymaps = { useDefaults = true } }

  -- Auto session
  vim.pack.add { gh 'rmagatti/auto-session' }
  require('auto-session').setup()
  vim.keymap.set('n', '<leader>wr', '<cmd>AutoSession search<CR>', { desc = 'Session search' })
  vim.keymap.set('n', '<leader>ws', '<cmd>AutoSession save<CR>', { desc = 'Save session' })
  vim.keymap.set('n', '<leader>wa', '<cmd>AutoSession toggle<CR>', { desc = 'Toggle autosave' })

  -- Filetype-only plugins
  vim.pack.add {
    gh 'wsdjeg/vim-fetch',
    gh 'vim-crystal/vim-crystal',
    gh 'amadeus/vim-mjml',
  }
end

-- ============================================================
-- SECTION 4: SEARCH & NAVIGATION (Telescope) + nvim-tree
-- ============================================================
do
  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then
    table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim')
  end
  vim.pack.add(telescope_plugins)

  -- Telescope, plenary and the two extensions are the heaviest require in this
  -- config (~8ms) and none of it is observable until a picker opens, so setup runs
  -- on first use. Every entry point below reaches load(), which is idempotent: the
  -- keymaps, the LSP pickers and vim.ui.select.
  --
  -- Only the require is deferred, not the runtimepath entry: vim.pack.add's `load`
  -- option is already false while init.lua is sourcing, and the plugin/ files are
  -- sourced by the normal startup pass either way, so passing load = false
  -- measured identically and only added packadd calls.
  local telescope_loaded = false
  local function load()
    if telescope_loaded then
      return
    end
    telescope_loaded = true
    local actions = require 'telescope.actions'
    local themes = require 'telescope.themes'
    require('telescope').setup {
      defaults = vim.tbl_extend('force', themes.get_dropdown(), {
        mappings = {
          i = {
            ['<esc>'] = actions.close,
            ['<C-y>'] = actions.preview_scrolling_up,
            ['<C-e>'] = actions.preview_scrolling_down,
            ['<C-t>'] = actions.delete_buffer,
            ['<C-q>'] = actions.send_to_qflist + actions.open_qflist,
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
        find_files = { hidden = true },
      },
      extensions = {
        ['ui-select'] = { themes.get_dropdown() },
      },
    }

    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')
  end

  -- Stands in for telescope.builtin: indexing it loads telescope and forwards to
  -- the real picker, so the call sites below read as they did when the module was
  -- required at startup.
  local builtin = setmetatable({}, {
    __index = function(_, key)
      return function(...)
        load()
        return require('telescope.builtin')[key](...)
      end
    end,
  })

  -- The ui-select extension replaces vim.ui.select when it loads, which is now
  -- later than the first code action might arrive. Route through load() and then
  -- call whatever is installed, falling back to the native picker if the
  -- extension failed to load at all.
  local native_select = vim.ui.select
  local lazy_select
  lazy_select = function(...)
    load()
    local impl = vim.ui.select
    if impl == lazy_select then
      impl = native_select
    end
    return impl(...)
  end
  vim.ui.select = lazy_select

  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>p', function()
    builtin.find_files { hidden = true }
  end, { desc = '[S]earch Files' })
  vim.keymap.set('n', 'g/', function()
    builtin.live_grep { additional_args = { '--fixed-strings' } }
  end, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('v', 'g/', function()
    builtin.grep_string { additional_args = { '--hidden', '--fixed-strings' } }
  end, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sa', function()
    local exclude = { 'node_modules', 'dist', '.astro', '.svelte-kit', '*.min.*', '*lock.*' }
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
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>ss', builtin.resume, { desc = '[S]earch Resume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
  vim.keymap.set('n', '<leader>/', function()
    load()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
  end, { desc = '[/] Fuzzily search in current buffer' })

  -- Telescope-based LSP pickers wired on LspAttach
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf
      vim.keymap.set('n', 'gr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
      vim.keymap.set('n', 'gi', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
      vim.keymap.set('n', 'gd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
      vim.keymap.set('n', 'gt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
    end,
  })

  -- [[ nvim-tree ]]
  -- Also first-use: the tree has no effect until it is opened, and netrw is
  -- already disabled in Section 1 rather than by the plugin.
  vim.pack.add { gh 'nvim-tree/nvim-tree.lua' }
  vim.keymap.set('n', '<leader>e', function()
    require 'kickstart.plugins.nvim-tree'
    vim.cmd 'NvimTreeFindFileToggle'
  end, { desc = 'Toggle Nvim Tree' })
end

-- ============================================================
-- SECTION 5: GIT (gitsigns, git-conflict, blame)
-- ============================================================
do
  vim.pack.add {
    gh 'lewis6991/gitsigns.nvim',
    gh 'akinsho/git-conflict.nvim',
  }
  require 'kickstart.plugins.git'
end

-- ============================================================
-- SECTION 6: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  vim.pack.add {
    gh 'j-hui/fidget.nvim',
    gh 'folke/lazydev.nvim',
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  -- fidget renders LSP progress, and no progress can arrive before a client
  -- attaches, so it loads on the first attach instead of at startup.
  vim.api.nvim_create_autocmd('LspAttach', {
    once = true,
    group = vim.api.nvim_create_augroup('kickstart-fidget-lazy', { clear = true }),
    callback = function()
      require('fidget').setup {}
    end,
  })
  require('lazydev').setup {}

  -- Servers advertise file watching by default and then register watchers across
  -- the whole workspace, which is the documented CPU sink on large trees
  -- (neovim/neovim#23291). Dropping the capability leaves a server reading the
  -- editor's own didChange notifications. The cost is that edits made outside nvim
  -- go unnoticed until :LspRestart, which is cheap here: a branch switch means a
  -- new worktree directory and a new nvim.
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.workspace.didChangeWatchedFiles = nil
  vim.lsp.config('*', { capabilities = capabilities })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
      map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
      map('K', vim.lsp.buf.hover, 'Hover Documentation')
      map('<leader>K', vim.lsp.buf.signature_help, 'Display signature')

      local client = vim.lsp.get_client_by_id(event.data.client_id)

      -- Nothing a server computes is worth the wait on a minified bundle or a
      -- dumped fixture, so detach instead of indexing it.
      if client and require('custom.bigfile').is_big(event.buf) then
        vim.schedule(function()
          vim.lsp.buf_detach_client(event.buf, client.id)
        end)
        return
      end

      -- Treesitter already colours these buffers, so semantic tokens buy a second
      -- opinion on the same text at the price of a request and a redraw per
      -- change. Only the two servers that send them for every token are turned
      -- off; the rest keep theirs, where they mark what a parser cannot know.
      if client and (client.name == 'vtsls' or client.name == 'eslint') then
        client.server_capabilities.semanticTokensProvider = nil
      end

      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })
        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
        end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  ---@type table<string, vim.lsp.Config & { package?: string }>
  local servers = {
    astro = { package = 'astro-language-server' },
    basedpyright = { package = 'basedpyright' },
    clangd = { package = 'clangd' },
    crystalline = { package = 'crystalline' },
    cssls = { package = 'css-lsp' },
    eslint = { package = 'eslint-lsp' },
    gopls = { package = 'gopls' },
    golangci_lint_ls = { package = 'golangci-lint-langserver' },
    jsonls = { package = 'json-lsp' },
    lua_ls = {
      package = 'lua-language-server',
      settings = {
        Lua = {
          completion = { callSnippet = 'Replace' },
          format = { enable = false },
        },
      },
    },
    svelte = { package = 'svelte-language-server' },
    tailwindcss = { package = 'tailwindcss-language-server' },
    vtsls = {
      package = 'vtsls',
      settings = {
        vtsls = {
          enableMoveToFileCodeAction = true,
          autoUseWorkspaceTsdk = true,
        },
        typescript = {
          tsserver = { maxTsServerMemory = 4096 },
          updateImportsOnFileMove = { enabled = 'always' },
          suggest = { completeFunctionCalls = true },
          inlayHints = {
            parameterNames = { enabled = 'none' },
            propertyDeclarationTypes = { enabled = false },
            variableTypes = { enabled = false },
          },
        },
      },
    },
    yamlls = { package = 'yaml-language-server' },
  }

  require('mason').setup {}

  local ensure_installed = {}
  for _, server in pairs(servers) do
    if server.package then
      table.insert(ensure_installed, server.package)
    end
  end
  vim.list_extend(ensure_installed, { 'black', 'gofumpt', 'goimports', 'isort', 'prettierd', 'ruff', 'stylua' })
  table.sort(ensure_installed)

  -- mason-tool-installer requires mason-registry at module level, and the registry
  -- is the expensive half of mason: loading it diffs every package above against
  -- the GitHub source list on each launch. The tool list only changes when this
  -- file changes, so the whole thing waits behind a command.
  --
  -- mason-lspconfig is deliberately absent. Its jobs are mapping mason package
  -- names to server names, which the `package` fields above already do by hand,
  -- and enabling installed servers automatically, which the vim.lsp.enable loop
  -- below does explicitly. Keeping it would only pull the registry back into
  -- startup. Servers still resolve because mason.setup puts its bin directory on
  -- PATH.
  vim.api.nvim_create_user_command('MasonToolsSync', function()
    require('mason-tool-installer').setup { ensure_installed = ensure_installed, run_on_start = false }
    vim.cmd 'MasonToolsInstall'
  end, { desc = 'Install every Mason tool this config declares' })

  for name, server in pairs(servers) do
    server.package = nil
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 7: FORMATTING (conform.nvim) + ordered LSP fixers on save
-- Order: LSP code actions (eslint --fix / organize-imports) -> formatter.
-- Prettier always runs last so its style wins any eslint formatting
-- conflicts even in projects without eslint-config-prettier.
-- ============================================================
do
  vim.pack.add { gh 'stevearc/conform.nvim' }

  require('conform').setup {
    notify_on_error = false,
    default_format_opts = { lsp_format = 'fallback' },
    formatters_by_ft = {
      go = { 'goimports', 'gofumpt' },
      lua = { 'stylua' },
      python = { 'isort', 'black' },
      astro = { 'prettierd' },
      css = { 'prettierd' },
      html = { 'prettierd' },
      javascript = { 'prettierd' },
      javascriptreact = { 'prettierd' },
      json = { 'prettierd' },
      jsonc = { 'prettierd' },
      markdown = { 'prettierd' },
      svelte = { 'prettierd' },
      typescript = { 'prettierd' },
      typescriptreact = { 'prettierd' },
      yaml = { 'prettierd' },
    },
  }

  -- Filetypes that get format-on-save.
  local format_filetypes = {
    astro = true,
    css = true,
    go = true,
    html = true,
    javascript = true,
    javascriptreact = true,
    json = true,
    jsonc = true,
    lua = true,
    markdown = true,
    python = true,
    svelte = true,
    typescript = true,
    typescriptreact = true,
    yaml = true,
  }

  -- LSP code-action kinds to apply before the formatter runs.
  local action_kinds_by_ft = {
    astro = { 'source.fixAll.eslint' },
    go = { 'source.organizeImports' },
    javascript = { 'source.fixAll.eslint' },
    javascriptreact = { 'source.fixAll.eslint' },
    svelte = { 'source.fixAll.eslint' },
    typescript = { 'source.fixAll.eslint' },
    typescriptreact = { 'source.fixAll.eslint' },
  }

  -- Synchronously request + apply code actions of the given kinds.
  -- buf_request_sync blocks the editor; safe inside BufWritePre.
  local function apply_lsp_actions(bufnr, kinds)
    local clients = vim.lsp.get_clients { bufnr = bufnr, method = 'textDocument/codeAction' }
    if #clients == 0 then
      return
    end
    local encoding = clients[1].offset_encoding or 'utf-8'
    local params = vim.lsp.util.make_range_params(0, encoding)
    params.context = { only = kinds, diagnostics = vim.diagnostic.get(bufnr) }
    local results = vim.lsp.buf_request_sync(bufnr, 'textDocument/codeAction', params, 2000) or {}
    for client_id, resp in pairs(results) do
      for _, action in pairs(resp.result or {}) do
        if action.edit then
          local client = vim.lsp.get_client_by_id(client_id)
          vim.lsp.util.apply_workspace_edit(action.edit, client and client.offset_encoding or 'utf-8')
        end
        if type(action.command) == 'table' then
          vim.lsp.buf.execute_command(action.command)
        end
      end
    end
  end

  vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('format-on-save', { clear = true }),
    callback = function(args)
      if vim.g.disable_format_on_save or vim.b[args.buf].disable_format_on_save then
        return
      end
      local ft = vim.bo[args.buf].filetype
      if not format_filetypes[ft] then
        return
      end
      local kinds = action_kinds_by_ft[ft]
      if kinds then
        apply_lsp_actions(args.buf, kinds)
      end
      require('conform').format { bufnr = args.buf, timeout_ms = 2000, lsp_format = 'fallback' }
    end,
  })

  vim.keymap.set({ 'n', 'v' }, '<leader>ff', function()
    require('conform').format { async = true, lsp_format = 'fallback' }
  end, { desc = '[F]ormat buffer' })
  vim.keymap.set('n', '<leader>tf', function()
    vim.b.disable_format_on_save = not vim.b.disable_format_on_save
    vim.notify('Format-on-save (buffer): ' .. (vim.b.disable_format_on_save and 'OFF' or 'ON'))
  end, { desc = '[T]oggle [F]ormat on save (buffer)' })
  vim.keymap.set('n', '<leader>tF', function()
    vim.g.disable_format_on_save = not vim.g.disable_format_on_save
    vim.notify('Format-on-save (global): ' .. (vim.g.disable_format_on_save and 'OFF' or 'ON'))
  end, { desc = '[T]oggle [F]ormat on save (global)' })
end

-- ============================================================
-- SECTION 8: AUTOCOMPLETE & SNIPPETS (blink.cmp)
-- ============================================================
do
  vim.pack.add {
    { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' },
  }

  require('blink.cmp').setup {
    keymap = { preset = 'enter' },
    appearance = { nerd_font_variant = 'mono' },
    completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
    sources = {
      default = { 'lsp', 'buffer', 'path', 'snippets', 'lazydev' },
      providers = {
        lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
      },
    },
    -- Native vim.snippet rather than LuaSnip: no snippet is defined anywhere in
    -- this config and no snippet collection is installed, so LuaSnip was only an
    -- expansion engine, costing ~16ms of startup, 7MB on disk and a
    -- make install_jsregexp build step for expansions nothing produces.
    snippets = { preset = 'default' },
    -- The Rust matcher, downloaded prebuilt for the pinned tag. The Lua fallback
    -- re-ranks every candidate in interpreted Lua on each keystroke, which is the
    -- slow path once the list is long.
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 9: TREESITTER
-- ============================================================
do
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    if not vim.treesitter.language.add(language) then
      return
    end
    vim.treesitter.start(buf, language)

    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil
    if has_indent_query then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      if require('custom.bigfile').is_big(buf) then
        return
      end

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then
        return
      end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        require('nvim-treesitter').install(language):await(function()
          treesitter_try_attach(buf, language)
        end)
      else
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 9b: MARKDOWN RENDERING (render-markdown.nvim)
-- ============================================================
do
  vim.pack.add { gh 'MeanderingProgrammer/render-markdown.nvim' }
  -- The default code border is `hide`, which deletes the fence rows outright on
  -- nvim 0.11+. That desynchronizes relativenumber from the file: the closing ```
  -- kept its number while occupying no row, so the gutter appeared to skip a line.
  -- `none` keeps both fences on screen without drawing a fill on them, which `thin`
  -- did: those rows then rendered as dark bars that survived a switch to the light
  -- colorscheme. `language` keeps the language label and drops the block background.
  -- language_border is the `█` run that pads the language label to full width. It
  -- is drawn as virtual text in RenderMarkdown_RenderMarkdownCodeBorder_bg_as_fg,
  -- a group the plugin derives from the border background. `:colorscheme` clears
  -- every highlight and the plugin only recreates the groups still in its cache,
  -- so after a light/dark switch that one resolves to nothing and the glyphs fall
  -- back to Normal's foreground: a solid black bar across each fence row. Empty
  -- keeps the label and draws no run.
  --
  -- Loaded on the first markdown buffer rather than at startup: it renders only
  -- markdown, and FileType has already fired for that buffer by then, so the
  -- event is re-fired once for it.
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    once = true,
    group = vim.api.nvim_create_augroup('kickstart-render-markdown-lazy', { clear = true }),
    callback = function(args)
      require('render-markdown').setup {
        completions = { lsp = { enabled = true } },
        code = { style = 'language', border = 'none', language_border = '' },
      }
      vim.api.nvim_exec_autocmds('FileType', { buffer = args.buf })
    end,
  })
end

-- ============================================================
-- SECTION 10: CUSTOM COMMANDS & FINAL TOUCHES
-- ============================================================
require 'custom.commands'

-- vim: ts=2 sts=2 sw=2 et
