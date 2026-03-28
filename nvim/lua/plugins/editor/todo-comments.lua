return {
  "folke/todo-comments.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {},
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO" },
    { "<leader>st", function() require("snacks").picker.todo_comments() end, desc = "TODOs (Picker)" },
    { "<leader>sT", "<cmd>TodoTrouble<cr>", desc = "TODOs (Trouble)" },
  },
}
