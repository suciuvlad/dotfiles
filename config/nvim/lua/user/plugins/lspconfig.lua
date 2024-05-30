-- -- Setup mason for managing external editor tooling
-- require("mason").setup()

-- -- Ensure specific language servers are installed and configure them via mason-lspconfig
-- require("mason-lspconfig").setup({
--   ensure_installed = { 'solidity', 'gopls', 'html', 'cssls', 'tsserver', 'tailwindcss' }
-- })

-- Require lspconfig for configuring language servers
local lspconfig = require('lspconfig')

-- Utilities for setting buffer options and keymaps
local buf_option = vim.api.nvim_buf_set_option
local buf_keymap = require 'lib.utils'.buf_keymap

-- Function to run when language server attaches to buffer
local on_attach = function(_, bufnr)
  -- Set omnifunc for LSP
  buf_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Set keymaps for LSP actions
  buf_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  buf_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  buf_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  buf_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  buf_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
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
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
capabilities.textDocument.completion.completionItem.snippetSupport = true

-- Configure servers via mason-lspconfig
require('mason-lspconfig').setup_handlers({
  function(server_name)
    lspconfig[server_name].setup {
      on_attach = on_attach,
      capabilities = capabilities,
      flags = {
        debounce_text_changes = 150,
      }
    }
  end,
  -- Specific configuration for gopls
  ['gopls'] = function()
    lspconfig.gopls.setup{
      on_attach = on_attach,
      capabilities = capabilities,
      -- flags = {
      --   debounce_text_changes = 150,
      -- },
      -- settings = {
      --   gopls = {
      --     experimentalPostfixCompletions = true,
      --     analyses = {
      --       unusedparams = true,
      --       shadow = true,
      --     },
      --     staticcheck = true,
      --   },
      -- },
      -- init_options = {
      --   usePlaceholders = true,
      -- }
    }
  end,
  -- Additional specific configurations can be added here
})

-- This code ensures that all specified language servers are installed and configured through mason-lspconfig
-- Any additional settings for specific language servers can be added in the handlers
