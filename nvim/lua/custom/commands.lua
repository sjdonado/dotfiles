local reference = require 'custom.copy-reference'

-- Yank file location (Cmd+Shift+Y via Ghostty: \x01\x19), alongside the
-- <leader>y maps the module registers.
vim.keymap.set('n', '\x01\x19', reference.line, { desc = 'Yank file location' })
vim.keymap.set('x', '\x01\x19', reference.range, { desc = 'Yank file location' })
