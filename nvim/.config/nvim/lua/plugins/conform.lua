return {
  'stevearc/conform.nvim',
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>gf",
      function() require("conform").format({ async = true, lsp_fallback = true }) end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
    {
      "<leader>uf",
      function()
        vim.g.autoformat = not vim.g.autoformat
        vim.notify("Format on save: " .. (vim.g.autoformat and "on" or "off"))
      end,
      desc = "Toggle format on save",
    },
  },
  init = function()
    vim.g.autoformat = true
  end,
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      go = { "goimports", "gofmt" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
    },
    formatters = {
      prettier = {
        prepend_args = { "--cache" },
      },
    },
    format_on_save = function(bufnr)
      if vim.g.autoformat == false then return end
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" and vim.fn.getfsize(name) > 100000 then return end
      return { timeout_ms = 2000, lsp_fallback = true }
    end,
  },
}
