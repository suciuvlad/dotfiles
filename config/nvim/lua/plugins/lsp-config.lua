return {
  {
    'williamboman/mason.nvim',
    config = function()
      -- Setup Mason (LSP/DAP/formatter installer)
      require("mason").setup()
    end
  },
  {
    'williamboman/mason-lspconfig.nvim',
    config = function()
      -- Automatically configure installed LSP servers
      require("mason-lspconfig").setup({
        ensure_installed = { 'solidity', 'gopls', 'html', 'cssls', 'lua_ls', 'ts_ls', 'tailwindcss', 'graphql', 'eslint', 'yamlls', 'jsonls' }
      })
    end
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      local lspconfig = require('lspconfig')

      -- Utility functions for buffer options and key mappings
      local buf_option = vim.api.nvim_buf_set_option
      local buf_keymap = require 'lib.utils'.buf_keymap

      -- Define diagnostic signs for LSP errors and warnings
      local signs = {
        { name = "DiagnosticSignError", text = "" },
        { name = "DiagnosticSignWarn", text = "" },
        { name = "DiagnosticSignHint", text = "󰌶" },
        { name = "DiagnosticSignInfo", text = "" }
      }
      for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { text = sign.text, texthl = sign.name, numhl = "" })
      end

      -- Configure diagnostics to display errors, warnings, etc.
      vim.diagnostic.config({
        virtual_text = true,  -- Show inline diagnostics
        signs = true,         -- Show diagnostic signs in the gutter
        underline = true,     -- Underline problematic code
        update_in_insert = false, -- Don't update diagnostics in insert mode
        float = {
          focusable = true,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
        severity_sort = true, -- Sort diagnostics by severity
      })

      -- Common function to run when an LSP attaches to a buffer
      local on_attach = function(_, bufnr)
        -- Set omnifunction for LSP completion
        buf_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- Key mappings for LSP actions
        buf_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
        buf_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
        buf_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
        buf_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
        buf_keymap(bufnr, 'n', '<leader>k', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
        buf_keymap(bufnr, 'n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
        buf_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
        buf_keymap(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')
        buf_keymap(bufnr, 'n', 'gr', ':Telescope lsp_references<CR>')
        buf_keymap(bufnr, 'n', '<leader>d', '<cmd>lua vim.diagnostic.open_float()<CR>')
        buf_keymap(bufnr, 'n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
        buf_keymap(bufnr, 'n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>')

        -- Command for formatting the buffer
        vim.api.nvim_buf_create_user_command(bufnr, 'Format', function()
          vim.lsp.buf.format({ async = true })
        end, { nargs = 0 })
      end

      -- Enhanced LSP capabilities for nvim-cmp (completion plugin)
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Common LSP settings for better performance
      local default_lsp_config = {
        capabilities = capabilities,
        on_attach = on_attach,
        flags = {
          debounce_text_changes = 150,
        },
      }

      -- Configure individual LSP servers
      lspconfig.lua_ls.setup(vim.tbl_deep_extend("force", default_lsp_config, {
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' }
            },
            workspace = {
              checkThirdParty = false, -- Improves startup time
            },
          }
        }
      }))

      lspconfig.gopls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        flags = {
          debounce_text_changes = 150, -- Debounce changes for performance
        },
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

      -- TypeScript server (ts_ls)
      lspconfig.ts_ls.setup({
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false -- Disable ts_ls formatting if using Prettier or null-ls
          on_attach(client, bufnr) -- Call the common on_attach function
        end,
        capabilities = capabilities,
      })

      lspconfig.eslint.setup({
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = true -- Enable ESLint for formatting
          buf_keymap(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>') -- Code actions
        end,
        root_dir = require('lspconfig.util').root_pattern('.eslintrc', '.eslintrc.json', '.eslintrc.js'),
        settings = {
          workingDirectory = { mode = 'auto' },
        },
        capabilities = capabilities,
      })

      -- Simple LSP servers with default performance config
      local simple_servers = { 'html', 'cssls', 'tailwindcss', 'graphql', 'solidity' }
      for _, server in ipairs(simple_servers) do
        lspconfig[server].setup(default_lsp_config)
      end

      -- YAML server with explicit GitHub Actions schema
      lspconfig.yamlls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
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
              ["https://json.schemastore.org/github-workflow"] = ".github/workflows/*", -- GitHub Actions schema
            },
          },
        },
      })

      -- JSON server with GitHub Actions schema included
      lspconfig.jsonls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
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
    end
  },
}
