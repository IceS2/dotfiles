 local M = {}

 function M.new()
   local self = setmetatable({}, { __index = M })
   self.server_default = {
     python = nil,
   }
   self.snapshot = nil
   return self
 end

 function M:snapshot_settings(client)
   if self.snapshot ~= nil then
     return
   end
   self.snapshot = {}

   -- Capture current python setting (nested under environment)
   if client.settings and client.settings.ty and client.settings.ty.environment and client.settings.ty.environment.python then
     self.snapshot.python = client.settings.ty.environment.python
   else
     self.snapshot.python = self.server_default.python
   end
 end

 function M:restore_snapshot(client)
   self:set_python_path(client, nil)
 end

 function M:set_python_path(client, python_path)
   python_path = python_path or self.snapshot.python

   if python_path then
     -- Update ty's python setting (nested under environment)
     client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
       ty = {
         environment = {
           python = python_path,
         },
       },
     })

     -- Notify the server of configuration change
     client.notify("workspace/didChangeConfiguration", {
       settings = client.settings,
     })
   else
     -- No path available, restart LSP
     vim.cmd("LspRestart " .. client.name)
   end
 end

 return M
