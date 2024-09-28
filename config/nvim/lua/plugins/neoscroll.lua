return {
  {
    'karb94/neoscroll.nvim',
    config = function()
      require('neoscroll').setup()

      local scroll = require('neoscroll').scroll

      -- Custom scroll mappings using neoscroll.scroll()
      vim.keymap.set('n', '<C-u>', function() scroll(-vim.wo.scroll, true, 50) end)
      vim.keymap.set('n', '<C-d>', function() scroll(vim.wo.scroll, true, 50) end)
    end
  }
}