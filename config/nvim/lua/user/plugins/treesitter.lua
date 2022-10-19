local parser_config = require('nvim-treesitter.parsers').get_parser_configs();
-- parser_config.solidity = {
--   install_info = {
--     url = '~/Code/JoranHonig/tree-sitter-solidity/', -- local path or git repo
--     files = { 'src/parser.c' },
--   },
-- }

require('nvim-treesitter.configs').setup {
  ensure_installed = 'all',
  ignore_install = { "phpdoc" },
  indent = {
    enable = { 'solidity', 'go', 'html', 'blade' ,'css', 'javascript', 'typescript'},
  },
  highlight = {
    enable = true,
    disable = { 'NvimTree' },
    additional_vim_regex_highlighting = true,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ['ia'] = '@parameter.inner',
        -- ['aa'] = {
        --   php = "" '@parameter.outer',

        --   python = "(function_definition) @function",
        --   cpp = "(function_definition) @function",
        --   c = "(function_definition) @function",
        --   java = "(method_declaration) @function",
        -- },
      },
    },
  },
  context_commentstring = {
    enable = true,
  },
}

vim.api.nvim_exec([[
  set foldexpr=nvim_treesitter#foldexpr()
  set foldmethod=expr
  set nofoldenable
  set foldlevel=1
  set foldnestmax=1
]], true)
