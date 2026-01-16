return {
  {
    'kyazdani42/nvim-tree.lua',
    dependencies = { 'kyazdani42/nvim-web-devicons' },
    cmd = { "NvimTreeToggle", "NvimTreeFindFileToggle", "NvimTreeFocus" },
    keys = {
      { '<leader>n', '<cmd>NvimTreeFindFileToggle<CR>', desc = "Toggle File Tree" },
    },
    opts = {
      view = {
        adaptive_size = false,
        centralize_selection = true,
        width = 30,
        cursorline = true,
      },
      renderer = {
        indent_markers = { enable = true },
        highlight_git = true,
        highlight_opened_files = "name",
        group_empty = true,
      },
    },
    config = function(_, opts)
      require("nvim-tree").setup(opts)
      vim.cmd [[highlight NvimTreeIndentMarker guifg=#30323E]]
    end
  }
}