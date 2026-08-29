-- Environment variables. Loaded first: must precede anything that execs.
-- Configured for: NVIDIA GPU, Qt6, Wayland.

-- ===== NVIDIA =====
-- VA-API via libva-nvidia-driver (NVDEC bridge) -- enables hardware video
-- decode for Waterfox/Electron. mpv is pinned to hwdec=nvdec in mpv.conf so it
-- uses NVDEC directly and bypasses VA-API regardless.
hl.env("XDG_SESSION_TYPE", "wayland")

hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("__GL_VRR_ALLOWED", "1")

-- Do not force __GL_SYNC_TO_VBLANK: it hangs Waterfox ESR 153 during Wayland
-- EGL startup. Games stay inside the VRR range via MangoHud's 160 FPS cap.

-- Helps preserve OpenGL contexts across screen lock/unlock (kitty freeze fix)
hl.env("__GL_THREADED_OPTIMIZATIONS", "0")

-- NOTE: AQ_NO_ATOMIC was needed for Aquamarine 0.10 + NVIDIA crashes/freezes.
-- Removed for Aquamarine 0.11 + Hyprland 0.55 -- legacy DRM iface causes
-- "Cannot commit when a page-flip is awaiting" errors -> terminal flicker.
-- Modern NVIDIA driver (>=555) + atomic DRM handles this properly.

-- ===== Qt theming & platform =====
hl.env("QT_QPA_PLATFORMTHEME", "hyprqt6engine")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- ===== Input method (cedilla fix for US International) =====
-- GTK on Wayland ignores ~/.XCompose by default -- "simple" forces it to read it
hl.env("GTK_IM_MODULE", "simple")

-- ===== Cursor theme (Catppuccin Mocha Lavender) =====
hl.env("XCURSOR_THEME", "catppuccin-mocha-lavender-cursors")
hl.env("XCURSOR_SIZE", "24")

-- ===== Firefox/Waterfox hardware video acceleration (NVIDIA) =====
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("MOZ_DRM_DEVICE", "/dev/dri/renderD128")
hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")
hl.env("MOZ_DISABLE_GMP_SANDBOX", "1")
hl.env("CUDA_DISABLE_PERF_BOOST", "1")

-- ===== Steam / Proton gaming =====
-- PROTON_* vars are only read by Proton -- no effect on non-game apps.
-- (GW2 overrides PROTON_ENABLE_WAYLAND=0 in Lutris, not here.)
hl.env("PROTON_ENABLE_WAYLAND", "1")
hl.env("PROTON_USE_NTSYNC", "1")
hl.env("PROTON_NO_WM_DECORATION", "1")
hl.env("PROTON_LOCAL_SHADER_CACHE", "1")
hl.env("__GL_SHADER_DISK_CACHE_SKIP_CLEANUP", "1")
hl.env("SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS", "0")
