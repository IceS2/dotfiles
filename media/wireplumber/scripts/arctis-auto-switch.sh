#!/bin/bash
# Auto-switch audio between Arctis 7+ and the soundbar (S/PDIF) based on the
# headset POWER state.
#
# Switching is EDGE-TRIGGERED on the headset power signal (headsetcontrol),
# NOT on PipeWire node presence. The Arctis sink node idle-suspends and is
# recreated (new node id) constantly while the headset stays powered on;
# treating that as a connect/disconnect produced phantom off->on edges that
# stomped manual sink selection (e.g. moving to the soundbar). headsetcontrol
# is the reliable signal for "is the headset actually powered on".
#
# THE POWER SIGNAL IS TRI-STATE (see classify_status): on | off | unknown.
#   - on   = BATTERY_AVAILABLE or BATTERY_CHARGING. Charging is NOT off — the
#            old code grepped only "BATTERY_AVAILABLE", so a headset on the
#            charger read as powered-off and audio was dragged to the soundbar.
#   - off  = BATTERY_UNAVAILABLE (level -1): the genuine power-off signal.
#   - unknown = HID error / no device / empty query. Held as "no news"; never
#            counted as off (doing so manufactured phantom power-off edges).
#
# DEBOUNCING: even within a single state the query occasionally returns a
# transient opposite reading. DEBOUNCE_SAMPLES consecutive opposite readings
# are required before the tracked state flips.
#
# MANUAL SELECTION IS SACRED: audio is moved ONLY on a confirmed power edge
# (on→headset, off→soundbar), each as a one-shot. There is no steady-state
# reconcile, so a manual sink change between edges is never overridden. The
# one exception is startup: a fresh start adopts the current state non-
# grabbing when ON (never steal across a restart), and when OFF reconciles a
# stale default to the soundbar exactly once.
#
# Requires: headsetcontrol, jq, pw-dump (pipewire), wpctl, pactl

set -euo pipefail

readonly CHECK_INTERVAL=3
readonly DEBOUNCE_SAMPLES=3
readonly ARCTIS_SINK="alsa_output.usb-SteelSeries_Arctis_7_-00.analog-stereo"
readonly ARCTIS_SOURCE="alsa_input.usb-SteelSeries_Arctis_7_-00.mono-fallback"
readonly CHATMIX_GAME_SINK="Arctis_Game"   # virtual sink from the ChatMix daemon (if running)
readonly SPDIF_SINK="alsa_output.usb-Generic_USB_Audio-00.HiFi__SPDIF__sink"
readonly USB_MIC="alsa_input.usb-Generic_USB_Audio-00.HiFi__Mic__source"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ── Power signal ──
# classify_status: pure map from headsetcontrol's battery-status enum to the
# tri-state the machine consumes. BATTERY_CHARGING is "on" — the headset is
# present and powered, it just happens to be on the cable; reading it as "off"
# (the old literal grep "BATTERY_AVAILABLE" did) dragged audio to the soundbar
# while the headset charged. Only BATTERY_UNAVAILABLE (level -1) means the
# headset is genuinely off. Anything else — HID error, no device, empty — is
# "unknown": a transient read failure we must NOT mistake for a power-off.
classify_status() {
    case "$1" in
        BATTERY_AVAILABLE|BATTERY_CHARGING) echo "on" ;;
        BATTERY_UNAVAILABLE)                echo "off" ;;
        *)                                  echo "unknown" ;;
    esac
}

# ── I/O wrappers (overridden by the test harness) ──
get_node_id() { pw-dump 2>/dev/null | jq -r ".[] | select(.info.props.\"node.name\" == \"$1\") | .id"; }
# read_power_state: echoes on|off|unknown. A failed/empty query yields "unknown".
read_power_state() {
    classify_status "$(headsetcontrol -o json 2>/dev/null | jq -r '.devices[0].battery.status // empty' 2>/dev/null)"
}
get_battery() { headsetcontrol -b 2>/dev/null | grep "Level:" | awk '{print $2}'; }
set_default() { wpctl set-default "$1" 2>/dev/null || true; }
get_default_sink_name() { pactl get-default-sink 2>/dev/null || true; }
move_all_streams() {
    local target_sink="$1"
    pactl list sink-inputs short 2>/dev/null | awk '{print $1}' | while read -r stream; do
        pactl move-sink-input "$stream" "$target_sink" 2>/dev/null || true
    done
}

# Effective Arctis output: prefer the ChatMix virtual "Game" sink when the
# ChatMix daemon is running (so the dial works), else the raw headset sink.
# Echoes "<sink_name> <node_id>", or empty string if no Arctis node exists yet.
resolve_arctis_target() {
    local id
    id=$(get_node_id "$CHATMIX_GAME_SINK")
    if [[ -n "$id" ]]; then echo "$CHATMIX_GAME_SINK $id"; return 0; fi
    id=$(get_node_id "$ARCTIS_SINK")
    if [[ -n "$id" ]]; then echo "$ARCTIS_SINK $id"; return 0; fi
    echo ""
}

