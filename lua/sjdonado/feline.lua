local feline = require('feline')
local nvimwebdevicons = require('nvim-web-devicons')
local U = require('catppuccin.utils.colors')

nvimwebdevicons.setup({
  override = {
    zsh = {
      icon = '',
      color = '#428850',
      cterm_color = '65',
      name = 'Zsh'
    }
  },
  color_icons = true
})

local c = {
  vim_mode = {
    provider = {
      name = 'vi_mode',
      opts = {
        show_mode_name = true,
        padding = 'center',
      },
    },
    hl = function()
      return {
        fg = require('feline.providers.vi_mode').get_mode_color(),
        bg = 'dark_bg',
        style = 'bold',
        name = 'NeovimModeHLColor',
      }
    end,
    left_sep = 'block',
    right_sep = 'block',
  },
  gitBranch = {
    provider = 'git_branch',
    hl = {
      fg = 'peanut',
      bg = 'dark_bg',
      style = 'bold',
    },
    left_sep = 'block',
    right_sep = 'block',
  },
  gitDiffAdded = {
    provider = 'git_diff_added',
    hl = {
      fg = 'green',
    },
    left_sep = 'block',
  },
  gitDiffRemoved = {
    provider = 'git_diff_removed',
    hl = {
      fg = 'red',
    },
    left_sep = 'block',
  },
  gitDiffChanged = {
    provider = 'git_diff_changed',
    hl = {
      fg = 'fg',
    },
    left_sep = 'block',
  },
  separator = {
    provider = '',
  },
  diagnostic_errors = {
    provider = 'diagnostic_errors',
    hl = {
      fg = 'red',
    },
    right_sep = 'block',
  },
  diagnostic_warnings = {
    provider = 'diagnostic_warnings',
    hl = {
      fg = 'yellow',
    },
    right_sep = 'block',
  },
  diagnostic_hints = {
    provider = 'diagnostic_hints',
    hl = {
      fg = 'aqua',
    },
    right_sep = 'block',
  },
  diagnostic_info = {
    provider = 'diagnostic_info',
    right_sep = 'block',
  },
  lsp_client_names = {
    provider = 'lsp_client_names',
    hl = {
      fg = 'purple',
      bg = 'dark_bg',
      style = 'bold',
    },
    left_sep = 'block',
    right_sep = 'block',
  },
  file_encoding = {
    provider = 'file_encoding',
    hl = {
      fg = 'orange',
      bg = 'dark_bg',
      style = 'italic',
    },
    left_sep = 'block',
    right_sep = 'block',
  },
  position = {
    provider = 'position',
    hl = {
      fg = 'green',
      bg = 'dark_bg',
      style = 'bold',
    },
    left_sep = 'block',
    right_sep = 'block',
  },
  line_percentage = {
    provider = 'line_percentage',
    hl = {
      fg = 'aqua',
      bg = 'dark_bg',
      style = 'bold',
    },
    left_sep = 'block',
    right_sep = 'block',
  },
}

local left = {
  c.vim_mode,
  c.gitBranch,
  c.gitDiffAdded,
  c.gitDiffRemoved,
  c.gitDiffChanged,
  c.separator,
}

local right = {
  c.diagnostic_errors,
  c.diagnostic_warnings,
  c.diagnostic_info,
  c.diagnostic_hints,
  c.separator,
  c.lsp_client_names,
  c.file_encoding,
  c.position,
  c.line_percentage,
}

local components = {
  active = {
    left,
    right,
  },
  inactive = {
    left,
    right,
  },
}

local M = {}

M.setup = function(clrs)
  local theme = {
    fg = clrs.text,
    bg = U.darken(clrs.base, 0.6, clrs.mantle),
    dark_bg = U.lighten(clrs.mantle, 0.8, clrs.base),
    green = clrs.green,
    yellow = clrs.yellow,
    red = clrs.red,
    purple = clrs.mauve,
    aqua = clrs.sky,
    orange = clrs.peach,
  }

  local vi_mode_colors = {
    NORMAL = 'green',
    OP = 'green',
    INSERT = 'yellow',
    VISUAL = 'purple',
    LINES = 'orange',
    BLOCK = 'red',
    REPLACE = 'red',
    COMMAND = 'aqua',
  }

  feline.setup({
    components = components,
    theme = theme,
    vi_mode_colors = vi_mode_colors
  })
end

return M
