return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      transparent_background = false,
      term_colors = true,
      integrations = {
        blink_cmp = true,
        fzf = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        fidget = true,
        indent_blankline = {
          enabled = true,
        },
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      -- Uncomment the line below to use catppuccin instead of tokyonight
      -- vim.cmd.colorscheme "catppuccin"
    end
  }
}
