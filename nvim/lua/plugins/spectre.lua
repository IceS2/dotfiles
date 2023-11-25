return {
  "nvim-pack/nvim-spectre",
  event = "VeryLazy",
  config = true,
  keys = {
    { "<leader>so", "<CMD>lua require('spectre').open()<CR>", desc = "Open Spectre" },
    { "<leader>sw", "<CMD>lua require('spectre').open_visual({select_word=true})<CR>", desc = "Search current word" },
    { "<leader>sp", "<CMD>lua require('spectre').open_file_search({select_word=true})<CR>", desc = "Search on current file" }
  }
}
