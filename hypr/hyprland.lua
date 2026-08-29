-- Hyprland configuration (Lua). Entry point.
-- System: Arch Linux + NVIDIA + dual monitors. Theme: Matugen / Catppuccin Mocha.
--
-- Replaces the deprecated hyprlang config (hyprland.conf), which upstream drops
-- in 0.57/0.58. See docs/superpowers/specs/2026-08-09-hyprland-lua-migration-design.md
--
-- Module order is load-bearing: env must precede anything that execs, and
-- monitors must precede workspace assignment.

require("configs.env")        -- 1. environment, before anything execs
require("configs.system")     -- 2. render/opengl/cursor/misc (NVIDIA)
require("configs.display")    -- 3. monitors, then workspace->monitor assignment
require("configs.input")      -- 4. input + tablet + device
require("configs.look")       -- 5. general/decorations/groups  (reads lib.colors)
require("configs.animations") -- 6. curves, then animations
require("configs.rules")      -- 7. window + layer rules
require("configs.keybinds")   -- 8. binds + resize submap
require("configs.autostart")  -- 9. last: hl.on("hyprland.start")
