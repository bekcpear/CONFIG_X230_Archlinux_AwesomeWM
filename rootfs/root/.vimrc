set pastetoggle=<F2>
set encoding=utf-8
set termencoding=utf-8  
set fileencodings=utf-8,ucs-bom,gbk,default,latin1 

set backupdir=~/.vimbak
set ts=2
set sw=2
"set expandtab

set autoindent
set smartindent
set cindent
filetype indent on

"set cursorline

set shiftwidth=2
set cindent

colorscheme elflord
syntax on
set nu
set foldlevel=100
set ai
set si
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
  filetype plugin indent on

  augroup vimStartup
    au!

    autocmd BufReadPost *
      \ if line("'\"") >= 1 && line("'\"") <= line("$") |
      \   exe "normal! g`\"" |
      \ endif

  augroup END

endif
