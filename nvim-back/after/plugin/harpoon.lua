local max_columns = vim.api.nvim_get_option("columns")

require("harpoon").setup({
  menu = {
    width = math.min(max_columns, 110),
  },
})
