return {
  {
    'williamboman/mason.nvim',
    config = function()
      require("mason").setup()
    end
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { 'solidity', 'gopls', 'html', 'cssls', 'lua_ls', 'ts_ls', 'tailwindcss', 'graphql', 'eslint', 'yamlls', 'jsonls' }
      })
    end
  },
  {
    -- Keep as dependency for mason-lspconfig compatibility
    'neovim/nvim-lspconfig',
    config = function()
      -- Configure diagnostics
      vim.diagnostic.config({
        virtual_text = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "󰌶",
            [vim.diagnostic.severity.INFO] = "",
          },
        },
        underline = true,
        update_in_insert = false,
        float = {
          focusable = true,
          style = "minimal",
          border = "rounded",
          source = true,
          header = "",
          prefix = "",
        },
        severity_sort = true,
      })

      -- LSP keymaps via LspAttach autocmd
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
          end

          map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
          map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
          map('n', 'K', vim.lsp.buf.hover, 'Hover')
          map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
          map('n', '<leader>k', vim.lsp.buf.signature_help, 'Signature help')
          map('n', '<leader>D', vim.lsp.buf.type_definition, 'Type definition')
          map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
          map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
          map('n', 'gr', '<cmd>FzfLua lsp_references<CR>', 'References')
          map('n', '<leader>d', vim.diagnostic.open_float, 'Open diagnostic float')
          map('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, 'Previous diagnostic')
          map('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, 'Next diagnostic')

          -- Disable ts_ls formatting (using Prettier via null-ls instead)
          if client and client.name == 'ts_ls' then
            client.server_capabilities.documentFormattingProvider = false
          end

          -- Enable ESLint formatting
          if client and client.name == 'eslint' then
            client.server_capabilities.documentFormattingProvider = true
          end

          vim.api.nvim_buf_create_user_command(bufnr, 'Format', function()
            vim.lsp.buf.format({ async = true })
          end, { nargs = 0 })
        end,
      })

      -- Default capabilities for all LSP servers (blink.cmp integration)
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      -- Server-specific configurations
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            diagnostics = { globals = { 'vim' } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      vim.lsp.config('gopls', {
        settings = {
          gopls = {
            experimentalPostfixCompletions = true,
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
          },
        },
        init_options = {
          usePlaceholders = true,
        },
      })

      vim.lsp.config('eslint', {
        root_markers = { '.eslintrc', '.eslintrc.json', '.eslintrc.js', 'eslint.config.js', 'eslint.config.mjs' },
        settings = {
          workingDirectory = { mode = 'auto' },
        },
      })

      vim.lsp.config('yamlls', {
        settings = {
          yaml = {
            hover = true,
            completion = true,
            validate = true,
            schemaStore = {
              enable = true,
              url = "https://www.schemastore.org/api/json/catalog.json",
            },
            schemas = {
              ["https://json.schemastore.org/github-workflow"] = ".github/workflows/*",
            },
          },
        },
      })

      vim.lsp.config('jsonls', {
        settings = {
          json = {
            schemas = vim.list_extend(require('schemastore').json.schemas(), {
              {
                description = "GitHub Actions Workflow",
                fileMatch = { ".github/workflows/*.yml", ".github/workflows/*.yaml" },
                url = "https://json.schemastore.org/github-workflow",
              },
            }),
            validate = { enable = true },
          },
        },
      })

      -- Enable all configured servers
      vim.lsp.enable({
        'lua_ls', 'gopls', 'ts_ls', 'eslint',
        'html', 'cssls', 'tailwindcss', 'graphql', 'solidity',
        'yamlls', 'jsonls',
      })
    end
  },
}
