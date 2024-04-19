require("tokyonight").setup({
  style = "night",
  on_colors = function(colors)
    colors.fg = "#ffffff"
    colors.fg_dark = "#d9dff9"
    colors.comment = "#6973a1"
    colors.bg = "#101017"
    colors.bg_highlight = "#151721"
    colors.bg_dark = "#0d0d12"
    colors.git = { change = "#a0b5d6", add = "#8bc7d1", delete = "#c38d94" }
    colors.gitSigns = { add = "#43bdb8", change = "#95a6c7", delete = "#d1999d" }
  end,
  on_highlights = function(highlights, colors)
    highlights.LineNr = { fg = "#5e6386" }
    highlights.WinSeparator = { fg = "#9397b3" }
    highlights.DiagnosticUnnecessary = { fg = colors.comment }
    highlights.NvimTreeWinSeparator = { fg = "#9397b3" }
    highlights.NvimTreeNormal = { bg = colors.none, fg = colors.none }
    -- highlights.NeogitHunkHeader = { bg = colors.none, fg = colors.none }
    highlights.NeogitDiffAddHighlight = { bg = colors.none, fg = colors.none }
    highlights.NeogitDiffContextHighlight = { bg = colors.none, fg = colors.none }
    highlights.NeogitDiffDeleteHighlight = { bg = colors.none, fg = colors.none }
    highlights.NeogitHunkHeaderHighlight = { bg = colors.none, fg = colors.none }
  end,
})

vim.cmd([[colorscheme tokyonight-night]])
