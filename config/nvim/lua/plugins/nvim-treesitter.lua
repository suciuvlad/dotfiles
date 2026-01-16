return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'JoosepAlviste/nvim-ts-context-commentstring',
      -- Playground only when needed
      { 'nvim-treesitter/playground', cmd = "TSPlaygroundToggle" },
    },
    config = function()
      -- Set up Treesitter parser configurations
      local parser_config = require('nvim-treesitter.parsers').get_parser_configs()

      -- Treesitter configuration
      require('nvim-treesitter.configs').setup {
        -- List of parsers to install
        ensure_installed = { 'solidity', 'go', 'html', 'css', 'lua', 'javascript', 'typescript', 'tsx' },
        -- List of parsers to ignore during installation
        ignore_install = { "phpdoc" },
        -- Enable indentation based on Treesitter for specified languages
        indent = { enable = true },
        -- Enable syntax highlighting based on Treesitter
        highlight = {
          enable = true,
          -- Disable highlighting for NvimTree
          disable = { 'NvimTree' },
        -- Disable additional Vim regex-based highlighting for better performance
        additional_vim_regex_highlighting = false,
        },
        -- Enable incremental selection for better memory usage
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

      -- ts_context_commentstring configuration for context-aware comments
      require('ts_context_commentstring').setup {}

      -- Option to skip ts_context_commentstring module
      vim.g.skip_ts_context_commentstring_module = true

      -- Treesitter-based folding settings
      vim.api.nvim_exec([[
        set foldexpr=nvim_treesitter#foldexpr()  " Use Treesitter for fold expressions
        set foldmethod=expr  " Use expression folding method
        set nofoldenable  " Do not enable folding by default
        set foldlevel=1  " Set initial fold level
        set foldnestmax=1  " Set maximum nesting level for folds
      ]], true)
    end
  }
}
