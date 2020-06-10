if empty(glob('~/.config/nvim/autoload/plug.vim'))
    silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugins will be downloaded under the specified directory.
call plug#begin('~/.config/nvim/plugged')

" Declare the list of plugins.
" git -----------------------------------------------------
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
" editor --------------------------------------------------
Plug 'frazrepo/vim-rainbow'
Plug 'itchyny/lightline.vim'
Plug 'sinetoami/lightline-hunks'
Plug 'joshdick/onedark.vim'
" utils ---------------------------------------------------
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'vim-scripts/taglist.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'jiangmiao/auto-pairs'
Plug 'sheerun/vim-polyglot'
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-entire'
Plug 'kana/vim-textobj-line'
Plug 'kana/vim-textobj-indent'
Plug 'christoomey/vim-system-copy'
" python --------------------------------------------------
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
" javascript ----------------------------------------------
Plug 'yuezk/vim-js'
Plug 'maxmellon/vim-jsx-pretty'
" List ends here. Plugins become visible to Vim after this call.
call plug#end()

