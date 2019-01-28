set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.

Plugin 'fatih/vim-go'
Plugin 'jnurmine/Zenburn'

Plugin 'tmhedberg/SimpylFold'
let g:SimpylFold_docstring_preview=1

Plugin 'vim-scripts/indentpython.vim'

"Plugin 'Valloric/YouCompleteMe'
"let g:ycm_python_binary_path = '/usr/bin/python3'
"let g:ycm_server_python_interpreter = '/usr/bin/python2'

Plugin 'scrooloose/syntastic'
Plugin 'nvie/vim-flake8'
let python_highlight_all=1

Plugin 'scrooloose/nerdtree'
Plugin 'kien/ctrlp.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
let g:airline_powerline_fonts = 1
set guifont=Source\ Code\ Pro\ for\ Powerline


" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
map <C-n> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

set pastetoggle=<F2>
set encoding=utf-8
set termencoding=utf-8  
set fileencodings=utf-8,ucs-bom,gbk,default,latin1 

set backupdir=~/.vimbak
set ts=2
set sw=2
set expandtab
set cursorline

syntax on
set nu
set foldlevel=100
set ai
set si
set cindent
set smarttab
set wrap
set lbr
set tw=0
set foldmethod=syntax

set autoread
set noerrorbells
set novisualbell
set hlsearch
set backspace=start,indent,eol

if has("autocmd")
  augroup vimStartup
    au!

    autocmd BufReadPost *
      \ if line("'\"") >= 1 && line("'\"") <= line("$") |
      \   exe "normal! g`\"" |
      \ endif

  augroup END
endif

if has('gui_running')
  set background=dark
  colorscheme solarized
  let g:solarized_degrade = 0
  set guioptions-=m " 隐藏菜单栏
  set guioptions-=T " 隐藏工具栏
  set guioptions-=L " 隐藏左侧滚动条
  set guioptions-=r " 隐藏右侧滚动条
  set guioptions-=b " 隐藏底部滚动条
else
  colorscheme molokai
endif

" Python
au BufNewFile,BufRead *.py
\set tabstop=2
\set softtabstop=2
\set shiftwidth=2
\set textwidth=79
\set expandtab
\set autoindent
\set fileformat=unix
\set foldmethod=indent
\set foldlevel=99

" css
au BufNewFile,BufRead *.css
\set tabstop=2
\set shiftwidth=2
\set expandtab
\set softtabstop=2

" javascript
au BufNewFile,BufRead *.js
\set tabstop=2
\set shiftwidth=2
\set expandtab

" PHP
au BufNewFile,BufRead *.php
\set tabstop=2
\set softtabstop=2
\set shiftwidth=2
\set expandtab
\set autoindent
\set fileformat=unix

