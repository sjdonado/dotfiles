local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

parser_config.ejs = {
  install_info = {
    url = "https://github.com/tree-sitter/tree-sitter-embedded-template",
    files = { "src/parser.c" },
    requires_generate_from_grammar = true,
  },
  filetype = "ejs",
}

parser_config.liquid = {
  install_info = {
    url = "https://github.com/Shopify/tree-sitter-liquid",
    branch = "main",
    files = { "src/parser.c" },
  },
}

require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "javascript",
    "html",
    "toml",
    "yaml",
    "dockerfile",
    "http",
    "json",
    "lua",
    "rust",
    "go",
    "python",
    "ejs",
    "liquid",
  },
  sync_install = false,
  highlight = {
    enable = true,
  },
  autopairs = {
    enable = true,
  },
  modules = {},
  ignore_install = {},
})
