return {
  {
    'karb94/neoscroll.nvim',
    config = function()
      require('neoscroll.config').set_mappings {
        ['<C-u>'] = { 'scroll', { '-vim.wo.scroll', 'true', '50' } },
        ['<C-d>'] = { 'scroll', { 'vim.wo.scroll', 'true', '50' } },
      }
    end
  }
}