hl.config({ animations = { enabled = true } })

-- ===== Bezier curves ===== (https://easings.net for visual reference)
-- Must be defined before any animation references them.

-- Snappy deceleration -- subtle overshoot on landing (primary)
hl.curve("snappy",     { type = "bezier", points = { {0.05, 0.9},  {0.1,  1.05} } })
-- MD3 expressive spatial -- pronounced overshoot for entrances (end-4 style)
hl.curve("expressive", { type = "bezier", points = { {0.38, 1.21}, {0.22, 1.0}  } })
-- Acceleration curve -- fast start, clean exit (for closing/removing)
hl.curve("close",      { type = "bezier", points = { {0.3,  0.0},  {0.8,  0.15} } })
-- Emphasized deceleration -- smooth fade-ins
hl.curve("decel",      { type = "bezier", points = { {0.05, 0.7},  {0.1,  1.0}  } })
-- Gentle -- for subtle things like fades
hl.curve("gentle",     { type = "bezier", points = { {0.4,  0.0},  {0.2,  1.0}  } })

-- ===== Window animations =====
-- Open: expressive pop-in with overshoot (iOS feel)
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3, bezier = "expressive", style = "popin 85%" })
-- Close: fast accelerating shrink (don't linger)
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "close",      style = "popin 90%" })
-- Move/resize: smooth repositioning with subtle overshoot
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "snappy",     style = "slide" })

-- ===== Workspace animations =====
-- Slidefade: slide + 20% opacity crossfade (smoother than pure slide)
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3, bezier = "expressive", style = "slidefade 20%" })
-- Scratchpad: vertical slide (distinct from workspace switch)
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "snappy",     style = "slidevert" })

-- ===== Fade animations =====
hl.animation({ leaf = "fade",       enabled = true, speed = 3, bezier = "decel"  })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 3, bezier = "decel"  })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 3, bezier = "gentle" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 3, bezier = "gentle" })
hl.animation({ leaf = "fadeDim",    enabled = true, speed = 3, bezier = "gentle" })

-- ===== Layer animations ===== (QuickShell surfaces, notifications, etc.)
hl.animation({ leaf = "layers",    enabled = true, speed = 2, bezier = "snappy", style = "fade" })
hl.animation({ leaf = "layersIn",  enabled = true, speed = 2, bezier = "snappy", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "close",  style = "fade" })
