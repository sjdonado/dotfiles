require("treesitter-context").setup({
	enable = true,
	max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
	patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
		default = {
			"class",
			"function",
			"method",
			"for",
			"while",
			"if",
			"switch",
			"case",
			"interface",
			"struct",
			"enum",
		},
		rust = {
			"impl_item",
		},
		javascript = {
			"class_declaration",
			"abstract_class_declaration",
		},
		typescript = {
			"class_declaration",
			"abstract_class_declaration",
			"else_clause",
		},
	},
})
