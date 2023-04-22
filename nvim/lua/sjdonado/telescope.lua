local actions = require("telescope.actions")

require("telescope").setup({
  pickers = {
    find_files = {
      theme = "dropdown",
    },
    grep_string = {
      theme = "dropdown",
    },
    live_grep = {
      theme = "dropdown",
    },
    buffers = {
      theme = "dropdown",
    },
    command_history = {
      theme = "dropdown",
    },
    search_history = {
      theme = "dropdown",
    },
  },
})

require("telescope").load_extension("dap")

local find_command = {
  "rg",
  "--hidden",
  "--files",
  "--glob",
  "!.git/",
}

-- Custom pickers
local Pickers = {}

Pickers.find_files = function()
  require("telescope.builtin").find_files({
    find_command = find_command,
  })
end

Pickers.live_grep = function()
  require("telescope.builtin").live_grep({
    find_command = find_command,
  })
end

Pickers.grep_string = function(opts)
  require("telescope.builtin").grep_string({
    search = opts.search,
    find_command = find_command,
  })
end

Pickers.find_all = function()
  require("telescope.builtin").find_files({
    prompt_title = "All Files",
    find_command = {
      "rg",
      "--hidden",
      "--files",
      "--glob",
      "!.git/",
      "-u",
    },
  })
end

Pickers.buffers = function()
  require("telescope.builtin").buffers({
    attach_mappings = function(_, map)
      map("i", "<leader>dd", actions.delete_buffer)
      map("n", "<leader>dd", actions.delete_buffer)
      return true
    end,
  })
end

return Pickers
