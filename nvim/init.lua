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

-- ============================================================
-- SECTION 2: PLUGIN MANAGER (vim.pack) BUILD HOOKS
-- ============================================================
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

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then
          run_build(name, { 'make', 'install_jsregexp' }, ev.data.path)
        end
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
  -- TEMPFIX: force built-in dark. Revert (uncomment xcode + auto-dark-mode
  -- below) once herdr fixes gray pane-selection color.
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'default'

  -- vim.pack.add { gh 'lunacookies/vim-colors-xcode' }
  --
  -- -- Pick scheme from &background, which Neovim sets from the terminal's
  -- -- OSC 11 background-color reply (works over ssh/herdr where auto-dark-mode
  -- -- can't reach dbus/gsettings). OptionSet catches the async OSC 11 result
  -- -- and any later terminal theme change.
  -- local function apply_xcode()
  --   pcall(vim.cmd.colorscheme, vim.o.background == 'light' and 'xcodelight' or 'xcodedark')
  -- end
  -- apply_xcode()
  -- vim.api.nvim_create_autocmd('OptionSet', { pattern = 'background', callback = apply_xcode })
  --
  -- vim.pack.add { gh 'f-person/auto-dark-mode.nvim' }
  -- require('auto-dark-mode').setup {
  --   update_interval = 300,
  --   set_dark_mode = function()
  --     vim.o.background = 'dark'
  --     vim.cmd.colorscheme 'xcodedark'
  --   end,
  --   set_light_mode = function()
  --     vim.o.background = 'light'
  --     vim.cmd.colorscheme 'xcodelight'
  --   end,
  -- }
  --
  -- -- :ToggleTheme — flip light/dark from the command line.
  -- vim.api.nvim_create_user_command('ToggleTheme', function()
  --   if vim.o.background == 'dark' then
  --     vim.o.background = 'light'
  --     vim.cmd.colorscheme 'xcodelight'
  --   else
  --     vim.o.background = 'dark'
  --     vim.cmd.colorscheme 'xcodedark'
  --   end
  -- end, { desc = 'Toggle light/dark colorscheme' })

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

  -- Autopairs
  vim.pack.add { gh 'windwp/nvim-autopairs' }
  require('nvim-autopairs').setup {}

  -- Colorizer
  -- vim.pack.add { gh 'catgoose/nvim-colorizer.lua' }
  -- require('colorizer').setup { filetypes = { '*', '!vim' } }

  -- Zen mode
  vim.pack.add { gh 'folke/zen-mode.nvim' }
  require('zen-mode').setup {
    window = { width = 1 },
    on_open = function()
      vim.g.zen_mode_active = true
    end,
    on_close = function()
      vim.g.zen_mode_active = false
    end,
  }
  vim.keymap.set('n', '<C-w>z', '<cmd>ZenMode<CR>', { desc = 'Toggle [Z]en Mode' })

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
      find_files = { hidden = true },
    },
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  local builtin = require 'telescope.builtin'

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
  vim.pack.add { gh 'nvim-tree/nvim-tree.lua' }
  require 'kickstart.plugins.nvim-tree'
end

-- ============================================================
-- SECTION 5: GIT (gitsigns, git-conflict, lazygit.nvim, blame)
-- ============================================================
do
  vim.g.lazygit_floating_window_scaling_factor = 1.0
  vim.pack.add {
    gh 'lewis6991/gitsigns.nvim',
    gh 'akinsho/git-conflict.nvim',
    gh 'kdheepak/lazygit.nvim',
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
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  require('fidget').setup {}
  require('lazydev').setup {}

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

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }
  require('mason-lspconfig').setup { ensure_installed = {}, automatic_installation = false }

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
-- SECTION 8: AUTOCOMPLETE & SNIPPETS (blink.cmp + LuaSnip)
-- ============================================================
do
  vim.pack.add {
    { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' },
    { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' },
  }

  require('luasnip').setup {}

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
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'lua' },
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
  require('render-markdown').setup {
    completions = { lsp = { enabled = true } },
  }
end

-- ============================================================
-- SECTION 10: CUSTOM COMMANDS & FINAL TOUCHES
-- ============================================================
require 'custom.commands'

-- vim: ts=2 sts=2 sw=2 et
