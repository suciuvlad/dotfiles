return {
  {
    'tpope/vim-fugitive',
    cmd = { "Git", "G", "Gstatus", "Gblame", "Gpush", "Gpull", "Gdiffsplit" },
    dependencies = { 'tpope/vim-rhubarb' },
    keys = {
      { "<leader>gg", "<cmd>Git<CR>", desc = "Git Status" },
      { "<leader>gB", "<cmd>Git blame<CR>", desc = "Git Blame" },
    },
  }
}