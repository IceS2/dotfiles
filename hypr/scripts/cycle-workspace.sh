#!/usr/bin/env bash
# Cycle through defined workspaces per monitor, including empty ones, with wrapping.
# Usage: cycle-workspace.sh next|prev [--move]

DIRECTION="$1"
MOVE_WINDOW="$2"

# Workspace ranges per monitor (matches workspaces.conf)
declare -A MONITOR_WORKSPACES
MONITOR_WORKSPACES["DP-2"]="1 3 5 7 9"
MONITOR_WORKSPACES["DP-1"]="2 4 6 8 10"

# Get current monitor and workspace
ACTIVE=$(hyprctl activeworkspace -j)
CURRENT_WS=$(echo "$ACTIVE" | jq -r '.id')
CURRENT_MON=$(echo "$ACTIVE" | jq -r '.monitor')

WORKSPACES=(${MONITOR_WORKSPACES[$CURRENT_MON]})
COUNT=${#WORKSPACES[@]}

# Find current index
INDEX=-1
for i in "${!WORKSPACES[@]}"; do
    if [[ "${WORKSPACES[$i]}" == "$CURRENT_WS" ]]; then
        INDEX=$i
        break
    fi
done

# Fallback to first workspace if current isn't in list
if [[ $INDEX -eq -1 ]]; then
    INDEX=0
fi

# Calculate next index with wrapping
if [[ "$DIRECTION" == "next" ]]; then
    INDEX=$(( (INDEX + 1) % COUNT ))
elif [[ "$DIRECTION" == "prev" ]]; then
    INDEX=$(( (INDEX - 1 + COUNT) % COUNT ))
fi

TARGET=${WORKSPACES[$INDEX]}

if [[ "$MOVE_WINDOW" == "--move" ]]; then
    hyprctl dispatch movetoworkspace "$TARGET"
else
    hyprctl dispatch workspace "$TARGET"
fi
