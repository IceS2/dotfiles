local fn = vim.fn

local install_path = fn.stdpath('data') .. '/site/pack/paqs/start/paq-nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({'git', 'clone', '--depth=1', 'https://github.com/savq/paq-nvim.git', install_path})
end

require 'paq' {
  -- Plugin Manager
  'savq/paq-nvim';

  -- Plenary
  'nvim-lua/plenary.nvim';

  -- Colorscheme
  'folke/tokyonight.nvim';

  -- LSP
  'neovim/nvim-lspconfig';
  'williamboman/mason.nvim';
  'williamboman/mason-lspconfig.nvim';
  'jose-elias-alvarez/null-ls.nvim';
  'jay-babu/mason-null-ls.nvim';

  -- DAP
  'folke/neodev.nvim';
  'mfussenegger/nvim-dap';
  'jay-babu/mason-nvim-dap.nvim';
  'rcarriga/nvim-dap-ui';

  -- Completion
  'hrsh7th/nvim-cmp';
  'hrsh7th/cmp-buffer';
  'hrsh7th/cmp-path';
  'hrsh7th/cmp-cmdline';
  'hrsh7th/cmp-nvim-lsp';
  'hrsh7th/cmp-nvim-lsp-signature-help';
  'onsails/lspkind-nvim';

  -- Rust
  'simrat39/rust-tools.nvim';

  -- Terminal
  'voldikss/vim-floaterm';

  -- Git
  'tpope/vim-fugitive';
  'lewis6991/gitsigns.nvim';

  -- Auto closes
  'windwp/nvim-autopairs';

  -- Comments
  'terrortylor/nvim-comment';

  -- Todo comments
  'folke/todo-comments.nvim';

  -- Which Key
  'folke/which-key.nvim';

  -- mkdir utility
  'jghauser/mkdir.nvim';

  -- matching pairs
  'andymass/vim-matchup';

  -- Indentation guides
  'lukas-reineke/indent-blankline.nvim';

  -- Better Whitespaces
  'ntpeters/vim-better-whitespace';

  -- Icons
  'kyazdani42/nvim-web-devicons';

  -- File Tree
  'kyazdani42/nvim-tree.lua';

  -- LuaLine
  'nvim-lualine/lualine.nvim';

  -- TreeSitter
  {'nvim-treesitter/nvim-treesitter', run=':TSUpdate'};
  'HiPhish/nvim-ts-rainbow2';
  'windwp/nvim-ts-autotag';

  -- Highlight color codes
  'norcalli/nvim-colorizer.lua';

  -- Dashboard
  'glepnir/dashboard-nvim';

  -- Fuzzy Finder
  'nvim-lua/popup.nvim';
  'nvim-telescope/telescope.nvim';
  {'nvim-telescope/telescope-fzf-native.nvim', run='make'};
  'barrett-ruth/telescope-http.nvim';
  'LinArcX/telescope-env.nvim';
  'olacin/telescope-cc.nvim';
  'paopaol/telescope-git-diffs.nvim';

  --resize
  'artart222/vim-resize';

  -- Replace
  'nvim-pack/nvim-spectre';

  -- Project Management
  'ahmedkhalf/project.nvim';

  -- DiffView
  'sindrets/diffview.nvim';

  -- Clipboard
  'AckslD/nvim-neoclip.lua';

  -- Surround
  'echasnovski/mini.nvim';

  -- Aerial
  'stevearc/aerial.nvim';

  -- CodeActionmenu
  'weilbith/nvim-code-action-menu';
  'kosayoda/nvim-lightbulb';

  -- TextObjects
  'kana/vim-textobj-user';
  'kana/vim-textobj-entire';
  'kana/vim-textobj-line';
  'kana/vim-textobj-indent';
  'nvim-treesitter/nvim-treesitter-textobjects';

  -- Just Syntax Highlight
  'NoahTheDuke/vim-just';

  -- Markdown Preview
  'ellisonleao/glow.nvim';
}
