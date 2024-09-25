return {
  'nvimtools/none-ls.nvim',
  config = function()
    local null_ls = require('null-ls')

    -- Configure null-ls with Go, JS, TS, and React tools
    null_ls.setup({
      sources = {
        -- Go-specific tools
        null_ls.builtins.diagnostics.golangci_lint,  -- Linting with golangci-lint
        null_ls.builtins.formatting.gofumpt,         -- Formatting with gofumpt
        null_ls.builtins.formatting.goimports,       -- Automatically format imports

        -- Go code actions
        null_ls.builtins.code_actions.gomodifytags,  -- Modify struct tags
        null_ls.builtins.code_actions.impl,          -- Generate method stubs for implementing an interface

        -- JavaScript/TypeScript/React tools
        null_ls.builtins.formatting.prettier.with({
          filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json" },
          extra_args = { "--cache" },  -- Enables caching
        }),  -- Formatting with Prettier
      },
    })

    -- Formatting keymap only for buffers with null-ls attached
    local function setup_formatting_keymap(bufnr)
      vim.keymap.set("n", "<leader>gf", function()
        vim.lsp.buf.format({ bufnr = bufnr })
      end, { buffer = bufnr, desc = "Format with null-ls" })
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        setup_formatting_keymap(args.buf)
      end,
    })

    -- Optional: format on save for supported filetypes (comment out if not needed)
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.go", "*.js", "*.jsx", "*.ts", "*.tsx" },
      callback = function(args)
        vim.lsp.buf.format({ bufnr = args.buf })
      end,
    })
  end
}