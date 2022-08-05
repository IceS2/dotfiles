#!/bin/bash
#
# Based on the provided -c (color) and -t (theme) flags, gets the color value
# from the theme located in THEME_PATH.
# the theme should be a folder containing the xresources.Xresources file.


# Function definitions --------------------------------------------------------

###############################################################################
# Loads themes from THEME_PATH
# Globals:
#   THEME_PATH
# Arguments:
#   None
###############################################################################
load_themes () {
  echo "$(ls $THEME_PATH)"
}

###############################################################################
# Loads COLOR_MAP
# Globals:
#   None
# Arguments:
#   None
###############################################################################
load_color_map () {
read -d '' COLOR_MAP << END
black: color0
red: color1
green: color2
yellow: color3
blue: color4
magenta: color5
cyan: color6
white: color7
bright-black: color8
bright-red: color9
bright-green: color10
bright-yellow: color11
bright-blue: color12
bright-magenta: color13
bright-cyan: color14
bright-white: color15
background: background
foreground: foreground
highlight: highlight
END

echo "$COLOR_MAP"
}

###############################################################################
# Validates if `color` is in COLOR_MAP
# Globals:
#   COLOR_MAP
# Arguments:
#   color
###############################################################################
is_valid_color () {
  VALID_COLORS=($(echo "$COLOR_MAP" | sed -E "s/(\w+-*\w+): [A-z0-0]+/\1/"))
  color=$1

  is_valid=false

  for valid_color in "${VALID_COLORS[@]}"; do
    if [[ $color == "$valid_color" ]]; then
      is_valid=true
      break
    fi
  done

  if [ "$is_valid" = false ]; then
    echo "Color ${color} is invalid."
    exit 1
  fi
}

###############################################################################
# Validates if `theme` is in THEMES
# Globals:
#   THEMES
# Arguments:
#   theme
###############################################################################
is_valid_theme () {
  VALID_THEMES=($THEMES)
  theme=$1

  is_valid=false

  for valid_theme in "${VALID_THEMES[@]}"; do
    if [[ $theme == "$valid_theme" ]]; then
      is_valid=true
      break
    fi
  done

  if [ "$is_valid" = false ]; then
    echo "Theme ${theme} is invalid."
    exit 1
  fi
}

###############################################################################
# Gets `color` from xresource.Xresource file from `theme`
# Globals:
#   COLOR_MAP
#   THEME_PATH
# Arguments:
#   color
#   theme
###############################################################################
get_xresource_color () {
  color=$1
  theme=$2

  xresource_color=$(echo "$COLOR_MAP" | sed -n "s/^$color: *//p")
  xresource_file="${THEME_PATH}/${theme}/xresources.Xresources"

  hex_color=$(sed -n "s/^\*$xresource_color: *//p" $xresource_file)

  if [ -z "$hex_color" ]; then
    echo "Color ${xresource_color} not found in ${xresource_file}." >&2
    echo "Returning #ffffff." >&2
    hex_color="#ffffff"
  fi

  echo "$hex_color"

}
# -----------------------------------------------------------------------------

THEME_PATH=$HOME/.config/themes
THEMES=$(load_themes)
COLOR_MAP=$(load_color_map)

usage () {
       printf "Usage:\n"
       printf " -h                               Display this help message.\n"
       printf " -c <color> (required)            Specify which color to get.\n"
       printf " -t <theme> (required)            Specify which theme to use.\n"
       exit 0
}


while getopts c:t:h opt
do
    case "${opt}" in
          h)
            usage
            ;;
          c) color=${OPTARG}
            ;;
          t) theme=${OPTARG}
            ;;
          *)
            printf "Invalid Option: $1.\n"
            usage
            ;;
     esac
done

# mandatory arguments
if [ ! "$color" ] || [ ! "$theme" ]; then
  echo "arguments -c and -t must be provided"
  usage
  exit 1
fi

is_valid_color $color
is_valid_theme $theme

echo "$(get_xresource_color $color $theme)"
