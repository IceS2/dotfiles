return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signcolumn = true,
    numhl = true,
    linehl = false,
    word_diff = false,

    on_attach = function(bufnr)
      local gs = require("gitsigns")

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Gitsigns: " .. desc })
      end

      -- Hunk Navigation
      map("n", "[h", function() gs.nav_hunk("prev") end, "Previous Hunk")
      map("n", "]h", function() gs.nav_hunk("next") end, "Next Hunk")

      -- Actions
      map("n", "<leader>ghs", gs.stage_hunk, "Stage Hunk")
      map("n", "<leader>ghr", gs.reset_hunk, "Reset Hunk")

      -- Whole-buffer Actions
      map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
      map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
    end,
  }
}
