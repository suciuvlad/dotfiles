return {
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
    config = function()
      require("ibl").setup {
        indent = {
          char = "▏", -- Change this to your preferred character
        },
        scope = {
          show_start = false,
          show_end = false,
        },
        exclude = {
          buftypes = { "terminal", "nofile" },
          filetypes = {
            "help",
            "startify",
            "dashboard",
            "lazy",
            "neogitstatus",
            "NvimTree",
            "Trouble",
            "text",
          },
        },
      }
    end
  }
}