# Route to the headset. Returns 1 (and does nothing) if the Arctis node is not
# present yet — caller keeps the "pending" flag and retries next cycle so the
# switch lands exactly once when the node appears.
switch_to_headset() {
    local out sink id src
    out=$(resolve_arctis_target)
    [[ -z "$out" ]] && return 1
    read -r sink id <<<"$out"
    log "→ Headset powered ON (power edge) — routing to $sink ($(get_battery))"
    set_default "$id"
    src=$(get_node_id "$ARCTIS_SOURCE")
    [[ -n "$src" ]] && set_default "$src"
    move_all_streams "$sink"
    return 0
}

# Route to the soundbar (S/PDIF). Returns 1 (and does nothing) if the SPDIF
# node is not present yet — at login PipeWire may not have enumerated the
# Generic USB Audio card (default sink is the dummy 'auto_null'), so the caller
# keeps a "pending" flag and retries next cycle so the switch lands exactly
# once when the node appears.
switch_to_soundbar() {
    local id mic
    id=$(get_node_id "$SPDIF_SINK")
    [[ -z "$id" ]] && return 1
    log "→ Headset powered OFF — routing to soundbar (S/PDIF)"
    set_default "$id"
    mic=$(get_node_id "$USB_MIC")
    [[ -n "$mic" ]] && set_default "$mic"
    move_all_streams "$SPDIF_SINK"
    return 0
}

# ── State machine ──
# Audio moves ONLY on a confirmed power EDGE: the headset powering on routes to
# the headset, powering off routes to the soundbar. Between edges the script
# never touches the default sink, so a manual selection is always respected —
# this is the whole point. There is deliberately NO steady-state reconcile (the
# ChatMix daemon no longer hijacks the default, so nothing needs stomping).
#
# LAST_POWER:     "init" (nothing adopted yet) | "on" | "off"
# PENDING_ON:     1 when a switch-to-headset is owed (Arctis node not ready yet)
# PENDING_OFF:    1 when a switch-to-soundbar is owed (SPDIF node not ready yet)
# DEBOUNCE_COUNT: consecutive readings that disagree with LAST_POWER
LAST_POWER="init"
PENDING_ON=0
PENDING_OFF=0
DEBOUNCE_COUNT=0

tick() {
    local raw cur
    raw=$(read_power_state)   # on | off | unknown

    if [[ "$raw" == "unknown" ]]; then
        # No reliable reading this cycle — hold the last known state and decide
        # nothing. A read failure must never masquerade as a power-off.
        cur="$LAST_POWER"
        if [[ "$cur" == "init" ]]; then return 0; fi   # nothing real adopted yet
    elif [[ "$LAST_POWER" == "init" ]]; then
        # First real reading: adopt it. Startup is NON-GRABBING when ON (never
        # steal a manually-selected sink across a service/wireplumber restart).
        # When OFF, the soundbar is the only valid output, so reconcile a stale
        # default ONCE (deferred via PENDING_OFF if the SPDIF node isn't up yet).
        log "Started — headset is $raw; adopting state (non-grabbing on ON)"
        cur="$raw"; LAST_POWER="$raw"; DEBOUNCE_COUNT=0
        if [[ "$cur" == "off" ]]; then PENDING_OFF=1; fi
    elif [[ "$raw" == "$LAST_POWER" ]]; then
        cur="$raw"; DEBOUNCE_COUNT=0
    else
        # Disagreement — require DEBOUNCE_SAMPLES consecutive opposite readings
        # before believing a flip. NOTE: `$(( … + 1 ))` not `((x++))` — the
        # post-increment returns exit 1 when the prior value is 0 and trips
        # `set -euo pipefail`.
        DEBOUNCE_COUNT=$(( DEBOUNCE_COUNT + 1 ))
        if [[ $DEBOUNCE_COUNT -ge $DEBOUNCE_SAMPLES ]]; then
            log "Power flip to '$raw' confirmed after $DEBOUNCE_COUNT readings"
            cur="$raw"; DEBOUNCE_COUNT=0
            # Confirmed EDGE — arm the matching one-shot switch.
            if [[ "$raw" == "on" ]]; then PENDING_ON=1; PENDING_OFF=0
            else                          PENDING_OFF=1; PENDING_ON=0; fi
        else
            cur="$LAST_POWER"   # blip — ignore
        fi
    fi

    # Execute at most one owed switch. Each is one-shot (cleared on success) and
    # retries while its target node is still absent (login/suspend races). Once
    # it lands it never re-fires until the next edge — no manual override.
    if [[ "$cur" == "on" && "$PENDING_ON" == "1" ]]; then
        if switch_to_headset; then PENDING_ON=0; fi
    elif [[ "$cur" == "off" && "$PENDING_OFF" == "1" ]]; then
        if [[ "$(get_default_sink_name)" == "$SPDIF_SINK" ]]; then
            PENDING_OFF=0                      # already on the soundbar — nothing to do
        elif switch_to_soundbar; then
            PENDING_OFF=0
        fi                                     # else SPDIF node absent → retry next tick
    fi

    LAST_POWER="$cur"
    return 0
}

# When sourced for testing, stop here (functions defined, no loop).
if [[ "${__TEST__:-0}" != "1" ]]; then
    command -v headsetcontrol &>/dev/null || { log "ERROR: headsetcontrol not found"; exit 1; }
    log "Arctis power-edge auto-switch starting (non-grabbing init)"
    while true; do
        tick
        sleep "$CHECK_INTERVAL"
    done
fi
