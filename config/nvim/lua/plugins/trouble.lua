return {
  {
    'folke/trouble.nvim',
    dependencies = { 'kyazdani42/nvim-web-devicons' },
    opts = {},  -- Optional, can be customized
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<CR>', desc = "Toggle Diagnostics (Trouble)" },
      { '<leader>xw', '<cmd>Trouble workspace_diagnostics<CR>', desc = "Workspace Diagnostics (Trouble)" },
      { '<leader>xd', '<cmd>Trouble document_diagnostics<CR>', desc = "Document Diagnostics (Trouble)" },
      { '<leader>xl', '<cmd>Trouble loclist<CR>', desc = "Location List (Trouble)" },
      { '<leader>xq', '<cmd>Trouble quickfix<CR>', desc = "Quickfix List (Trouble)" },
      { '<leader>gR', '<cmd>Trouble lsp_references<CR>', desc = "LSP References (Trouble)" },
    },
    config = function()
      require('trouble').setup({})
    end
  }
}