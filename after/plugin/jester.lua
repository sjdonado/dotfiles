require("jester").setup({
	cmd = 'npm run test -- --watchAll=false --no-coverage -t "$result" -- $file',
	dap = {
		type = "pwa-node",
		request = "launch",
		-- trace = true,
		program = "$path_to_jest",
		args = {
			"--runInBand",
			"--watchAll=false",
			"--testNamePattern",
			"${jest.testNamePattern}",
			"--runTestsByPath",
			"${jest.testFile}",
		},
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
})
