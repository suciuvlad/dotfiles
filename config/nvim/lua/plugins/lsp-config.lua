return {
  {
    'williamboman/mason.nvim',
    config = function()
      require("mason").setup()
    end
  },
  {
    'williamboman/mason-lspconfig.nvim',
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { 'solidity', 'gopls', 'html', 'cssls', 'lua_ls', 'tsserver', 'tailwindcss', 'graphql' }
      })
    end
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      local lspconfig = require('lspconfig')

      -- Utilities for setting buffer options and keymaps
      local buf_option = vim.api.nvim_buf_set_option
      local buf_keymap = require 'lib.utils'.buf_keymap

      -- Define diagnostic signs
      local signs = {
        { name = "DiagnosticSignError", text = "" },
        { name = "DiagnosticSignWarn", text = "" },
        { name = "DiagnosticSignHint", text = "󰌶" },
        { name = "DiagnosticSignInfo", text = "" }
      }
      for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { text = sign.text, texthl = sign.name, numhl = "" })
      end

      -- Configure diagnostics to use both virtual text and floating windows with LunarVim settings
      vim.diagnostic.config({
        virtual_text = {
          spacing = 4,
          prefix = '●',
        },
        signs = {
          active = true,
          values = signs,
          linehl = {},
          numhl = { "DiagnosticSignError", "DiagnosticSignWarn", "DiagnosticSignInfo", "DiagnosticSignHint" },
          text = { " ", " ", " ", "󰌶 " }
        },
        underline = true,
        update_in_insert = false,
        float = {
          focusable = true,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
        severity_sort = true,
      })

      -- Function to run when language server attaches to buffer
      local on_attach = function(_, bufnr)
        -- Set omnifunc for LSP
        buf_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- Set keymaps for LSP actions
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

        -- Create a command for formatting
        vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
      end

      -- Setup capabilities for nvim-cmp (completion plugin)
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Configure servers via mason-lspconfig
      lspconfig.lua_ls.setup({
        capabilities = capabilities
      })
      lspconfig.gopls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        flags = {
          debounce_text_changes = 150,
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
        }
      })
    end
  },
}
