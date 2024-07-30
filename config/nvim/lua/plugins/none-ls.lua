return {
  'nvimtools/none-ls.nvim',
  config = function()
      local null_ls = require('null-ls')
      null_ls.setup({
        sources = {
          null_ls.builtins.diagnostics.golangci_lint,  -- Linting with golangci-lint
          null_ls.builtins.formatting.gofumpt,         -- Formatting with gofumpt
          null_ls.builtins.formatting.goimports,       -- Automatically format imports
          null_ls.builtins.code_actions.gomodifytags,  -- Modify struct tags
          null_ls.builtins.code_actions.impl           -- Generate method stubs for implementing an interface
        }
      })

      vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
  end
}
