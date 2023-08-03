local function create_workspace_from_current_root()
  vim.ui.input({ prompt = " Workspace Name " }, function(input)
    if not (input == nil or input == "") then
      require("workspaces").add(input)
    end
  end)
end

return {
  "natecraddock/workspaces.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-tree.lua",
    "nanozuki/tabby.nvim",
  },
  config = function()
    local workspaces = require "workspaces"
    workspaces.setup {
      hooks = {
        open = function()
          local tree_api = require "nvim-tree.api"
          local workspace_name = workspaces.name()
          local workspace_path = ""
          for _, v in ipairs(workspaces.get()) do
            if v.name == workspace_name then
              workspace_path = v.path
            end
          end
          if tree_api.tree.is_visible() then
            tree_api.tree.change_root(workspace_path)
          else
            tree_api.tree.open({ path = workspace_path })
          end
          local tab_id = require("tabby.module.api").get_current_tab()
          require("tabby.feature.tab_name").set(tab_id, workspace_name)
        end
      }
    }
  end,
  keys = {
    {"<leader>wc", create_workspace_from_current_root, desc = "Create Workspace from current dir"}
  }
}
