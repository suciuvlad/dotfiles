return {
  {
    'vim-test/vim-test',
    dependencies = {
      'preservim/vimux'
    },
    config = function()
      vim.keymap.set('n', '<Leader>tn', ':TestNearest<CR>')
      vim.keymap.set('n', '<Leader>tf', ':TestFile<CR>')
      vim.keymap.set('n', '<Leader>ts', ':TestSuite<CR>')
      vim.keymap.set('n', '<Leader>tl', ':TestLast<CR>')
      vim.keymap.set('n', '<Leader>tv', ':TestVisit<CR>')

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
