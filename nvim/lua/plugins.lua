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
  'navarasu/onedark.nvim';

  -- LSP
  'neovim/nvim-lspconfig';
  'williamboman/nvim-lsp-installer';


  -- Completion
  'hrsh7th/nvim-cmp';
  'hrsh7th/cmp-buffer';
  'hrsh7th/cmp-path';
  'hrsh7th/cmp-cmdline';
  'hrsh7th/cmp-nvim-lsp';
  'L3MON4D3/LuaSnip';
  'saadparwaiz1/cmp_luasnip';
  'ray-x/lsp_signature.nvim';
  'onsails/lspkind-nvim';

  -- Rust
  'simrat39/rust-tools.nvim';

  -- View and Search LSP symbos
  'liuchengxu/vista.vim';

  -- Terminal
  'akinsho/nvim-toggleterm.lua';

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

  -- Bufferline
  'akinsho/nvim-bufferline.lua';

  -- LuaLine
  'nvim-lualine/lualine.nvim';

  -- TreeSitter
  {'nvim-treesitter/nvim-treesitter', run=':TSUpdate'};
  'p00f/nvim-ts-rainbow';
  'windwp/nvim-ts-autotag';

  -- Highlight color codes
  'norcalli/nvim-colorizer.lua';

  -- Dashboard
  'glepnir/dashboard-nvim';

  -- Fuzzy Finder
  'nvim-lua/popup.nvim';
  'nvim-telescope/telescope.nvim';
  {'nvim-telescope/telescope-fzf-native.nvim', run='make'};

  --resize
  'artart222/vim-resize';

  -- DAP
  'mfussenegger/nvim-dap';
  'rcarriga/nvim-dap-ui';
  'Pocco81/DAPInstall.nvim';
  'mfussenegger/nvim-dap-python';
  'nvim-telescope/telescope-dap.nvim';

  -- AutoFocus Windows
  -- 'beauwilliams/focus.nvim'
  'IceS2/focus.nvim';

  -- Replace
  'windwp/nvim-spectre';

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

  -- Distant
  'chipsenkbeil/distant.nvim';
}
