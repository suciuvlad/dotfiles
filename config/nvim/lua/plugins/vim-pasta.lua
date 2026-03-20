return {
  {
    'sickill/vim-pasta',
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      vim.g.pasta_disabled_filetypes = {'fugitive'}
    end
  }
}