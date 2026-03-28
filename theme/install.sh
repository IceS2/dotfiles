#!/usr/bin/env bash
# Theme configuration installer
# Handles: core theme, GTK 3/4, Qt 5/6, Kvantum, wallpaper
source "$(dirname "$0")/../lib/helpers.sh"

log_header "Theme"

# Core theme dir (colors.json, matugen, apply-theme.sh, etc.)
link_config theme

# ── GTK 3.0 / 4.0 ──
# GTK dirs must be real directories because apply-theme.sh writes
# colors.css at runtime. We symlink settings.ini and gtk.css only.
for ver in 3.0 4.0; do
    ensure_dir "$HOME/.config/gtk-$ver"
    link_to "theme/gtk-$ver/settings.ini" "$HOME/.config/gtk-$ver/settings.ini"
    link_to "theme/gtk-$ver/gtk.css"      "$HOME/.config/gtk-$ver/gtk.css"
done

# ── Qt / Kvantum ──
link_config theme/qt5ct qt5ct
link_config theme/qt6ct qt6ct
link_config theme/Kvantum Kvantum

# ── Wallpaper ──
# wallpaper dir itself (for theme/wallpaper/README.md reference)
link_config theme/wallpaper wallpaper
# wpaperd config
link_config theme/wallpaper/wpaperd wpaperd
# wallpaper images (accessible as ~/.config/wallpapers)
link_config theme/wallpaper/images wallpapers
