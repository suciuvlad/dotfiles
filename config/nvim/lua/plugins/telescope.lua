return {
  -- Main Telescope setup
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },  -- Load plenary as dependency
    config = function()
      local telescope = require 'telescope'
      local actions = require 'telescope.actions'
      local keymap = require 'lib.utils'.keymap

      telescope.setup {
        defaults = {
          path_display = { truncate = 1 },
          prompt_prefix = '   ',
          selection_caret = '  ',
          layout_config = {
            prompt_position = 'top',
          },
          sorting_strategy = 'ascending',
          mappings = {
            i = {
              ['<esc>'] = actions.close,
              ['<C-Down>'] = actions.cycle_history_next,
              ['<C-Up>'] = actions.cycle_history_prev,
            },
          },
          file_ignore_patterns = { '.git/', 'vendor' },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
          buffers = {
            previewer = false,
            layout_config = {
              width = 80,
            },
          },
          oldfiles = {
            prompt_title = 'History',
          },
          lsp_references = {
            previewer = false,
          },
        },
      }

      -- Keymaps for Telescope commands
      keymap('n', '<leader>f', [[<cmd>Telescope find_files<CR>]])
      keymap('n', '<leader>F', [[<cmd>Telescope find_files { no_ignore = true, prompt_title = 'All Files' }<CR>]])
      keymap('n', '<leader>lb', [[<cmd>Telescope buffers<CR>]])
      keymap('n', '<leader>lg', [[<cmd>Telescope live_grep<CR>]])
      keymap('n', '<leader>ld', [[<cmd>Telescope diagnostics<CR>]])
      keymap('n', '<leader>h', [[<cmd>Telescope oldfiles<CR>]])
      keymap('n', '<leader>gd', [[<cmd>Telescope lsp_definitions<CR>]], { desc = '[G]oto [D]efinition with Telescope' })
    end
  },

  -- FZF-native extension for faster sorting
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make',
    config = function()
      require('telescope').setup {
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = 'smart_case',
          }
        }
      }

      require('telescope').load_extension('fzf')
    end
  },

  -- UI-select extension for better UI with Telescope
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require('telescope').setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {}
          }
        }
      }

      require('telescope').load_extension('ui-select')
    end,
  }
}