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

" set wildignore = *.png,*.PNG,*.JPG,*.jpg,*.GIF,*.gif,vendor/**,coverage/**,tmp/**,rdoc/**

" highlight current line
set cursorline
"
" Highlight the status line
highlight StatusLine ctermfg=blue ctermbg=yellow

set shiftround " When at 3 spaces and I hit >>, go to 4, not 5.

" set grepprg=ack
set grepprg=rg\ --vimgrep\ --smart-case\ --hidden\ --follow


"if executable('ag')
"  " Use ag over grep
"  set grepprg=ag\ --nogroup\ --nocolor
"
"  let $FZF_DEFAULT_COMMAND = 'ag -g ""'
" endif

let $FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"

" bind K to grep word under cursor
nnoremap K :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>


" bind \ (backward slash) to grep shortcut
" command -nargs=+ -complete=file -bar Ag silent! grep! <args>|cwindow|redraw!
" nnoremap \ :Ag<SPACE>
 nnoremap \ :Rg<CR>

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
" set list listchars=tab:¬ª¬∑,trail:¬∑

" Set the taf file search order
set tags=./tags;

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" STATUS LINE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"set statusline=%<%f\ (%{&ft})\ %-4(%m%)%=%-19(%3l,%02c%03V%)

set background=dark
set t_Co=256
" colorscheme solarized
if filereadable(expand("~/.vimrc_background"))
  source ~/.vimrc_background
endif

let base16colorspace=256
"colorscheme base16-ocean

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
" set winwidth=84
" We have to have a winheight bigger than we want to set winminheight. But if
" we set winheight to be huge before winminheight, the winminheight set will
" fail.
" set winheight=5
" set winminheight=5
" set winheight=999

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

map <leader>rt :NERDTreeToggle<cr>

map <Leader>pn :sp ~/Dropbox/dev/notes/project-notes.txt<cr>
map <Leader>m :Rmodel

let g:indentLine_color_gui = '#0A3641'
let g:indentLine_char = '‚îÜ'

" tell vim to use the system clipboard:
set clipboard=unnamed

let g:Powerline_stl_path_style = 'short'

" Syntax coloring lines that are too long just slows down the world
set synmaxcol=81

set ttyfast " u got a fast terminal
" set ttyscroll=3
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
"let g:neomake_javascript_enabled_makers = ['eslint']

hi clear SignColumn

"autocmd! BufWritePost * Neomake

let g:go_fmt_autosave = 1
let g:go_fmt_command = "goimports"

set completeopt-=preview
autocmd FileType javascript setlocal omnifunc=tern#Complete

" Use tern_for_vim.
let g:tern#command = ["tern"]
let g:tern#arguments = ["--persistent"]

let g:deoplete#omni#functions = {}
" set omnifunc=syntaxcomplete#Complete

let g:deoplete#omni#functions.javascript = [
  \ 'tern#Complete',
  \ 'jspc#omni'
  \]

let g:go_def_mode='gopls'
let g:go_info_mode='gopls'


let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_function_parameters = 1
let g:go_highlight_chan_whitespace_error = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_format_strings = 1
let g:go_highlight_variable_declarations = 1
let g:go_highlight_variable_assignments = 1

" test
let g:go_auto_type_info = 1


nnoremap <leader>. :GoAlternate<cr>


" COC Config

" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType go,golang,typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> for scroll float windows/popups.
" Note coc#float#scroll works on neovim >= 0.4.0 or vim >= 8.2.0750
nnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
inoremap <nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"

" NeoVim-only mapping for visual mode scroll
" Useful on signatureHelp after jump placeholder of snippet expansion
if has('nvim')
  vnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#nvim_scroll(1, 1) : "\<C-f>"
  vnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#nvim_scroll(0, 1) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>

" Remap for do codeAction of selected region
function! s:cocActionsOpenFromSelected(type) abort
  execute 'CocCommand actions.open ' . a:type
endfunction
xmap <silent> <leader>a :<C-u>execute 'CocCommand actions.open ' . visualmode()<CR>
nmap <silent> <leader>a :<C-u>set operatorfunc=<SID>cocActionsOpenFromSelected<CR>g@

" highlight CocErrorHighlight ctermfg=Yellow  guifg=#ff00ff
"
" 
autocmd BufWritePre *.go :call CocAction('runCommand', 'editor.action.organizeImport')
let g:airline#extensions#coc#enabled = 1

nnoremap <silent> <leader>h :call CocActionAsync('doHover')<cr>

" END COC Config

set termguicolors
autocmd FileType go nmap <leader>t  <Plug>(go-test)

"=================================="
"           EASY MOTION            "
"=================================="
" ~~~~~ Map easy motion to search
        nmap f <Plug>(easymotion-overwin-f2)
        " NO Need for these with relative lines
        "map / <Plug>(easymotion-bd-jk)
        "nmap / <Plug>(easymotion-overwin-line)
        map  <leader>f <Plug>(easymotion-bd-w)
        nmap <leader>f <Plug>(easymotion-overwin-w)
" ~~~~~ Make sure <leader><leader> isnt remapped
        let g:EasyMotion_do_mapping = 0

"=================================="
"               FZF                "
"=================================="
" ~~~~~ Open FZF search in vim
map <C-p> <Esc><Esc>:Files!<CR>
map <C-f> <Esc><Esc>:BLines!<CR>
map <C-g> <Esc><Esc>:BCommits!<CR>
