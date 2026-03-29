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
			current_line_blame_opts = { delay = 200 },
			current_line_blame_formatter = ' <abbrev_sha> <author>, <author_time:%R> - <summary>',
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
				-- Blame with commit URL in a floating window
				local function get_blame_info()
					local file = vim.fn.expand '%:p'
					local line = vim.fn.line '.'
					local blame_out = vim.fn.systemlist('git blame -p -L ' .. line .. ',' .. line .. ' -- ' .. vim.fn.shellescape(file))
					if #blame_out == 0 then return nil end
					local parts = vim.split(blame_out[1], ' ')
					local sha = parts[1]
					local orig_line = parts[2]
					if sha:match '^0+$' then return nil end
					local info = { sha = sha, orig_line = orig_line }
					for _, bl in ipairs(blame_out) do
						info.author = info.author or bl:match '^author (.+)$'
						info.author_mail = info.author_mail or bl:match '^author%-mail (.+)$'
						info.date = info.date or bl:match '^author%-time (.+)$'
						info.summary = info.summary or bl:match '^summary (.+)$'
						info.filename = info.filename or bl:match '^filename (.+)$'
					end
					if info.date then
						info.date = os.date('%Y-%m-%d %H:%M', tonumber(info.date))
					end
					local path_hash = vim.trim(vim.fn.system("printf '%s' " .. vim.fn.shellescape(info.filename or '') .. " | shasum -a 256 | cut -d' ' -f1"))
					local repo_url = vim.trim(vim.fn.system 'gh repo view --json url -q .url')
					info.url = repo_url .. '/commit/' .. sha .. '#diff-' .. path_hash .. 'R' .. orig_line
					return info
				end

				map('n', '<leader>hb', function()
					local info = get_blame_info()
					if not info then
						vim.notify('No blame info (uncommitted?)', vim.log.levels.WARN)
						return
					end
					local lines = {
						info.author .. ' ' .. (info.author_mail or ''),
						'',
						info.summary or '',
						'',
						info.date .. '  ' .. info.sha:sub(1, 8),
						info.url,
					}
					local buf = vim.api.nvim_create_buf(false, true)
					vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
					local width = 0
					for _, l in ipairs(lines) do width = math.max(width, #l) end
					local win = vim.api.nvim_open_win(buf, true, {
						relative = 'cursor',
						row = 1,
						col = 0,
						width = math.min(width + 2, vim.o.columns - 4),
						height = #lines,
						style = 'minimal',
						border = 'rounded',
					})
					vim.bo[buf].modifiable = false
					vim.bo[buf].bufhidden = 'wipe'
					-- Press Enter to open URL, q or Esc to close
					vim.keymap.set('n', '<CR>', function()
						vim.fn.system('open ' .. vim.fn.shellescape(info.url))
						vim.api.nvim_win_close(win, true)
					end, { buffer = buf })
					vim.keymap.set('n', 'y', function()
						vim.fn.setreg('+', info.sha)
						vim.notify('Copied: ' .. info.sha)
						vim.api.nvim_win_close(win, true)
					end, { buffer = buf })
					vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
					vim.keymap.set('n', '<Esc>', function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
				end, { desc = 'git [b]lame line (full)' })
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
{ 'akinsho/git-conflict.nvim', version = '*', config = true },
	{
		'NeogitOrg/neogit',
		dependencies = { 'nvim-lua/plenary.nvim' },
		keys = {
			{ '<leader>gs', function() require('neogit').open() end, desc = 'Neogit status' },
			{ '<leader>gl', function() require('neogit').open({ 'log' }) end, desc = 'Neogit log' },
		},
		opts = {
			integrations = {
				diffview = false,
			},
		},
	},
}
