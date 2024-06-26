return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
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

      keymap('n', '<leader>f', [[<cmd>lua require('telescope.builtin').find_files()<CR>]])
      keymap('n', '<leader>F', [[<cmd>lua require('telescope.builtin').find_files({ no_ignore = true, prompt_title = 'All Files' })<CR>]])
      keymap('n', '<leader>b', [[<cmd>lua require('telescope.builtin').buffers()<CR>]])
      keymap('n', '<leader>r', [[<cmd>lua require('telescope.builtin').live_grep()<CR>]])
      keymap('n', '<leader>h', [[<cmd>lua require('telescope.builtin').oldfiles()<CR>]])
    end
  },
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = 'make',
    config = function()
      require('telescope').setup {
        extensions = {
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          }
        }
      }

      require('telescope').load_extension('fzf')
    end
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    config = function()
      require('telescope').setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
              -- customize as needed
            }
          }
        }
      }

      require('telescope').load_extension('ui-select')
    end,
  }
}
