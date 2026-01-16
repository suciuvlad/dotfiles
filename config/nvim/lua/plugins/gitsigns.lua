return {
  {
    'lewis6991/gitsigns.nvim',
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      current_line_blame = false,
      current_line_blame_opts = {
        delay = 300,
      },
    },
    keys = {
      { '<leader>gp', '<cmd>Gitsigns preview_hunk<CR>', desc = "Preview Hunk" },
      { '<leader>gb', '<cmd>Gitsigns toggle_current_line_blame<CR>', desc = "Toggle Line Blame" },
      { '<leader>gs', '<cmd>Gitsigns stage_hunk<CR>', desc = "Stage Hunk" },
      { '<leader>gr', '<cmd>Gitsigns reset_hunk<CR>', desc = "Reset Hunk" },
      { ']h', '<cmd>Gitsigns next_hunk<CR>', desc = "Next Hunk" },
      { '[h', '<cmd>Gitsigns prev_hunk<CR>', desc = "Prev Hunk" },
    },
  }
}
