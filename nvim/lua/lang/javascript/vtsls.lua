  return {
    settings = {
      typescript = {
        inlayHints = {
          parameterNames = { enabled = "all" },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
        },
        preferences = {
          importModuleSpecifier = "non-relative",
        },
      },
      javascript = {
        inlayHints = {
          parameterNames = { enabled = "all" },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
        },
      },
    },
  }
