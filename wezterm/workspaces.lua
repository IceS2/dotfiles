local W = {}
local home = os.getenv("HOME")

W.workspaces = {
  projects = {
    default = {
      default = "Default",
      repositories = {
        {
          workspace = "Default",
          tabs = {
            {
              name = "Home",
              path = home
            }
          }
        },
      }
    },
    personal = {
      default = "Default",
      repositories = {
        {
          workspace = "Default",
          tabs = {
            {
              name = "Home",
              path = home
            }
          }
        },
        {
          workspace = "DisparaBot",
          tabs = {
            {
              name = "DisparaBot",
              path = home .. "/Workspace/ices2/disparabot/"
            }
          }
        },
        {
          workspace = "Maia Analysis",
          tabs = {
            {
              name = "Maia Analysis",
              path = home .. "/Workspace/ices2/eric-data-analyst/"
            }
          }
        },
      }
    },
    work = {
      default = "Default",
      repositories = {
        {
          workspace = "Default",
          tabs = {
            {
              name = "Home",
              path = home
            }
          }
        },
        {
          workspace = "OpenMetadata",
          tabs = {
            {
              name = "OpenMetadata",
              path = home .. "/Workspace/repos/UpstreamOpenMetadata"
            }
          }
        },
        {
          workspace = "Collate",
          tabs = {
            {
              name = "Collate",
              path = home .. "/Workspace/repos/openmetadata-collate"
            }
          }
        },
      }
    }
  }
}

return W
