return {
  "voldikss/vim-floaterm",
  event = "TermOpen",
  cmd = { "FloatermNew", "FloatermToggle" },
  config = function()
    vim.g.floaterm_width = 0.7
    vim.g.floaterm_height = 0.8
    vim.g.floaterm_autoclose = 1
    vim.g.floaterm_giteditor = true
  end,
  keys = {
    -- Toggle Floaterm
    { "t", "<CMD>FloatermToggle<CR>", desc = "Toggle Floaterm" },

    -- New Floaterm
    { "<leader>tf", "<CMD>FloatermNew<CR>", desc = "Floaterm New - Float" },
    { "<leader>th", "<CMD>FloatermNew --wintype=split --height=0.3<CR>", desc = "Floaterm New - Horizontal Split" },
    { "<leader>tv", "<CMD>FloatermNew --wintype=vsplit --width=0.3<CR>", desc = "Floaterm New - Vertical Split" },

    -- Git and Docker
    { "<leader>tg", "<CMD>FloatermNew gitui<CR>", desc = "Floaterm - GiTUI" },
    { "<leader>td", "<CMD>FloatermNew lazydocker<CR>", desc = "Floaterm - LazyDocker" },

    -- Move between Terminals
    { mode = "t", "<F2>", "<CMD>FloatermPrev<CR>", desc = "GoTo Previous Floaterm" },
    { mode = "t", "<F3>", "<CMD>FloatermNext<CR>", desc = "GoTo Next Floaterm" },
  }
}
