local keymap = require 'lib.utils'.keymap

return {
  {
    'folke/trouble.nvim',
    dependencies = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      keymap('n', '<leader>xx', [[<cmd>Trouble<CR>]])
      keymap('n', '<leader>xw', [[<cmd>Trouble workspace_diagnostics<CR>]])
      keymap('n', '<leader>xd', [[<cmd>Trouble document_diagnostics<CR>]])
      keymap('n', '<leader>xl', [[<cmd>Trouble loclist<CR>]])
      keymap('n', '<leader>xq', [[<cmd>Trouble quickfix<CR>]])
      keymap('n', '<leader>gR', [[<cmd>Trouble lsp_references<CR>]])
    end
  }
}