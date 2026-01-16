return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 300,
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "+",
    },
    spec = {
      { "<leader>c", group = "code" },
      { "<leader>d", group = "debug/diagnostics" },
      { "<leader>g", group = "git/goto" },
      { "<leader>l", group = "list/lsp" },
      { "<leader>n", group = "notifications" },
      { "<leader>t", group = "test" },
      { "<leader>u", group = "ui" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps",
    },
  },
}
