return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("gitsigns").setup {
      signcolumn = true,
      numhl = true,
      current_line_blame_opts = {
        virt_text_post = "right_align",
        delay = "300"
      }
    }
  end,
  keys = {
    {"<leader>hb", "<CMD>Gitsigns toggle_current_line_blame<CR>", desc = "Toggle Git Current Line Git Blame"}
  }
}
