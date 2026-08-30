local nio = require("nio")

local function run_async(fn)
  local complete = false
  local succeeded
  local result

  nio.run(function()
    succeeded, result = pcall(fn)
    complete = true
  end)

  assert(
    vim.wait(5000, function()
      return complete
    end, 20),
    "Rust discovery timed out"
  )

  return succeeded, result
end

local adapter = require("config.neotest-rust")
local succeeded, tree = run_async(function()
  return adapter.discover_positions(vim.env.NVIM_RUST_FIXTURE)
end)
assert(succeeded, tree)

local data = tree:data()
assert(data.type == "file", "Rust empty discovery did not return a file root")
assert(data.path == vim.env.NVIM_RUST_FIXTURE, "Rust empty discovery returned the wrong path")

local upstream = require("rustaceanvim.neotest")
local original_discover_positions = upstream.discover_positions
local rust_analyzer = require("rustaceanvim.rust_analyzer")
local original_get_client_for_file = rust_analyzer.get_client_for_file
rust_analyzer.get_client_for_file = function()
  return { id = 1 }
end
local original_get_clients = vim.lsp.get_clients
vim.lsp.get_clients = function()
  return { { id = 1, name = "rust-analyzer" } }
end
local test_bufnr = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(test_bufnr, vim.env.NVIM_RUST_TEST_FIXTURE)

local discovery_attempts = 0
upstream.discover_positions = function(file_path)
  discovery_attempts = discovery_attempts + 1
  local file = {
    id = file_path,
    name = vim.fs.basename(file_path),
    path = file_path,
    type = "file",
    range = { 0, 0, 1, 0 },
  }
  if discovery_attempts == 1 then
    return require("neotest.types.tree").from_list({ file }, function(position)
      return position.name
    end)
  end
  local test = {
    id = file_path .. "::works",
    name = "works",
    path = file_path,
    type = "test",
    range = { 0, 0, 1, 13 },
  }
  return require("neotest.types.tree").from_list({ file, { test } }, function(position)
    return position.name
  end)
end
package.loaded["config.neotest-rust"] = nil

local retry_adapter = require("config.neotest-rust")
local retry_succeeded, retry_tree = run_async(function()
  return retry_adapter.discover_positions(vim.env.NVIM_RUST_TEST_FIXTURE)
end)
assert(retry_succeeded, retry_tree)
assert(discovery_attempts == 2, "Rust adapter discovery attempts: " .. discovery_attempts)
local discovered_test
for _, node in retry_tree:iter_nodes() do
  if node:data().type == "test" then
    discovered_test = node:data().name
  end
end
assert(discovered_test == "works", "Rust adapter returned no test after retry")

upstream.discover_positions = function()
  error("unrelated discovery failure")
end
package.loaded["config.neotest-rust"] = nil

local strict_adapter = require("config.neotest-rust")
local unrelated_succeeded, unrelated_error = run_async(function()
  return strict_adapter.discover_positions(vim.env.NVIM_RUST_TEST_FIXTURE)
end)
assert(not unrelated_succeeded, "Rust adapter swallowed an unrelated discovery error")
assert(tostring(unrelated_error):find("unrelated discovery failure", 1, true), unrelated_error)

upstream.discover_positions = original_discover_positions
rust_analyzer.get_client_for_file = original_get_client_for_file
vim.lsp.get_clients = original_get_clients
