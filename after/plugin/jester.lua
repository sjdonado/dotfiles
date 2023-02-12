local Path = require("plenary.path")

local default = {
	identifiers = { "test", "it" }, -- used to identify tests
	prepend = { "describe" }, -- prepend describe blocks
	expressions = { "call_expression" }, -- tree-sitter object used to scan for tests/describe blocks
	escapeRegex = false,
	regexStartEnd = false,
	dap = {
		type = "pwa-node",
		request = "launch",
		-- trace = true,
		program = "$path_to_jest",
		cwd = "${workspaceFolder}",
		skipFiles = { "<node_internals>/**/*.js" },
		resolveSourceMapLocations = {
			"${workspaceFolder}/**",
			"!**/node_modules/**",
		},
		console = "integratedTerminal",
		internalConsoleOptions = "neverOpen",
		disableOptimisticBPs = true,
	},
}

local function setup_jester_by_filetype(config)
	if config.type == "js" then
		require("jester").setup(vim.tbl_extend("force", default, {
			path_to_jest_run = "jest",
			path_to_jest_debug = "./node_modules/.bin/jest",
			cmd = 'npm run test -- --watch=false --no-coverage -t "$result" -- $file',
			dap = vim.tbl_extend("force", default.dap, {
				args = {
					"--watch",
					"false",
					"--testNamePattern",
					"${jest.testNamePattern}",
					"--runTestsByPath",
					"${jest.testFile}",
				},
			}),
		}))
	end

	if config.type == "ts" then
		local relative_path = Path:new(vim.api.nvim_buf_get_name(0)):make_relative(vim.loop.cwd())

		require("jester").setup(vim.tbl_extend("force", default, {
			path_to_jest_run = "vitest",
			path_to_jest_debug = "./node_modules/.bin/vitest",
			cmd = "npm run test -- --watch=false --no-coverage -t $result " .. relative_path,
			dap = vim.tbl_extend("force", default.dap, {
				args = {
					"--watch",
					"false",
					"--testNamePattern",
					"${jest.testNamePattern}",
					relative_path,
				},
			}),
		}))
	end
end

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = { "*.js", "*.jsx" },
	callback = function()
		setup_jester_by_filetype({ type = "js" })
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = { "*.ts", "*.tsx" },
	callback = function()
		setup_jester_by_filetype({ type = "ts" })
	end,
})
