set runtimepath+=~/.config/nvim,~/.config/nvim/after

" ------------------------------------------------------------------------
" ## Plugin Manager configs ----------------------------------------------
" ------------------------------------------------------------------------

if empty(glob('~/.config/vim/autoload/plug.vim'))
    silent !curl -fLo ~/.config/vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugins will be downloaded under the specified directory.
call plug#begin('~/.config/nvim/plugged')

" Declare the list of plugins.
Plug 'tpope/vim-fugitive'
Plug 'frazrepo/vim-rainbow'
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'preservim/nerdcommenter'
Plug 'itchyny/lightline.vim'
Plug 'sinetoami/lightline-hunks'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'airblade/vim-gitgutter'
Plug 'vim-scripts/taglist.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'tpope/vim-surround'
Plug 'dense-analysis/ale'
Plug 'jiangmiao/auto-pairs'
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
Plug 'joshdick/onedark.vim'
Plug 'sheerun/vim-polyglot'
Plug 'yuezk/vim-js'
Plug 'maxmellon/vim-jsx-pretty'
" List ends here. Plugins become visible to Vim after this call.
call plug#end()

" ------------------------------------------------------------------------
" ## Plugin configs ------------------------------------------------------
" ------------------------------------------------------------------------
"'joshdick/onedark.vim'
syntax on
colorscheme onedark
" 'frazrepo/vim-rainbow'
" ------------------------------------------------------------------------
let g:rainbow_active = 1

" 'preservim/nerdtree'
" ------------------------------------------------------------------------
map <C-n> :NERDTreeToggle<CR>

" 'itchyny/lightline.vim'
" ------------------------------------------------------------------------
let g:lightline = {
      \ 'colorscheme': 'Tomorrow_Night_Blue',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste', 'lightline_hunks' ],
      \             [ 'readonly', 'filename', 'modified'] ]
      \ },
      \ 'component_function': {
      \   'lightline_hunks': 'lightline#hunks#composer'
      \ },
      \ }

" ------------------------------------------------------------------------
" ## Editor configs ------------------------------------------------------
" ------------------------------------------------------------------------

let mapleader = ","
nnoremap <leader>W :%s/\s\+$//<cr>:let @/=''<CR>
nnoremap <leader>w <C-w>v<C-w>l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" " Copy to clipboard
vnoremap  <leader>y  "+y
nnoremap  <leader>Y  "+yg_
nnoremap  <leader>y  "+y
nnoremap  <leader>yy  "+yy

" " Paste from clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P
set number
set relativenumber
set noshowmode
set gdefault
set cursorline
set smartcase
set mouse=a
set fileencoding=utf-8
set nowrap
set linebreak
set list
set lazyredraw
set tagcase=smart
set breakindent
set smartindent
set expandtab
set shiftwidth=2
set colorcolumn=80
set diffopt+=vertical
set pyxversion=3

augroup vimrc
  autocmd!
  autocmd BufWritePre * call s:strip_trailing_whitespace()
augroup END


function! s:strip_trailing_whitespace()
  if &modifiable
    let l:l = line('.')
    let l:c = col('.')
    call execute('%s/\s\+$//e')
    call histdel('/', -1)
    call cursor(l:l, l:c)
  endif
endfunction
