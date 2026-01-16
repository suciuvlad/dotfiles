return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "FzfLua",
  keys = {
    { "<leader>f", "<cmd>FzfLua files<cr>", desc = "Find Files" },
    { "<leader>F", "<cmd>FzfLua files no_ignore=true<cr>", desc = "Find All Files" },
    { "<leader>lg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
    { "<leader>lb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
    { "<leader>h", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
    { "<leader>ld", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Diagnostics" },
    { "gr", "<cmd>FzfLua lsp_references<cr>", desc = "LSP References" },
    { "<leader>gd", "<cmd>FzfLua lsp_definitions<cr>", desc = "LSP Definitions" },
  },
  opts = {
    defaults = {
      git_icons = true,
      file_icons = true,
      color_icons = true,
    },
    winopts = {
      height = 0.85,
      width = 0.80,
      row = 0.35,
      col = 0.50,
      preview = {
        layout = "flex",
        flip_columns = 120,
        scrollbar = false,
      },
    },
    files = {
      prompt = "   ",
      fd_opts = [[--color=never --type f --hidden --follow --exclude .git --exclude node_modules --exclude vendor]],
    },
    grep = {
      prompt = "   ",
      rg_opts = [[--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -g "!{.git,node_modules,vendor}/*"]],
    },
    lsp = {
      code_actions = {
        previewer = "codeaction_native",
      },
    },
  },
}
