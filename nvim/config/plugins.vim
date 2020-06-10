" 'coc-nvim'
" use <tab> for trigger completion and navigate to the next complete item
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>" 'coc-explorer'
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" -----------------------------------------------
:nmap <space>e :CocCommand explorer<CR>
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

