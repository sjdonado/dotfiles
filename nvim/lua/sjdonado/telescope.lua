local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_mt = require("telescope.actions.mt")

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

-- Custom actions
local Actions = {}

Actions.copy_entry = function(prompt_bufnr)
	local current_picker = action_state.get_current_picker(prompt_bufnr)
	local entry = action_state.get_selected_entry()

	vim.fn.setreg("+", entry.value)
end

local custom_actions = action_mt.transform_mod(Actions)

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

Pickers.git_commits = function()
	require("telescope.builtin").git_commits({
		attach_mappings = function(_, map)
			map("i", "<leader>cc", custom_actions.copy_entry)
			map("n", "<leader>cc", custom_actions.copy_entry)
			return true
		end,
	})
end

Pickers.git_branches = function()
	require("telescope.builtin").git_branches({
		attach_mappings = function(_, map)
			map("i", "<leader>cc", custom_actions.copy_entry)
			map("n", "<leader>cc", custom_actions.copy_entry)
			map("i", "<leader>dd", actions.git_delete_branch)
			map("n", "<leader>dd", actions.git_delete_branch)
			return true
		end,
	})
end

return Pickers
