local actions = require("telescope.actions")

require("telescope").setup({
  defaults = vim.tbl_extend("force", require("telescope.themes").get_dropdown(), {
    mappings = {
      i = {
        ["<C-t>"] = require("telescope.actions.layout").toggle_preview,
        ["<C-y>"] = require("telescope.actions").preview_scrolling_up,
        ["<C-e>"] = require("telescope.actions").preview_scrolling_down,
      },
    },
    layout_config = {
      height = 0.2,
      width = function(_, max_columns, _)
        return math.min(max_columns, 110)
      end,
    },
  }),
})

require("telescope").load_extension("dap")

local find_files_command = {
  "rg",
  "--hidden",
  "--files",
  "--glob",
  "!.git/",
}

local find_all_command = {
  "rg",
  "--hidden",
  "--files",
  "--glob",
  "!.git/",
  "-u",
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
    find_command = find_all_command,
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
    find_command = find_all_command,
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
