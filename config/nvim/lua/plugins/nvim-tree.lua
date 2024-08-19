return {
  {
    'kyazdani42/nvim-tree.lua',
    dependencies = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      require("nvim-tree").setup({
        view = {
          adaptive_size = false,
          centralize_selection = true,
          width = 30,
          cursorline = true,
        },
      })

      vim.cmd [[highlight NvimTreeIndentMarker guifg=#30323E]]

      vim.api.nvim_set_keymap('n', '<leader>n', ':NvimTreeFindFileToggle<CR>', { silent = true, noremap = true })

      vim.g.nvim_tree_indent_markers = 1
      vim.g.nvim_tree_git_hl = 1
      vim.g.nvim_tree_highlight_opened_files = 1
      vim.g.nvim_tree_group_empty = 1
      vim.wo.signcolumn = 'yes'
    end
  }
}