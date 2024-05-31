local keymap = require 'lib.utils'.keymap

return {
  {
    'vim-test/vim-test',
    dependencies = {
      'preservim/vimux'
    },
    config = function()
      keymap('n', '<Leader>tn', ':TestNearest<CR>', { silent = false })
      keymap('n', '<Leader>tf', ':TestFile<CR>', { silent = false })
      keymap('n', '<Leader>ts', ':TestSuite<CR>', { silent = false })
      keymap('n', '<Leader>tl', ':TestLast<CR>', { silent = false })
      keymap('n', '<Leader>tv', ':TestVisit<CR>', { silent = false })

      -- Define the FloatermStrategy
      vim.cmd([[
        function! FloatermStrategy(cmd)
          execute 'FloatermKill scratch'
          execute 'FloatermNew! --autoclose=2 --name=scratch '.a:cmd.' |less -X'
        endfunction
        let g:test#custom_strategies = {'floaterm': function('FloatermStrategy')}
      ]])

      -- Check if we're inside tmux and set the strategy accordingly
      if vim.fn.exists('$TMUX') == 1 then
        vim.cmd("let g:test#strategy = 'vimux'")
      else
        vim.cmd("let g:test#strategy = 'floaterm'")
      end
    end
  }
}
