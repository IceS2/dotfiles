#!/bin/bash
# Auto-switch audio between Arctis 7+ and S/PDIF based on headset power state
# Requires: headsetcontrol, jq

set -euo pipefail

# Configuration
readonly CHECK_INTERVAL=3
readonly ARCTIS_SINK="alsa_output.usb-SteelSeries_Arctis_7_-00.analog-stereo"
readonly ARCTIS_SOURCE="alsa_input.usb-SteelSeries_Arctis_7_-00.mono-fallback"
readonly SPDIF_SINK="alsa_output.usb-Generic_USB_Audio-00.HiFi__SPDIF__sink"
readonly USB_MIC="alsa_input.usb-Generic_USB_Audio-00.HiFi__Mic__source"

# Functions
get_node_id() { pw-dump 2>/dev/null | jq -r ".[] | select(.info.props.\"node.name\" == \"$1\") | .id"; }
is_headset_on() { headsetcontrol -b 2>/dev/null | grep -q "BATTERY_AVAILABLE"; }
get_battery() { headsetcontrol -b 2>/dev/null | grep "Level:" | awk '{print $2}'; }
log() { echo "[$(date '+%H:%M:%S')] $*"; }
move_all_streams() {
    local target_sink="$1"
    pactl list sink-inputs short | awk '{print $1}' | while read -r stream; do
        pactl move-sink-input "$stream" "$target_sink" 2>/dev/null || true
    done
}
wait_for_node() {
    local node_name="$1"
    local max_attempts=20
    local attempt=1
    log "Waiting for $node_name to appear..." >&2
    while [[ $attempt -le $max_attempts ]]; do
        local node_id=$(get_node_id "$node_name")
        if [[ -n "$node_id" ]]; then
            log "✓ Found $node_name (ID: $node_id) after ${attempt}s" >&2
            echo "$node_id"
            return 0
        fi
        sleep 1
        ((attempt++))
    done
    log "✗ Timeout waiting for $node_name after ${max_attempts}s" >&2
    return 1
}

# Initialize
command -v headsetcontrol &>/dev/null || { log "ERROR: headsetcontrol not found"; exit 1; }

# Wait for SPDIF device to be ready (always connected, should always exist)
SPDIF_SINK_ID=$(wait_for_node "$SPDIF_SINK")
if [[ -z "$SPDIF_SINK_ID" ]]; then
    log "FATAL: SPDIF device never appeared. Exiting."
    exit 1
fi

# Wait for USB mic to be ready (same device as SPDIF)
USB_MIC_ID=$(wait_for_node "$USB_MIC")

# Check for Arctis (may or may not be connected)
log "Checking for Arctis headset..."
ARCTIS_SINK_ID=$(get_node_id "$ARCTIS_SINK")
ARCTIS_SOURCE_ID=$(get_node_id "$ARCTIS_SOURCE")

# Handle missing Arctis device (not connected at boot)
if [[ -z "$ARCTIS_SINK_ID" ]]; then
    PREV="off"
    log "Started - Arctis NOT FOUND (disconnected/off)"
    log "→ Setting S/PDIF as default (S/PDIF: $SPDIF_SINK_ID)"
    [[ -n "$SPDIF_SINK_ID" ]] && wpctl set-default "$SPDIF_SINK_ID"
    [[ -n "$USB_MIC_ID" ]] && wpctl set-default "$USB_MIC_ID"
    [[ -n "$SPDIF_SINK" ]] && move_all_streams "$SPDIF_SINK"
else
    # Arctis exists - detect initial state and set devices accordingly
    if is_headset_on; then
        PREV="on"
        log "Started (Arctis: $ARCTIS_SINK_ID, S/PDIF: $SPDIF_SINK_ID) - Initial: ON ($(get_battery))"
        log "→ Setting Arctis as default"
        wpctl set-default "$ARCTIS_SINK_ID"
        [[ -n "$ARCTIS_SOURCE_ID" ]] && wpctl set-default "$ARCTIS_SOURCE_ID"
        move_all_streams "$ARCTIS_SINK"
    else
        PREV="off"
        log "Started (Arctis: $ARCTIS_SINK_ID, S/PDIF: $SPDIF_SINK_ID) - Initial: OFF"
        log "→ Setting S/PDIF as default"
        [[ -n "$SPDIF_SINK_ID" ]] && wpctl set-default "$SPDIF_SINK_ID"
        [[ -n "$USB_MIC_ID" ]] && wpctl set-default "$USB_MIC_ID"
        [[ -n "$SPDIF_SINK" ]] && move_all_streams "$SPDIF_SINK"
    fi
fi

# Monitor loop
while sleep "$CHECK_INTERVAL"; do
    # Refresh node IDs in case devices appeared/disappeared
    ARCTIS_SINK_ID=$(get_node_id "$ARCTIS_SINK")
    ARCTIS_SOURCE_ID=$(get_node_id "$ARCTIS_SOURCE")
    SPDIF_SINK_ID=$(get_node_id "$SPDIF_SINK")
    USB_MIC_ID=$(get_node_id "$USB_MIC")

    # Skip headset check if Arctis device doesn't exist
    if [[ -z "$ARCTIS_SINK_ID" ]]; then
        # Arctis not found - ensure S/PDIF is default
        if [[ "$PREV" != "off" ]]; then
            log "→ Arctis DISCONNECTED - S/PDIF ID: $SPDIF_SINK_ID"
            [[ -n "$SPDIF_SINK_ID" ]] && wpctl set-default "$SPDIF_SINK_ID"
            [[ -n "$USB_MIC_ID" ]] && wpctl set-default "$USB_MIC_ID"
            [[ -n "$SPDIF_SINK" ]] && move_all_streams "$SPDIF_SINK"
        fi
        PREV="off"
        continue
    fi

    # Arctis exists - check power state
    if is_headset_on; then
        if [[ "$PREV" == "off" ]]; then
            log "→ Arctis ON ($(get_battery)) - Sink ID: $ARCTIS_SINK_ID - Moving all streams"
            wpctl set-default "$ARCTIS_SINK_ID"
            [[ -n "$ARCTIS_SOURCE_ID" ]] && wpctl set-default "$ARCTIS_SOURCE_ID"
            sleep 0.5  # Brief delay to let default sink change
            move_all_streams "$ARCTIS_SINK"
        fi
        PREV="on"
    else
        if [[ "$PREV" == "on" ]]; then
            log "→ Arctis OFF - S/PDIF ID: $SPDIF_SINK_ID - Moving all streams"
            [[ -n "$SPDIF_SINK_ID" ]] && wpctl set-default "$SPDIF_SINK_ID"
            [[ -n "$USB_MIC_ID" ]] && wpctl set-default "$USB_MIC_ID"
            sleep 0.5  # Brief delay to let default sink change
            [[ -n "$SPDIF_SINK" ]] && move_all_streams "$SPDIF_SINK"
        fi
        PREV="off"
    fi
done
