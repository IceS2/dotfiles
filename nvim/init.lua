require('plugins')
require('settings')
require('colorscheme')
require('mappings')
require('diagnostic')


-- Load Plugins
-- -------------

require('plugins_cfg/aerial')
require('plugins_cfg/mason_ls_and_dap')
require('plugins_cfg/cmp')
require('plugins_cfg/indent_blankline')
require('plugins_cfg/tree')
require('plugins_cfg/lualine')
require('plugins_cfg/treesitter')
require('plugins_cfg/colorize')
require('plugins_cfg/dashboard')
require('plugins_cfg/better_whitespace')
require('plugins_cfg/telescope')


require('gitsigns').setup()
require('nvim-autopairs').setup()
require('todo-comments').setup()
require('which-key').setup()
require('mkdir')
require('nvim_comment').setup({
  comment_empty = false
})
require('spectre').setup()
require('project_nvim').setup()
require('diffview').setup()
require('neoclip').setup()
require('mini.surround').setup({
  -- Number of lines within which surrounding is searched
  n_lines = 20,

  -- Duration (in ms) of highlight when calling `MiniSurround.highlight()`
  highlight_duration = 500,

  -- Pattern to match function name in 'function call' surrounding
  -- By default it is a string of letters, '_' or '.'
  funname_pattern = '[%w_%.]+',

  -- Mappings. Use `''` (empty string) to disable one.
  mappings = {
    add = 'sa',           -- Add surrounding
    delete = 'sd',        -- Delete surrounding
    find = 'sf',          -- Find surrounding (to the right)
    find_left = 'sF',     -- Find surrounding (to the left)
    highlight = 'sh',     -- Highlight surrounding
    replace = 'sr',       -- Replace surrounding
    update_n_lines = 'sn' -- Update `n_lines`
  }
})

vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]

