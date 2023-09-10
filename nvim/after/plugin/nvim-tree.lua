local nnoremap = require("sjdonado.keymap").nnoremap

require("nvim-tree").setup({
  actions = {
    open_file = {
      quit_on_open = true,
    },
  },
  view = {
    width = 60,
  },
  on_attach = function(bufnr)
    local api = require("nvim-tree.api")

    local function opts(desc)
      return {
        desc = "nvim-tree: " .. desc,
        buffer = bufnr,
        noremap = true,
        silent = true,
        nowait = true,
      }
    end

    nnoremap("<CR>", api.node.open.edit, opts("Open"))
    nnoremap("o", api.node.open.edit, opts("Open"))
    nnoremap("<2-LeftMouse>", api.node.open.edit, opts("Open"))
    nnoremap("I", api.tree.toggle_gitignore_filter, opts("Toggle Git Ignore"))
    nnoremap("H", api.tree.toggle_hidden_filter, opts("Toggle Dotfiles"))
    nnoremap("U", api.tree.toggle_custom_filter, opts("Toggle Hidden"))
    nnoremap("R", api.tree.reload, opts("Refresh"))
    nnoremap("a", api.fs.create, opts("Create"))
    nnoremap("d", api.fs.remove, opts("Delete"))
    nnoremap("D", api.fs.trash, opts("Trash"))
    nnoremap("r", api.fs.rename, opts("Rename"))
    nnoremap("x", api.fs.cut, opts("Cut"))
    nnoremap("c", api.fs.copy.node, opts("Copy"))
    nnoremap("p", api.fs.paste, opts("Paste"))
    nnoremap("y", api.fs.copy.filename, opts("Copy Name"))
    nnoremap("Y", api.fs.copy.relative_path, opts("Copy Relative Path"))
    nnoremap("gy", api.fs.copy.absolute_path, opts("Copy Absolute Path"))
    nnoremap("W", api.tree.collapse_all, opts("Collapse"))
    nnoremap("E", api.tree.expand_all, opts("Expand All"))
    nnoremap("q", api.tree.close, opts("Close"))
    nnoremap("g?", api.tree.toggle_help, opts("Help"))
  end,
})

-- hide native tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
