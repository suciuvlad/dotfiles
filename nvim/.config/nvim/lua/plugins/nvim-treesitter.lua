return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      -- Must be set before loading ts_context_commentstring
      vim.g.skip_ts_context_commentstring_module = true

      -- Treesitter configuration
      require('nvim-treesitter.configs').setup {
        ensure_installed = { 'solidity', 'go', 'html', 'css', 'lua', 'javascript', 'typescript', 'tsx', 'markdown', 'markdown_inline' },
        ignore_install = { "phpdoc" },
        indent = { enable = true },
        highlight = {
          enable = true,
          disable = { 'NvimTree' },
          additional_vim_regex_highlighting = false,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
          },
        },
      }

      require('ts_context_commentstring').setup {}

      -- Treesitter-based folding
      vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
      vim.opt.foldmethod = 'expr'
      vim.opt.foldenable = false
      vim.opt.foldlevel = 1
      vim.opt.foldnestmax = 1
    end
  }
}
