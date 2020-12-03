" configs ------------------------------------------------------
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

syntax enable
filetype plugin indent on

" shortcuts ----------------------------------------------------
let mapleader = ","

nnoremap <leader>W :%s/\s\+$//<cr>:let @/=''<CR>
nnoremap <leader>w <C-w>v<C-w>l
" split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" fzf
nnoremap <silent> <C-p> :Files<CR>
" scripts -------------------------------------------------------
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
