" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')
Plug 'jnurmine/Zenburn'

Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'mdempsky/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }

" Plug 'tmhedberg/SimpylFold'
" let g:SimpylFold_docstring_preview=1
Plug 'vim-scripts/indentpython.vim'
Plug 'nvie/vim-flake8'

function! BuildYCM(info)
  " info is a dictionary with 3 fields
  " - name:   name of the plugin
  " - status: 'installed', 'updated', or 'unchanged'
  " - force:  set on PlugInstall! or PlugUpdate!
  if a:info.status == 'installed' || a:info.force
    !./install.py
  endif
endfunction
Plug 'Valloric/YouCompleteMe', { 'do': function('BuildYCM') }

Plug 'scrooloose/syntastic'
let python_highlight_all=1
Plug 'scrooloose/nerdtree'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline_powerline_fonts = 1
set guifont=Source\ Code\ Pro\ for\ Powerline

" Initialize plugin system
call plug#end()


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
\set tabstop=4
\set softtabstop=4
\set shiftwidth=4
\set expandtab
\set textwidth=79
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

