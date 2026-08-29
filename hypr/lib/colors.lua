-- Reads the Material You palette from theme/colors.json.
--
-- MUST NOT abort on a bad read. Hyprland evaluates this during config load, so
-- an error here fails the whole chunk and drops the session into emergency mode
-- (SUPER+Q only). Under hyprlang a missing generated.conf was merely a `source`
-- warning. The writes are also not atomic -- switch-theme.sh uses `cp` and
-- matugen writes the output path directly -- so a partial read is possible.
--
-- Resolution order: parsed file -> built-in fallback -> error.
-- A missing/partial file costs the theme, not the session; a genuine typo
-- (e.g. camelCase "surfaceContainer") is in neither table and still raises.

local FALLBACK = { -- Catppuccin Mocha; the keys this config actually consumes
  primary                  = "cba6f7",
  secondary                = "b4befe",
  surface                  = "1e1e2e",
  surface_container        = "313244",
  surface_container_lowest = "11111b",
  on_surface               = "cdd6f4",
}

local M, parsed = {}, {}
local path = os.getenv("COLORS_JSON")
    or (os.getenv("HOME") .. "/.config/theme/colors.json")

local f = io.open(path, "r")
if f then
  local s = f:read("a")
  f:close()
  for k, v in s:gmatch('"([%w_]+)"%s*:%s*"#(%x+)"') do parsed[k] = v end
end

local function hex(k)
  return parsed[k] or FALLBACK[k]
      or error("unknown color key: " .. tostring(k), 2)
end

function M.rgb(k)     return "rgb("  .. hex(k) .. ")"      end
function M.rgba(k, a) return "rgba(" .. hex(k) .. a .. ")" end

return M
