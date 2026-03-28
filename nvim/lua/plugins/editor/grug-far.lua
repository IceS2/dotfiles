return {
  "MagicDuck/grug-far.nvim",
  cmd = "GrugFar",
  opts = {},
  keys = {
    { "<leader>sr", function() require("grug-far").open() end, desc = "Search and Replace" },
    { "<leader>sr", function() require("grug-far").with_visual_selection() end, mode = "v", desc = "Search and Replace (Selection)" },
    { "<leader>sR", function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } }) end, desc = "Search and Replace (Current File)" },
  },
}
