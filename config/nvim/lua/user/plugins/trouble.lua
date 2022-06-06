local keymap = require 'lib.utils'.keymap

-- keymap('n', '<leader>xx', ':Trouble<CR>')
keymap('n', '<leader>xx', [[<cmd>Trouble<CR>]])
keymap('n', '<leader>xw', [[<cmd>Trouble workspace_diagnostics<CR>]])
keymap('n', '<leader>xd', [[<cmd>Trouble document_diagnostics<CR>]])
keymap('n', '<leader>xl', [[<cmd>Trouble loclist<CR>]])
keymap('n', '<leader>xq', [[<cmd>Trouble quickfix<CR>]])
keymap('n', '<leader>gR', [[<cmd>Trouble lsp_references<CR>]])

-- vim.api.nvim_set_keymap("n", "<leader>xx", "<cmd>Trouble<cr>",
--   {silent = true, noremap = true}
-- )
-- vim.api.nvim_set_keymap("n", "<leader>xw", "<cmd>Trouble workspace_diagnostics<cr>",
--   {silent = true, noremap = true}
-- )
-- vim.api.nvim_set_keymap("n", "<leader>xd", "<cmd>Trouble document_diagnostics<cr>",
--   {silent = true, noremap = true}
-- )
-- vim.api.nvim_set_keymap("n", "<leader>xl", "<cmd>Trouble loclist<cr>",
--   {silent = true, noremap = true}
-- )
-- vim.api.nvim_set_keymap("n", "<leader>xq", "<cmd>Trouble quickfix<cr>",
--   {silent = true, noremap = true}
-- )
-- vim.api.nvim_set_keymap("n", "gR", "<cmd>Trouble lsp_references<cr>",
--   {silent = true, noremap = true}
-- )