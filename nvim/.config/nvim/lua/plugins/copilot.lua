return {
  -- Copilot.lua - Better Lua-based Copilot with completion integration
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-k>",
          accept_line = "<M-j>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          open = "<M-CR>",
        },
      },
      filetypes = {
        yaml = true,
        markdown = true,
        go = true,
        lua = true,
        javascript = true,
        typescript = true,
        typescriptreact = true,
        javascriptreact = true,
        html = true,
        css = true,
        json = true,
        ["*"] = false, -- Disable for all other filetypes
      },
    },
  },
}
