#!/bin/bash

WAL_XRESOURCES_FILE="/home/${USER}/.cache/wal/colors.Xresources"
DESTINATION_FILE="/home/${USER}/.config/xres/themes/wal_theme"

$(cp $WAL_XRESOURCES_FILE $DESTINATION_FILE)