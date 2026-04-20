return {
  'nvimtools/none-ls.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local null_ls = require('null-ls')

    null_ls.setup({
      sources = {
        -- Go
        null_ls.builtins.formatting.goimports,
        null_ls.builtins.code_actions.gomodifytags,
        null_ls.builtins.code_actions.impl,

        -- JS/TS
        null_ls.builtins.formatting.prettier.with({
          filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "markdown" },
          extra_args = { "--cache" },
        }),
      },
    })

    local function format_buf(bufnr)
      vim.lsp.buf.format({
        bufnr = bufnr,
        timeout_ms = 2000,
        filter = function(client) return client.name == "null-ls" end,
      })
    end

    -- Formatting keymap only for buffers with null-ls attached
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "null-ls" then
          vim.keymap.set("n", "<leader>gf", function()
            format_buf(args.buf)
          end, { buffer = args.buf, desc = "Format with null-ls" })
        end
      end,
    })

    -- Format on save
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.go", "*.js", "*.jsx", "*.ts", "*.tsx" },
      callback = function(args)
        if vim.fn.getfsize(vim.fn.expand('%')) > 100000 then
          vim.notify("File too large, skipping format on save", vim.log.levels.WARN)
          return
        end
        format_buf(args.buf)
      end,
    })
  end
}
