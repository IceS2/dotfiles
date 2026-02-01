return {
  "snacks.nvim",
  opts = {
    explorer = {
      replace_netrw = true,
      trash = false,
    },
  },

  keys = {
    {
      "<leader>e",
      function() require("snacks").explorer() end,
      desc = "Explorer (Root)"
    },
    {
      "<leader>E",
      function() require("snacks").explorer({ cwd = vim.fn.expand("%:p:h") }) end,
      desc = "Explorer (Current File Dir)"
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("SnacksExplorerAutoOpen", { clear = true }),
      callback = function(data)
        -- Check if the opened file is a directory
        local is_directory = vim.fn.isdirectory(data.file) == 1

        if not is_directory then
          return
        end

        -- Change to the directory
        vim.cmd.cd(data.file)

        -- Create a new empty buffer
        vim.cmd.enew()

        -- Delete the directory buffer
        vim.cmd.bwipeout(data.buf)

        -- Open the explorer sidebar
        -- Using vim.schedule to ensure snacks is fully loaded
        vim.schedule(function()
          require("snacks").explorer()
        end)
      end,
      desc = "Auto-open explorer sidebar when opening directory"
    })
  end,
}
