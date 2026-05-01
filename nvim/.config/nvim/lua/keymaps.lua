local map = function(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('keep', opts or {}, { silent = true }))
end

vim.g.mapleader = ','
vim.g.maplocalleader = ','

map('n', '<leader><leader>', '<c-^>')

map('n', '<leader>/', ':nohlsearch<CR>')
map('n', '<leader>Q', ':bufdo bdelete<CR>')

-- Allow gf to open non-existent files
map('', 'gf', ':edit <cfile><CR>')

-- Reselect visual selection after indenting
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Maintain the cursor position when yanking a visual selection
-- http://ddrscott.github.io/blog/2016/yank-without-jank/
map('v', 'y', 'myy`hay')
map('v', 'Y', 'myY`y')

-- When text is wrapped, move by terminal rows, not lines, unless a count is provided
map('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
map('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Paste replace visual selection without copying it
map('v', 'p', '"_dP')

-- Easy insertion of a trailing ; or , from insert mode
map('i', ';;', '<Esc>A;<Esc>')
map('i', ',,', '<Esc>A,<Esc>')

-- Open the current file in the default program
map('n', '<leader>x', ':!open %<cr><cr>')

-- Disable annoying command line thing
map('n', 'q:', ':q<CR>')

-- Resize with arrows
map('n', '<C-Up>', ':resize +2<CR>')
map('n', '<C-Down>', ':resize -2<CR>')
map('n', '<C-Left>', ':vertical resize -2<CR>')
map('n', '<C-Right>', ':vertical resize +2<CR>')

-- Move text up and down. Shift-Alt instead of plain Alt so copilot keeps
-- M-j/M-k for accept-line/accept-word.
map('n', '<S-A-j>', ':move .+1<CR>==')
map('n', '<S-A-k>', ':move .-2<CR>==')
map('i', '<S-A-j>', '<Esc>:move .+1<CR>==gi')
map('i', '<S-A-k>', '<Esc>:move .-2<CR>==gi')
map('x', '<S-A-j>', ":move '>+1<CR>gv-gv")
map('x', '<S-A-k>', ":move '<-2<CR>gv-gv")
