return {
  -- nvim-cmp LSP integration
  {
    'hrsh7th/cmp-nvim-lsp',
  },

  -- LuaSnip for snippet support and related plugins
  {
    'L3MON4D3/LuaSnip',
    dependencies = {
      'saadparwaiz1/cmp_luasnip',
      'rafamadriz/friendly-snippets'
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end
  },

  -- lspkind for adding icons to completion items
  {
    'onsails/lspkind-nvim',
  },

  -- nvim-cmp (main completion engine)
  {
    "hrsh7th/nvim-cmp",
    config = function()
      local cmp = require'cmp'
      local lspkind = require'lspkind'

      cmp.setup({
        snippet = {
          -- REQUIRED - you must specify a snippet engine
          expand = function(args)
            require('luasnip').lsp_expand(args.body) -- For LuaSnip users
            -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
            -- vim.snippet.expand(args.body) -- For native Neovim snippets (Neovim v0.10+)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item
        }),
        formatting = {
          format = lspkind.cmp_format({
            mode = 'symbol_text',
            maxwidth = 70,
            ellipsis_char = '...',  -- Shorten long entries for readability
          })
        },
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' }, -- LuaSnip for snippets
          { name = 'vsnip' }, -- For vsnip users
          { name = 'ultisnips' }, -- For ultisnips users
          { name = 'snippy' }, -- For snippy users
        }, {
          { name = 'buffer' }, -- Buffer source for text within the current buffer
        })
      })

      -- nvim-autopairs integration with nvim-cmp
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )
    end
  }
}