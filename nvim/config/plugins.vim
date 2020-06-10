" 'maxmellon/vim-jsx-pretty'
" -----------------------------------------------
g:vim_jsx_pretty_template_tags = ['html', 'jsx', 'js']

" 'joshdick/onedark.vim'
" -----------------------------------------------
syntax on
colorscheme onedark

" 'frazrepo/vim-rainbow'
" -----------------------------------------------
let g:rainbow_active = 1

" 'itchyny/lightline.vim'
" -----------------------------------------------
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

