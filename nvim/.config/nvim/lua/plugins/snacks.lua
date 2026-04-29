return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    -- Performance: disable features for big files automatically
    bigfile = {
      enabled = true,
      size = 1.5 * 1024 * 1024, -- 1.5MB
      setup = function(ctx)
        vim.b.minianimate_disable = true
        vim.cmd("IndentBlanklineDisable")
        vim.opt_local.foldmethod = "manual"
        vim.opt_local.spell = false
      end,
    },
    -- Faster file opening
    quickfile = { enabled = true },
    -- Better notifications (replaces nvim-notify)
    notifier = {
      enabled = true,
      timeout = 3000,
      style = "compact",
    },
    -- Highlight word under cursor
    words = {
      enabled = true,
      debounce = 200,
    },
    -- Better status column
    statuscolumn = { enabled = true },
    -- Dashboard on startup
    dashboard = {
      enabled = true,
      preset = {
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":FzfLua files" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":FzfLua live_grep" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":FzfLua oldfiles" },
          { icon = " ", key = "c", desc = "Config", action = ":e $MYVIMRC" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
    -- Input UI (better vim.ui.input)
    input = { enabled = true },
    -- Scope detection for indent
    scope = { enabled = true },
    scroll = { enabled = false },
  },
  keys = {
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss Notifications" },
    { "<leader>nh", function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
    { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
  },
}
