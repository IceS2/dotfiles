#!/usr/bin/env bash
# Gaming configuration installer
# Handles: MangoHud, GameMode
source "$(dirname "$0")/../lib/helpers.sh"

log_header "Gaming"

# MangoHud config
link_config gaming/MangoHud MangoHud

# MangoHud log directory
ensure_dir "$HOME/Documents/mangohud_logs"

# GameMode system config
sudo_copy gaming/gamemode.ini /etc/gamemode.ini
