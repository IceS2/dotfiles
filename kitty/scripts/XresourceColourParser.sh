#!/bin/bash
XRESOURCE_COLOUR_FILE="/home/${USER}/.config/xres/themes/default" 
KITTY_COLOUR_CONF_FILE="/home/${USER}/.config/kitty/kittyColor.conf"

COLOUR_DEFINITION=(backg foreg base00 base01 base02 base03 base04 base05 base06 base07 base08 base09 base0A base0B base0C base0D base0E base0F)
COLOURS=(foreground background color0 color1 color2 color3 color4 color5 color6 color7 color8 color9 color10 color11 color12 color13 color14 color15)

for colour in ${COLOUR_DEFINITION[@]}; do
    declare "$colour"=$(awk -v colour="#define $colour " '$0 ~ colour {print $3}' $XRESOURCE_COLOUR_FILE)
done


for colour in ${COLOURS[@]}; do
    colour_defined=$(awk -v colour="$colour: " '$0 ~ colour {print $2}' $XRESOURCE_COLOUR_FILE)
    old_text="^$colour\s\?#\?\(\w\{6\}\)*$"
    new_text="$colour ${!colour_defined}"
    sed -i "s/$old_text/$new_text/g" "$KITTY_COLOUR_CONF_FILE"
done
