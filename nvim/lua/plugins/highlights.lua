return {
  {
    "RRethy/vim-illuminate",
    event = "BufReadPost",
    config = function()
      require("illuminate").configure({
        delay = 200,
        filetypes_denylist = {
          "NvimTree"
        }
      })
    end
  },
  {
    "andymass/vim-matchup",
    lazy = false,
    init = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup"}
    end
  }
}
