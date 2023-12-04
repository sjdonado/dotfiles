local actions = require("telescope.actions")

require("telescope").setup({
  defaults = vim.tbl_extend("force", require("telescope.themes").get_dropdown(), {
    mappings = {
      i = {
        ["<C-t>"] = require("telescope.actions.layout").toggle_preview,
        ["<C-y>"] = require("telescope.actions").preview_scrolling_up,
        ["<C-e>"] = require("telescope.actions").preview_scrolling_down,
        ["<esc>"] = require("telescope.actions").close,
      },
    },
    layout_config = {
      height = 0.2,
      width = function(_, max_columns, _)
        return math.min(max_columns, 110)
      end,
    },
  }),
  pickers = {
    buffers = {
      show_all_buffers = true,
      ignore_current_buffer = true,
      sort_lastused = true,
      mappings = {
        i = {
          ["<leader>dd"] = "delete_buffer",
        },
      },
      layout_config = {
        height = function(_, _, max_lines)
          return math.max(math.floor(max_lines * 0.3), 12)
        end,
      },
    },
  },
})

require("telescope").load_extension("dap")

local find_files_command = {
  "fd",
  "--hidden",
  "--type=file",
  "--glob",
  "--exclude",
  ".git",
}

local find_all_files_command = {
  "fd",
  "--hidden",
  "--no-ignore",
  "--glob",
}

local grep_all_command = {
  "rg",
  "--no-ignore",
  "--unrestricted",
  "--files",
  "--glob",
  "!.git/",
}

-- Custom pickers
local Pickers = {}

Pickers.find_files = function()
  require("telescope.builtin").find_files({
    find_command = find_files_command,
  })
end

Pickers.live_grep = function()
  require("telescope.builtin").live_grep({
    find_command = find_files_command,
  })
end

Pickers.live_grep_all_files = function()
  require("telescope.builtin").live_grep({
    prompt_title = "All Files",
    find_command = grep_all_command,
  })
end

Pickers.grep_string = function(opts)
  require("telescope.builtin").grep_string({
    search = opts.search,
    find_command = find_files_command,
  })
end

Pickers.find_all = function()
  require("telescope.builtin").find_files({
    prompt_title = "All Files",
    find_command = find_all_files_command,
  })
end

return Pickers
