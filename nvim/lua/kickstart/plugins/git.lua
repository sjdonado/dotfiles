return {
	{
		'lewis6991/gitsigns.nvim',
		opts = {
			signs = {
				add = { text = '+' },
				change = { text = '~' },
				delete = { text = '_' },
				topdelete = { text = '‾' },
				changedelete = { text = '~' },
			},
			current_line_blame = true,
			on_attach = function(bufnr)
				local gitsigns = require 'gitsigns'

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map('n', ']c', function()
					if vim.wo.diff then
						vim.cmd.normal { ']c', bang = true }
					else
						gitsigns.nav_hunk 'next'
					end
				end, { desc = 'Jump to next git [c]hange' })

				map('n', '[c', function()
					if vim.wo.diff then
						vim.cmd.normal { '[c', bang = true }
					else
						gitsigns.nav_hunk 'prev'
					end
				end, { desc = 'Jump to previous git [c]hange' })

				-- Actions
				-- visual mode
				map('v', '<leader>hs', function()
					gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
				end, { desc = 'git [s]tage hunk' })
				map('v', '<leader>hr', function()
					gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
				end, { desc = 'git [r]eset hunk' })
				-- normal mode
				map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
				map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
				map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
				map('n', '<leader>hu', gitsigns.stage_hunk, { desc = 'git [u]ndo stage hunk' })
				map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
				map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
				map('n', '<leader>hb', gitsigns.blame_line, { desc = 'git [b]lame line' })
				map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
				map('n', '<leader>hD', function()
					gitsigns.diffthis '@'
				end, { desc = 'git [D]iff against last commit' })
				-- Toggles
				map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
				map('n', '<leader>tD', gitsigns.preview_hunk_inline, { desc = '[T]oggle git show [D]eleted' })
			end,
		},
	},
	{
		'ksaito422/remote-line.nvim',
		keys = {
			{ '<leader>hl', '<cmd>RemoteLine<CR>', desc = 'Open git remote [Line]' },
		},
	},
	{
		'tpope/vim-fugitive',
		lazy = false,
		config = function()
			-- Store the in-progress commit message
			local saved_commit_message = nil

			-- Extract commit message (non-comment lines)
			local function extract_commit_message(bufnr)
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
				local message_lines = {}

				for _, line in ipairs(lines) do
					-- Stop at the first comment line
					if line:match '^#' then
						break
					end
					table.insert(message_lines, line)
				end

				-- Remove trailing empty lines
				while #message_lines > 0 and message_lines[#message_lines]:match '^%s*$' do
					table.remove(message_lines)
				end

				return #message_lines > 0 and message_lines or nil
			end

			-- Apply saved commit message to buffer
			local function apply_commit_message(bufnr, message_lines)
				if not message_lines or #message_lines == 0 then
					return
				end

				-- Find where the comments start
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
				local comment_start = 0
				for i, line in ipairs(lines) do
					if line:match '^#' then
						comment_start = i - 1
						break
					end
				end

				-- Replace the non-comment part with our saved message
				-- Add a blank line after message if there isn't one
				local lines_to_insert = vim.deepcopy(message_lines)
				if comment_start > 0 then
					table.insert(lines_to_insert, '')
				end
				vim.api.nvim_buf_set_lines(bufnr, 0, comment_start, false, lines_to_insert)
			end

			-- Auto-cleanup commit buffer after :wq
			vim.api.nvim_create_autocmd('BufWinLeave', {
				pattern = 'COMMIT_EDITMSG',
				callback = function(ev)
					-- If buffer was saved (not modified), commit was submitted
					if not vim.api.nvim_get_option_value('modified', { buf = ev.buf }) then
						-- Clear saved message since commit was successful
						saved_commit_message = nil
						vim.defer_fn(function()
							if vim.api.nvim_buf_is_valid(ev.buf) then
								vim.api.nvim_buf_delete(ev.buf, { force = true })
							end
						end, 100)
					else
						-- Buffer was just hidden, save the commit message
						saved_commit_message = extract_commit_message(ev.buf)
					end
				end,
			})

			local function toggle_commit_split(amend)
				local commit_bufnr = vim.fn.bufnr 'COMMIT_EDITMSG'

				-- Check if commit buffer exists
				if commit_bufnr ~= -1 then
					local commit_winnr = vim.fn.bufwinnr(commit_bufnr)
					if commit_winnr ~= -1 then
						-- Commit window is visible, hide it (message will be saved by autocmd)
						vim.cmd(commit_winnr .. 'wincmd w')
						vim.cmd 'hide'
						return
					else
						-- Buffer exists but not visible, delete it to create fresh one
						vim.api.nvim_buf_delete(commit_bufnr, { force = true })
					end
				end

				-- Create fresh commit buffer
				if amend then
					vim.cmd 'botright vertical Git commit --amend'
					-- Add a visual indicator and apply saved message
					vim.defer_fn(function()
						local bufnr = vim.fn.bufnr 'COMMIT_EDITMSG'
						if bufnr ~= -1 then
							-- Ensure buffer stays loaded when hidden and doesn't reload from disk
							vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = bufnr })
							vim.api.nvim_set_option_value('autoread', false, { buf = bufnr })
							vim.api.nvim_buf_set_extmark(bufnr, vim.api.nvim_create_namespace 'git_amend', 0, 0, {
								virt_text = { { ' [AMEND]', 'WarningMsg' } },
								virt_text_pos = 'inline',
							})
							-- Apply saved commit message if any
							if saved_commit_message then
								apply_commit_message(bufnr, saved_commit_message)
							end
						end
					end, 100)
				else
					vim.cmd 'botright vertical Git commit'
					-- Ensure buffer stays loaded when hidden and apply saved message
					vim.defer_fn(function()
						local bufnr = vim.fn.bufnr 'COMMIT_EDITMSG'
						if bufnr ~= -1 then
							vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = bufnr })
							vim.api.nvim_set_option_value('autoread', false, { buf = bufnr })
							-- Apply saved commit message if any
							if saved_commit_message then
								apply_commit_message(bufnr, saved_commit_message)
							end
						end
					end, 100)
				end
			end

			vim.keymap.set('n', '<leader>gcc', function()
				toggle_commit_split(false)
			end, { desc = 'Toggle Git Commit' })

			vim.keymap.set('n', '<leader>gca', function()
				toggle_commit_split(true)
			end, { desc = 'Toggle Git Commit Amend' })
		end,
	},
	{ 'akinsho/git-conflict.nvim', version = '*', config = true },
	{
		'sindrets/diffview.nvim',
		lazy = true,
		opts = {
			use_icons = vim.g.have_nerd_font,
			view = {
				default = {
					winbar_info = true,
				},
				merge_tool = {
					layout = 'diff3_mixed',
				},
			},
		},
		keys = {
			{ '<leader>gs', desc = 'Toggle DiffView with Git Status' },
			{ '<leader>gl', desc = 'Toggle DiffView with Git Log' },
			{ '<leader>gf', desc = 'Toggle DiffView with Git File History' },
		},
		config = function(_, opts)
			require('diffview').setup(opts)

			-- Reusable toggle function for diffview
			local function toggle_diffview(pattern, open_command)
				local current_tabpage = vim.api.nvim_get_current_tabpage()

				-- Check if current tab has a buffer matching the pattern
				for _, win in ipairs(vim.api.nvim_tabpage_list_wins(current_tabpage)) do
					local bufnr = vim.api.nvim_win_get_buf(win)
					local bufname = vim.api.nvim_buf_get_name(bufnr)
					if bufname:match(pattern) then
						vim.cmd 'DiffviewClose'
						return
					end
				end

				-- Check if any other tab contains a buffer matching the pattern
				for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
					if tabpage ~= current_tabpage then
						for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
							local bufnr = vim.api.nvim_win_get_buf(win)
							local bufname = vim.api.nvim_buf_get_name(bufnr)
							if bufname:match(pattern) then
								local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
								vim.cmd('tabnext ' .. tabnr)
								return
							end
						end
					end
				end

				-- If not open, open it
				vim.cmd(open_command)
			end

			-- Set up keymaps
			vim.keymap.set('n', '<leader>gs', function()
				toggle_diffview('DiffviewFilePanel$', 'DiffviewOpen')
			end, { desc = 'Toggle DiffView with Git Status' })

			vim.keymap.set('n', '<leader>gl', function()
				toggle_diffview('DiffviewFileHistoryPanel', 'DiffviewFileHistory')
			end, { desc = 'Toggle DiffView with Git Log' })

			vim.keymap.set('n', '<leader>gf', function()
				toggle_diffview('DiffviewFileHistoryPanel', 'DiffviewFileHistory %')
			end, { desc = 'Toggle DiffView with Git File History' })
		end,
	},
}
