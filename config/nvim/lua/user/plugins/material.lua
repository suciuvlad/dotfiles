local keymap = require 'lib.utils'.keymap

vim.g.material_style = "deep ocean"
vim.cmd 'colorscheme material'

keymap('n', '<leader>mm', [[<cmd>lua require('material.functions').toggle_style()<CR>]])
keymap('n', '<leader>md', [[<cmd>lua require('material.functions').change_style('darker')<CR>]])
keymap('n', '<leader>ml', [[<cmd>lua require('material.functions').change_style('lighter')<CR>]])
