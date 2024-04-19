-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'akinsho/toggleterm.nvim',
    opts = {
      open_mapping = [[<c-\>]],
      on_create = function(term)
        vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { buffer = term.bufnr, silent = true, desc = 'Exit terminal mode' })
      end,
      size = function(term)
        if term.direction == 'horizontal' then
          return 25
        elseif term.direction == 'vertical' then
          return vim.o.columns * 0.43
        end
      end,
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
    },
    keys = {
      { '<C-g>', '<cmd>Neogit<CR>', desc = 'Open Neogit' },
    },
  },
}
