return {
  "kevinhwang91/nvim-ufo",
  dependencies = { "kevinhwang91/promise-async" },
  event = "BufReadPost",
  opts = {
    provider_selector = function()
      return { "treesitter", "indent" }
    end,
    preview = {
      win_config = {
        border = "single",
        winblend = 0,
      },
    },
  },
  keys = {
    { "zR", function() require("ufo").openAllFolds() end, desc = "Open All Folds" },
    { "zM", function() require("ufo").closeAllFolds() end, desc = "Close All Folds" },
    { "zK", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek Fold" },
  },
}
