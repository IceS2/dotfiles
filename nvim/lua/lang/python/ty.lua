return {
  settings = {
    ty = {
      -- Diagnostic mode: "openFilesOnly" (default) or "workspace"
      diagnosticMode = "openFilesOnly",

      -- Inlay hints
      inlayHints = {
        variableTypes = true,
        callArgumentNames = true,
      },

      -- Completions
      completions = {
        autoImport = true,
      },
    },
  },

  flags = {
    debounce_text_changes = 300,
  },
}
