local M = {}

function M.new()
  local self = setmetatable({}, { __index = M })
  self.snapshot = nil
  return self
end

function M:snapshot_settings(_client)
  -- ty auto-detects the Python environment, no settings to snapshot
  self.snapshot = true
end

function M:restore_snapshot(client)
  -- Restart ty to pick up the new environment
  vim.cmd("LspRestart " .. client.name)
end

function M:set_python_path(client, _python_path)
  -- ty has no LSP setting for Python path — restart to re-detect
  vim.cmd("LspRestart " .. client.name)
end

return M
