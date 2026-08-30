#!/usr/bin/env bash
# CLI tools configuration installer
# Handles: yazi, zathura, swayimg, paru, scripts
source "$(dirname "$0")/../lib/helpers.sh"

log_header "Tools"

link_config tools/yazi yazi
ya pkg install
link_config tools/zathura zathura
link_config tools/swayimg swayimg
link_config tools/paru paru
link_config tools/scripts scripts
