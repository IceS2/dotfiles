  return {
    settings = {
      vtsls = {
        tsserver = {
          globalPlugins = {
            {
              name = "@astrojs/ts-plugin",
              location = vim.fn.stdpath("data") .. "/mason/packages/astro-language-server/node_modules/@astrojs/ts-plugin",
              enableForWorkspaceTypeScriptVersions = true,
            },
          },
        },
      },
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
