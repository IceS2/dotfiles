#!/bin/bash
WAL_ROFI_COLOR_FILE="/home/${USER}/.cache/wal/colors-rofi-dark.rasi" 
ROFI_CONFIG="/home/${USER}/.config/rofi/config.rasi"

WAL_COLORS=(active-background urgent-background selected-active-background selected-normal-background selected-urgent-background background foreground)

for color in ${WAL_COLORS[@]}; do
    rofi_regex="^\s*$color: \(#\w\{6\}\)\?;*"
    wal_color=$(sed -n "s/$rofi_regex/\1/p" $WAL_ROFI_COLOR_FILE)
    new_color_config="    $color: $wal_color;"
    sed -i "s/$rofi_regex/$new_color_config/g" $ROFI_CONFIG
    printf "${color}: "
    printf "${wal_color}\n"
    printf "${new_color_config}\n"
done