local feline = require('feline')

require'nvim-web-devicons'.setup {
  override = {
    zsh = {
      icon = '',
      color = '#428850',
      cterm_color = '65',
      name = 'Zsh'
    }
  },
  color_icons = true
}

local one_monokai = {
  fg = '#abb2bf',
  bg = '#1e2024',
  green = '#98c379',
  yellow = '#e5c07b',
  purple = '#c678dd',
  orange = '#d19a66',
  red = '#e06c75',
  aqua = '#61afef',
  darkblue = '#282c34',
  dark_red = '#f75f5f',
}


local github_light = {
  fg = '#586069',
  bg = '#f6f8fa',
  green = '#28a745',
  yellow = '#dbab09',
  purple = '#5a32a3',
  orange = '#d18616',
  red = '#d73a49',
  aqua = '#0598bc',
  darkblue = '#e8e9eb',
  dark_red = '#f75f5f',
}

local vi_mode_colors = {
  NORMAL = 'green',
  OP = 'green',
  INSERT = 'yellow',
  VISUAL = 'purple',
  LINES = 'orange',
  BLOCK = 'dark_red',
  REPLACE = 'red',
  COMMAND = 'aqua',
}

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
        bg = 'darkblue',
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
      bg = 'darkblue',
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
      bg = 'darkblue',
      style = 'bold',
    },
    left_sep = 'block',
    right_sep = 'block',
  },
  file_encoding = {
    provider = 'file_encoding',
    hl = {
      fg = 'orange',
      bg = 'darkblue',
      style = 'italic',
    },
    left_sep = 'block',
    right_sep = 'block',
  },
  position = {
    provider = 'position',
    hl = {
      fg = 'green',
      bg = 'darkblue',
      style = 'bold',
    },
    left_sep = 'block',
    right_sep = 'block',
  },
  line_percentage = {
    provider = 'line_percentage',
    hl = {
      fg = 'aqua',
      bg = 'darkblue',
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

M.dark_setup = function()
  feline.setup({
    components = components,
    theme = one_monokai,
    vi_mode_colors = vi_mode_colors,
  })
end

M.light_setup = function()
  feline.setup({
    components = components,
    theme = github_light,
    vi_mode_colors = vi_mode_colors,
  })
end

return M
