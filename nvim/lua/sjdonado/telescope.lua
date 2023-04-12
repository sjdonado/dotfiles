local actions = require("telescope.actions")

require("telescope").setup({
  defaults = {
    color_devicons = true,
    file_sorter = require("telescope.sorters").get_fzy_sorter,
    mappings = {
      i = {
        ["<C-n>"] = actions.cycle_previewers_next,
        ["<C-p>"] = actions.cycle_previewers_prev,
      },
    },
  },
})

require("telescope").load_extension("dap")

-- Custom pickers
local Pickers = {}

Pickers.search_dotfiles = function()
  require("telescope.builtin").find_files({
    prompt_title = "< VimRC >",
    cwd = vim.env.DOTFILES,
    hidden = true,
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
