return {
  {
    'numToStr/Comment.nvim',
    opts = {
      -- Add your options here
      pre_hook = function(ctx)
        -- Only calculate commentstring for tsx filetypes
        if vim.bo.filetype == 'typescriptreact' or vim.bo.filetype == 'javascriptreact' then
          local U = require 'Comment.utils'

          -- Determine whether to use linewise or blockwise commentstring
          local type = ctx.ctype == U.ctype.line and '__default' or '__multiline'

          -- Determine the location where to calculate commentstring
          local location = nil
          if ctx.ctype == U.ctype.block then
            location = require('ts_context_commentstring.utils').get_cursor_location()
          elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
            location = require('ts_context_commentstring.utils').get_visual_start_location()
          end

          return require('ts_context_commentstring.internal').calculate_commentstring {
            key = type,
            location = location,
          }
        end
      end,
    },
  }
}
