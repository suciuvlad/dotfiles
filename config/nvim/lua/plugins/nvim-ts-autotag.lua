return {
  {
    'windwp/nvim-ts-autotag',
    config = function()
      require('nvim-ts-autotag').setup({
        opts = {
          -- You can define your setup options here
          enable_close = true, -- Auto close tags
          enable_rename = true, -- Auto rename pairs of tags
          enable_close_on_slash = false, -- Disable auto close on </
        },
      })
    end
  }
}