return {
  'nvimtools/none-ls.nvim',
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local null_ls = require('null-ls')

    -- Configure null-ls with Go, JS, TS, and React tools
    null_ls.setup({
      debug = false,
      update_in_insert = false,
      debounce = 150,
      sources = {
        -- Go-specific tools
        null_ls.builtins.formatting.gofumpt.with({
          filetypes = { "go" },
        }),  -- Formatting with gofumpt

        -- Go linting with golangci-lint
        -- null_ls.builtins.diagnostics.golangci_lint.with({
        --   filetypes = { "go" },
        -- }),  -- Linting with golangci-lint
        
        null_ls.builtins.formatting.goimports.with({
          filetypes = { "go" },
        }),  -- Automatically format imports
    
        -- Go code actions
        null_ls.builtins.code_actions.gomodifytags.with({
          filetypes = { "go" },
        }),  -- Modify struct tags
    
        null_ls.builtins.code_actions.impl.with({
          filetypes = { "go" },  -- Only apply impl to Go files
        }),  -- Generate method stubs for implementing an interface
    
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

    -- Format on save with size limit for better performance
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.go", "*.js", "*.jsx", "*.ts", "*.tsx" },
      callback = function(args)
        -- Skip formatting for large files (over 100KB)
        if vim.fn.getfsize(vim.fn.expand('%')) > 100000 then
          vim.notify("File too large, skipping format on save", vim.log.levels.WARN)
          return
        end
        vim.lsp.buf.format({ 
          bufnr = args.buf,
          timeout_ms = 2000  -- Timeout after 2 seconds
        })
      end,
    })
  end
}
