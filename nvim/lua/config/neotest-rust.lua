local adapter = require("rustaceanvim.neotest")
local discover_positions = adapter.discover_positions
local nio = require("nio")

local function empty_file_tree(file_path)
  local lines = vim.fn.readfile(file_path)
  local end_row = math.max(#lines - 1, 0)
  local end_col = #lines > 0 and #lines[#lines] or 0

  return require("neotest.lib").positions.parse_tree({
    {
      id = file_path,
      path = file_path,
      name = vim.fs.basename(file_path),
      type = "file",
      range = { 0, 0, end_row, end_col },
    },
  })
end

local function contains_test(tree)
  for _, node in tree:iter_nodes() do
    if node:data().type == "test" then
      return true
    end
  end
  return false
end

local function file_declares_tests(file_path)
  for _, line in ipairs(vim.fn.readfile(file_path)) do
    if line:match("#%s*%[%s*[%w_:]*test%s*[%(%]]") then
      return true
    end
  end
  return false
end

adapter.discover_positions = function(file_path)
  local bufnr = vim.fn.bufnr(file_path)
  local attached = bufnr > 0
      and vim.tbl_filter(function(client)
        return client.name == "rust-analyzer"
      end, vim.lsp.get_clients({ bufnr = bufnr }))
    or {}
  if #attached == 0 then
    return empty_file_tree(file_path)
  end

  local retry_empty = file_declares_tests(file_path)
  local last_tree
  for attempt = 1, 40 do
    local lsp_client = require("rustaceanvim.rust_analyzer").get_client_for_file(file_path, "experimental/runnables")
    if lsp_client then
      local ok, result = pcall(discover_positions, file_path)
      if ok then
        last_tree = result
        if not retry_empty or contains_test(result) then
          return result
        end
      else
        local message = tostring(result)
        local empty_positions = message:find("/neotest/lua/neotest/lib/positions/init.lua:", 1, true)
          and message:find("assertion failed!", 1, true)
        if not empty_positions then
          error(result, 0)
        end
      end
    end

    if attempt < 40 then
      nio.sleep(250)
    end
  end

  return last_tree or empty_file_tree(file_path)
end

return adapter
