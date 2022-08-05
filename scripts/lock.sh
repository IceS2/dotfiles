#!/bin/sh

# Heavily based on betterlockscreen.

# Colors
# ------
TRANSPARENT="#00000000"
FOREGROUND="#C0CAF5FF"
CLEAR='#ffffff22'

PINK="#FF26E2FF"
GREEN="#26FF43FF"
CYAN="#26FFB0FF"
CLEAR_CYAN="#26FFB022"
YELLOW="#E2FF26FF"
ORANGE="#FFB026FF"
PURPLE="#B026FFFF"
RED="#FF4326FF"
CLEAR_RED="#FF432622"

# Command to run before locking the screen
prelock() {

    # set dpms timeout
    if [ "$DEFAULT_DPMS" == "Enabled" ]; then
        xset dpms "$LOCK_TIMEOUT"
    fi

    # If dusnt is already paused don't pause it again
    if [[ "$DUNST_INSTALLED" == "true" && "$DUNST_IS_PAUSED" == "false" ]]; then
        dunstctl set-paused true
    fi

}

# How to lock the screen
lock() {
  i3lock \
    --insidever-color=$CLEAR_CYAN \
    --ringver-color=$CYAN   \
    --verif-color=$FOREGROUND \
    --verif-text="Alohomora!" \
    --verif-size=60 \
    \
    --insidewrong-color=$CLEAR_RED \
    --ringwrong-color=$RED \
    --wrong-color=$FOREGROUND \
    --wrong-text="Uh Oh! Try Again (=" \
    --wrong-size=40 \
    \
    --inside-color=$CLEAR \
    --ring-color=$FOREGROUND \
    --line-color=$TRANSPARENT \
    --separator-color=$TRANSPARENT \
    --noinput-text="There's Nothing Here!" \
    \
    --keyhl-color=$PURPLE \
    --bshl-color=$YELLOW \
    --layout-color=$TRANSPARENT \
    \
    --screen 1 \
    --blur 10 \
    --clock \
    --indicator \
    --ring-width 10 \
    --radius 210 \
    \
    --time-str="%H:%M:%S" \
    --time-font="Cascadia Code" \
    --time-size=60 \
    --time-color=$CYAN \
    \
    --date-pos="ix:iy+40" \
    --date-str="%A, %b %d" \
    --date-font="Cascadia Code" \
    --date-color=$PINK \
    --date-size=35 \
    \
    --pass-media-keys \
    --pass-screen-keys \
    --pass-volume-keys \
    --pass-power-keys \
    \
    --nofork

}

# Command to run after unlocking the screen
postlock() {

    # restore default dpms timeout
    if [ "$DEFAULT_DPMS" == "Enabled" ]; then
        xset dpms "$DEFAULT_TIMEOUT"
    fi

    # If dunst already paused before locking don't unpause dunst
    if [[ "$DUNST_INSTALLED" == "true" && "$DUNST_IS_PAUSED" == "false" ]]; then
        dunstctl set-paused false
    fi

}

# Runing the Script

# Original DPMS timeout
DEFAULT_TIMEOUT=$(cut -d ' ' -f4 <<< "$(xset q | sed -n '25p')")
# Original DPMS status
DEFAULT_DPMS=$(xset q | awk '/^[[:blank:]]*DPMS is/ {print $(NF)}')

LOCK_TIMEOUT=300

#Dunst
DUNST_INSTALLED=false && [[ -e "$(command -v dunstctl)" ]] && DUNST_INSTALLED=true
DUNST_IS_PAUSED=false && [[ "$DUNST_INSTALLED" == "true" ]] && DUNST_IS_PAUSED=$(dunstctl is-paused)

prelock

lock

postlock

