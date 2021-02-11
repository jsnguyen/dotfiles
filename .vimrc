syntax enable
set tabstop=2
set shiftwidth=2
set expandtab
set number
set showcmd
set cursorline
set wildmenu
set lazyredraw
set showmatch
set incsearch
set hlsearch
set autoindent
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>
inoremap <Up> <Nop>
inoremap <Down> <Nop>
inoremap <Left> <Nop>
inoremap <Right> <Nop>
set backspace=indent,eol,start
filetype on

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
  Plug 'morhetz/gruvbox'
  Plug 'dracula/vim'
  Plug 'vim-airline/vim-airline'
  Plug 'JuliaEditorSupport/julia-vim'
  Plug 'junegunn/goyo.vim'
call plug#end()

inoremap jk <ESC>
inoremap kj <ESC>

colo dracula 
set background=dark
