 local function get_python_path()
   -- Try to get from whichpy cache first (if available)
   local whichpy_ok, whichpy_envs = pcall(require, "whichpy.envs")
   if whichpy_ok then
     local selected = whichpy_envs.current_selected()
     if selected and selected ~= "" then
       return selected
     end
   end

   -- Fallback to common virtualenv locations
   local cwd = vim.fn.getcwd()
   local patterns = {
     cwd .. "/env/bin/python",
     cwd .. "/.env/bin/python",
     cwd .. "/.venv/bin/python",
     cwd .. "/venv/bin/python",
     cwd .. "/.virtualenv/bin/python",
   }
   for _, path in ipairs(patterns) do
     if vim.fn.executable(path) == 1 then
       return path
     end
   end

   -- Use system python as last resort
   return vim.fn.exepath("python3") or vim.fn.exepath("python")
 end

 return {
   settings = {
     ty = {
       -- Python environment configuration (mirrors [tool.ty.environment] in pyproject.toml)
       environment = {
         python = get_python_path(),
       },

       -- Diagnostic mode: "openFilesOnly" (default) or "workspace"
       -- openFilesOnly = best performance, only checks open files
       -- workspace = checks entire project (slower but comprehensive)
       diagnosticMode = "openFilesOnly",

       -- Inlay hints for better code readability
       inlayHints = {
         variableTypes = true,          -- Show variable types inline
         callArgumentNames = true,      -- Show parameter names in calls
       },

       -- Completion settings
       completions = {
         autoImport = true,              -- Include non-imported symbols in completions
       },

       -- Uncomment to set specific Python version for analysis
       -- pythonVersion = "3.11",

       -- Uncomment to set target platform
       -- pythonPlatform = "linux",  -- Options: win32, darwin, linux, ios, android, all

       -- Logging (useful for debugging)
       -- logLevel = "info",  -- Options: trace, debug, info, warn, error
     },
   },

   -- Debounce to avoid checking on every keystroke
   -- ty performs incremental checking, so this helps with performance
   flags = {
     debounce_text_changes = 300,  -- Wait 300ms after typing stops
   },
 }

