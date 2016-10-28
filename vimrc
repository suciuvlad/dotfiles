if filereadable(expand("~/.vimrc.bundles"))
  source ~/.vimrc.bundles
endif

set nocompatible  " Use Vim settings, rather then Vi settings

set history=10000
set ruler         " show the cursor position all the time
set showcmd       " display incomplete commands
set incsearch     " do incremental searching
set laststatus=2  " Always display the status line
set ignorecase smartcase

set showmatch
set nowrap
set autoread

" Don't add the comment prefix when I hit enter or o/O on a comment line.
set formatoptions-=or
"
" Remove trailing whitespace on save for ruby files.
au BufWritePre *.rb :%s/\s\+$//e

" Limit line-length to 80 columns by highlighting col 81 onward
if exists("+colorcolumn")
  set colorcolumn=81
endif

set nobackup
set nowritebackup
set noswapfile

set wildignore = *.png,*.PNG,*.JPG,*.jpg,*.GIF,*.gif,vendor/**,coverage/**,tmp/**,rdoc/**

" highlight current line
set cursorline
"
" Highlight the status line
highlight StatusLine ctermfg=blue ctermbg=yellow

set shiftround " When at 3 spaces and I hit >>, go to 4, not 5.

set grepprg=ack
if executable('ag')
  " Use ag over grep
  set grepprg=ag\ --nogroup\ --nocolor

  let $FZF_DEFAULT_COMMAND = 'ag -g ""'
endif
" bind K to grep word under cursor
nnoremap K :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>


" bind \ (backward slash) to grep shortcut
command -nargs=+ -complete=file -bar Ag silent! grep! <args>|cwindow|redraw!
nnoremap \ :Ag<SPACE>

" Snippets are activated by Shift+Tab
let g:snippetsEmu_key = "<S-Tab>"

set go-=L " Removes left hand scroll bar
set guioptions-=r "Removes right hand scroll bar


" Let's be reasonable, shall we?
nmap k gk
nmap j gj

nmap <silent> ,/ :nohlsearch<CR>

" keep more context when scrolling off the end of a buffer
set scrolloff=3

syntax on
filetype plugin indent on

" Line Numbers
set relativenumber
set numberwidth=5

" silent! au FocusLost * :set number
" silent! au FocusGained * :set relativenumber
" silent! autocmd WinLeave * :set number
" silent! autocmd WinEnter * set relativenumber

" Treat <li> and <p> tags like the block tags they are
let g:html_indent_tags = 'li\|p'

" Display extra whitespace
set list listchars=tab:»·,trail:·

" Set the taf file search order
set tags=./tags;

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" STATUS LINE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
:set statusline=%<%f\ (%{&ft})\ %-4(%m%)%=%-19(%3l,%02c%03V%)

set background=dark
set t_Co=256
" colorscheme solarized
if filereadable(expand("~/.vimrc_background"))
  let base16colorspace=256
  source ~/.vimrc_background
endif

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set expandtab

set guifont=Monaco:h12
set guioptions-=m
set guioptions-=T
set smartindent
set autoindent

let mapleader=","

"For autocompletion
set wildmode=list:longest

set hlsearch
set linespace=3
set splitbelow

set foldenable

" Make the current window big, but leave others context
set winwidth=84
" We have to have a winheight bigger than we want to set winminheight. But if
" we set winheight to be huge before winminheight, the winminheight set will
" fail.
set winheight=5
set winminheight=5
set winheight=999

" easier Ack navigation
map <C-n> :cn<CR>
map <C-p> :cp<CR>

" easier navigation between split windows
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ARROW KEYS ARE UNACCEPTABLE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OPEN FILES IN DIRECTORY OF CURRENT FILE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
cnoremap %% <C-R>=expand('%:h').'/'<cr>
map <leader>e :edit %%
map <leader>v :view %%

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RENAME CURRENT FILE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! RenameFile()
    let old_name = expand('%')
    let new_name = input('New file name: ', expand('%'))
    if new_name != '' && new_name != old_name
        exec ':saveas ' . new_name
        exec ':silent !rm ' . old_name
        redraw!
    endif
endfunction
map <leader>n :call RenameFile()<cr>

nnoremap <leader><leader> <c-^>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" SWITCH BETWEEN TEST AND PRODUCTION CODE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! OpenTestAlternate()
  let new_file = AlternateForCurrentFile()
  exec ':e ' . new_file
endfunction
function! AlternateForCurrentFile()
  let current_file = expand("%")
  let new_file = current_file
  let in_spec = match(current_file, '^spec/') != -1
  let going_to_spec = !in_spec
  let in_app = match(current_file, '\<controllers\>') != -1 || match(current_file, '\<models\>') != -1 || match(current_file, '\<views\>') || match(current_file, '\<helpers\>') != -1
  if going_to_spec
    if in_app
      let new_file = substitute(new_file, '^app/', '', '')
    end
    let new_file = substitute(new_file, '\.rb$', '_spec.rb', '')
    let new_file = 'spec/' . new_file
  else
    let new_file = substitute(new_file, '_spec\.rb$', '.rb', '')
    let new_file = substitute(new_file, '^spec/', '', '')
    if in_app
      let new_file = 'app/' . new_file
    end
  endif
  return new_file
endfunction
nnoremap <leader>. :call OpenTestAlternate()<cr>

" RSpec.vim mappings
map <Leader>t :call RunCurrentSpecFile()<CR>
map <Leader>s :call RunNearestSpec()<CR>
map <Leader>l :call RunLastSpec()<CR>
map <Leader>a :call RunAllSpecs()<CR>

map <leader>rt :NERDTreeToggle<cr>

map <Leader>pn :sp ~/Dropbox/dev/notes/project-notes.txt<cr>
map <Leader>m :Rmodel

map <Leader>vc :RVcontroller<cr>
map <Leader>vm :RVmodel<cr>
map <Leader>vv :RVview<cr>

let g:indentLine_color_gui = '#0A3641'
let g:indentLine_char = '┆'

" tell vim to use the system clipboard:
set clipboard=unnamed

let g:Powerline_stl_path_style = 'short'

" Syntax coloring lines that are too long just slows down the world
set synmaxcol=81

set ttyfast " u got a fast terminal
set ttyscroll=3
set lazyredraw " to avoid scrolling problems
"
" This tells vim-rspec to use Send_to_Tmux to run the selected specs.
let g:rspec_command = 'call Send_to_Tmux("rspec {spec} --color -f d\n")'

nnoremap <c-p> :Files<CR>

" Enable snipMate compatibility feature.
let g:neosnippet#enable_snipmate_compatibility = 1

" Tell Neosnippet about the other snippets
let g:neosnippet#snippets_directory='~/.config/nvim/plugged/vim-snippets/snippets'

" Use deoplete.
let g:deoplete#enable_at_startup = 1

let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 1

nnoremap <silent> <BS> :TmuxNavigateLeft<cr>
let g:neomake_javascript_enabled_makers = ['eslint']

hi clear SignColumn

autocmd! BufWritePost * Neomake
