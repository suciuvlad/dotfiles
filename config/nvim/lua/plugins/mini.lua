return {
  -- mini.ai - Better text objects (great for React/JS)
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          -- Function text object (works great with React components)
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          -- Class text object
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          -- Parameter/argument text object
          a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
          -- Block text object
          b = ai.gen_spec.treesitter({ a = "@block.outer", i = "@block.inner" }),
          -- Conditional text object
          o = ai.gen_spec.treesitter({ a = "@conditional.outer", i = "@conditional.inner" }),
          -- Loop text object
          l = ai.gen_spec.treesitter({ a = "@loop.outer", i = "@loop.inner" }),
        },
      }
    end,
  },

  -- mini.surround - Better surround operations (cs, ds, ys)
  {
    "echasnovski/mini.surround",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "gsa",            -- Add surrounding in Normal and Visual modes
        delete = "gsd",         -- Delete surrounding
        find = "gsf",           -- Find surrounding (to the right)
        find_left = "gsF",      -- Find surrounding (to the left)
        highlight = "gsh",      -- Highlight surrounding
        replace = "gsr",        -- Replace surrounding
        update_n_lines = "gsn", -- Update `n_lines`
      },
    },
  },

  -- mini.pairs - Auto pairs (alternative to nvim-autopairs, lighter)
  -- Uncomment if you want to replace nvim-autopairs
  -- {
  --   "echasnovski/mini.pairs",
  --   event = "VeryLazy",
  --   opts = {},
  -- },
}
