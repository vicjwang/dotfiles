set expandtab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set smartindent
syntax on

autocmd FileType java setlocal noexpandtab
autocmd FileType python setlocal expandtab

set encoding=utf-8
set scrolloff=3
set autoindent
set showmode
set showcmd
set hidden
set wildmenu
set wildmode=list:longest
set visualbell
set cursorline
set ttyfast
set ruler
set backspace=indent,eol,start
set laststatus=2
set relativenumber
set number
set undofile

set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch
nnoremap <tab> %
vnoremap <tab> %

set wrap
set textwidth=79
set formatoptions=qrn1
set colorcolumn=100

let mapleader = ","
nnoremap <leader>w <C-w>v<C-w>l

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
inoremap jj <ESC>
" CTRL+a conflicts with Screen so make CTRL+s increment number in Normal Mode.
nnoremap <C-s> <C-a>
" CTRL+i sometimes behaves like TAB so remap CTRL+m
nnoremap <C-m> <C-i>

" Uncomment the following to have Vim jump to the last position when                                                       
" reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif

" Flagging unecessary white space
set list
set listchars=trail:*

" Plugins
call plug#begin('~/.vim/plugged')  " Or wherever you want your plugins installed
  Plug 'tmhedberg/SimpylFold'
  Plug 'preservim/nerdtree'
  Plug 'vim-scripts/indentpython.vim'
call plug#end()

" NERDTree
" Open NERDTree on file open.
autocmd VimEnter * NERDTree | wincmd p
" Move cursor to NERDTree tab.
nnoremap <C-n> :NERDTreeFind<CR>
" Toggle NERDTree tab visibility.
nnoremap <C-m> :NERDTreeToggle<CR>
" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif

" SimpylFold
set foldmethod=indent

"## ALE ##
" Enable ALE
"let g:ale_enabled = 1

" Python linters (choose one or more)
"let g:ale_python_flake8_options = '--max-line-length=120' " Example flake8 options
"let g:ale_python_pylint_options = '--disable=missing-module-docstring,invalid-name' " Example pylint options
"let g:ale_python_mypy_options = '--ignore-missing-imports --follow-imports=silent'
"
"let g:ale_linters = {
"\   'python': ['flake8', 'pylint', 'mypy'],
"\}
"
"" Python fixers (for auto-fixing)
"let g:ale_fixers = {
"\   'python': ['autopep8', 'black', 'isort'],
"\}
"
"" Automatically fix files on save (use with caution!)
"let g:ale_fix_on_save = 1
"
"" Optional: Customize ALE's appearance
"let g:ale_sign_column_always = 1  " Always show the sign column
"let g:ale_set_quickfix = 1        " Use quickfix list for errors
"let g:ale_set_loclist = 0         " Don't use location list (usually quickfix is better)
"
