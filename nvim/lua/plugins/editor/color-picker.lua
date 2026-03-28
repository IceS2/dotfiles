return {
  "eero-lehtinen/oklch-color-picker.nvim",
  version = "*",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "<leader>cp", function() require("oklch-color-picker").pick_under_cursor() end, desc = "Color Picker" },
  },
}
