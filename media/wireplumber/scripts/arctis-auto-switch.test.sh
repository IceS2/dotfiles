#!/bin/bash
# Regression tests for arctis-auto-switch.sh decision logic.
#
# S1 is the original failure observed in the service journal: the headset
# stays powered ON while the Arctis PipeWire node idle-suspends and is
# recreated — the old logic treated that as disconnect→reconnect and force-
# moved all streams back to the headset, stomping a manual soundbar selection.
# S1 must result in NO audio movement.
#
# S11/S12 cover the bugs reported on 2026-05-30:
#   S11: manual default selection is sacred — a mid-session default change
#        while the headset is off must NOT be overridden. (Inverts the old
#        every-tick reconcile: the ChatMix daemon no longer touches the
#        default, so nothing legitimately needs stomping anymore.)
#   S12: transient blip in the power reading while the headset is actually
#        on must NOT flip the tracked state (debouncing).
#   S15: an "unknown"/unreadable power reading holds the last state instead
#        of being miscounted as "off" (which manufactured phantom edges).
#   T:   classify_status maps the headsetcontrol battery-status enum to
#        on|off|unknown — BATTERY_CHARGING is on, not off (the charger bug).
#
# Run: bash media/wireplumber/scripts/arctis-auto-switch.test.sh

DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
__TEST__=1 source "$DIR/arctis-auto-switch.sh"
set +e +u +o pipefail   # neutralize the sourced script's strict mode for the harness

PASS=0
FAIL=0
ACTIONS=""

# Controlled inputs
POWER="off"          # resolved power reading: on | off | unknown
ARCTIS_PRESENT=0     # whether the Arctis sink node currently exists
SPDIF_PRESENT=1      # whether the soundbar (Generic USB Audio) sink node exists yet
DEFAULT_SINK=""      # node name reported by get_default_sink_name

# POWER is the resolved power reading the script consumes: "on" | "off" |
# "unknown". classify_status (the raw enum→state mapping) is left REAL so its
# own unit tests exercise the actual code.
read_power_state() { echo "$POWER"; }
get_battery() { echo "100%"; }
get_node_id() {
    case "$1" in
        "$ARCTIS_SINK")       [[ "$ARCTIS_PRESENT" == 1 ]] && echo "arctis-id" ;;
        "$CHATMIX_GAME_SINK") [[ "$ARCTIS_PRESENT" == 1 ]] && echo "chatmix-id" ;;
        "$ARCTIS_SOURCE")     [[ "$ARCTIS_PRESENT" == 1 ]] && echo "arctis-src" ;;
        "$SPDIF_SINK")        [[ "$SPDIF_PRESENT" == 1 ]] && echo "spdif-id" ;;
        "$USB_MIC")           [[ "$SPDIF_PRESENT" == 1 ]] && echo "usbmic-id" ;;
    esac
}
# Mirror real wpctl behavior: a successful set-default updates the default sink.
# Sources (mic ids) don't change the sink-name reported by get_default_sink_name.
set_default() {
    ACTIONS+="set_default:$1 "
    case "$1" in
        "spdif-id")   DEFAULT_SINK="$SPDIF_SINK" ;;
        "arctis-id")  DEFAULT_SINK="$ARCTIS_SINK" ;;
        "chatmix-id") DEFAULT_SINK="$CHATMIX_GAME_SINK" ;;
    esac
}
get_default_sink_name() { echo "$DEFAULT_SINK"; }
move_all_streams() { ACTIONS+="move:$1 "; }
log() { :; }

reset_state() {
    LAST_POWER="init"; PENDING_ON=0; PENDING_OFF=0; DEBOUNCE_COUNT=0
    ACTIONS=""; DEFAULT_SINK=""; SPDIF_PRESENT=1; POWER="off"
}

# Tick N times with current inputs.
ticks() { local n=$1; while ((n-- > 0)); do tick; done; }

# Run enough ticks of the current POWER reading to push a flip through the
# debouncer. DEBOUNCE_SAMPLES consecutive opposite readings flip the state.
confirm_flip() { ticks "$DEBOUNCE_SAMPLES"; }

assert_none() {
    local desc="$1" got="$2"
    if [[ -z "${got// /}" ]]; then
        echo "PASS: $desc"; ((PASS++))
    else
        echo "FAIL: $desc — expected NO actions, got: '$got'"; ((FAIL++))
    fi
}
assert_has() {
    local desc="$1" needle="$2" got="$3"
    if [[ "$got" == *"$needle"* ]]; then
        echo "PASS: $desc"; ((PASS++))
    else
        echo "FAIL: $desc — expected '*$needle*', got: '$got'"; ((FAIL++))
    fi
}

assert_eq() {
    local desc="$1" exp="$2" got="$3"
    if [[ "$got" == "$exp" ]]; then
        echo "PASS: $desc"; ((PASS++))
    else
        echo "FAIL: $desc — expected '$exp', got '$got'"; ((FAIL++))
    fi
}

# ── T: classify_status maps the headsetcontrol battery enum → on|off|unknown ──
# The charger bug: BATTERY_CHARGING used to fail the literal grep "BATTERY_AVAILABLE"
# and be read as "off", dragging audio to the soundbar while the headset charged.
assert_eq "T classify BATTERY_AVAILABLE → on"    "on"      "$(classify_status BATTERY_AVAILABLE)"
assert_eq "T classify BATTERY_CHARGING → on"     "on"      "$(classify_status BATTERY_CHARGING)"
assert_eq "T classify BATTERY_UNAVAILABLE → off" "off"     "$(classify_status BATTERY_UNAVAILABLE)"
assert_eq "T classify HID error → unknown"       "unknown" "$(classify_status BATTERY_HIDERROR)"
assert_eq "T classify empty → unknown"           "unknown" "$(classify_status '')"

# ── S1: node suspend/resume while powered ON must NOT move audio ──
reset_state; POWER="on"; ARCTIS_PRESENT=1; DEFAULT_SINK="$CHATMIX_GAME_SINK"
tick                                   # non-grabbing init (headset on)
init_actions="$ACTIONS"; ACTIONS=""
ARCTIS_PRESENT=0; tick                 # Arctis node idle-suspended (vanished)
ARCTIS_PRESENT=1; tick                 # Arctis node recreated (new id)
assert_none "S1 init with headset ON is non-grabbing" "$init_actions"
assert_none "S1 node suspend/resume while powered ON moves nothing" "$ACTIONS"

# ── S2: genuine power off→on edge routes to headset, once ──
reset_state; POWER="off"; ARCTIS_PRESENT=0
tick; ACTIONS=""                       # init adopt: off (may reconcile)
POWER="on"; ARCTIS_PRESENT=1
confirm_flip                           # DEBOUNCE_SAMPLES on-readings to confirm
assert_has "S2 power-on edge routes to headset (Arctis_Game preferred)" "move:$CHATMIX_GAME_SINK" "$ACTIONS"
ACTIONS=""; tick
assert_none "S2 steady ON does not repeat" "$ACTIONS"

# ── S3: genuine power on→off edge routes to soundbar ──
reset_state; POWER="on"; ARCTIS_PRESENT=1; DEFAULT_SINK="$CHATMIX_GAME_SINK"
tick; ACTIONS=""                       # init adopt: on
POWER="off"; ARCTIS_PRESENT=0
confirm_flip
assert_has "S3 power-off edge routes to soundbar" "move:$SPDIF_SINK" "$ACTIONS"

# ── S4: deferred switch — power-on while Arctis node absent, then node appears ──
reset_state; POWER="off"; tick; ACTIONS=""
POWER="on"; ARCTIS_PRESENT=0
confirm_flip                           # edge confirmed but node not ready
assert_none "S4 deferred: no move while Arctis node absent" "$ACTIONS"
ARCTIS_PRESENT=1; tick                 # node now present
assert_has "S4 switches once Arctis node appears" "move:$CHATMIX_GAME_SINK" "$ACTIONS"
ACTIONS=""; tick
assert_none "S4 no repeat after deferred switch" "$ACTIONS"

# ── S5: manual soundbar selection with headset ON is never overridden by steady polling ──
reset_state; POWER="on"; ARCTIS_PRESENT=1; DEFAULT_SINK="$SPDIF_SINK"
tick; ACTIONS=""                       # init adopt on (user has SPDIF default already)
ticks 5                                # 5 poll cycles, headset still on
assert_none "S5 steady ON over many polls never grabs audio" "$ACTIONS"

# ── S6: init with headset OFF + stale Arctis_Game default reconciles to soundbar ──
reset_state; POWER="off"; ARCTIS_PRESENT=0; DEFAULT_SINK="$CHATMIX_GAME_SINK"
tick
assert_has "S6 init OFF with stale Arctis_Game default reconciles" "move:$SPDIF_SINK" "$ACTIONS"

# ── S6b: same with raw Arctis analog-stereo as stale default ──
reset_state; POWER="off"; ARCTIS_PRESENT=0; DEFAULT_SINK="$ARCTIS_SINK"
tick
assert_has "S6b init OFF with stale Arctis analog-stereo default reconciles" "move:$SPDIF_SINK" "$ACTIONS"

# ── S7: init with headset OFF and SPDIF already default is non-grabbing ──
reset_state; POWER="off"; ARCTIS_PRESENT=0; DEFAULT_SINK="$SPDIF_SINK"
tick
assert_none "S7 init OFF with SPDIF already default is non-grabbing" "$ACTIONS"

# ── S8: init with headset ON never reconciles, even if default is non-Arctis ──
reset_state; POWER="on"; ARCTIS_PRESENT=1; DEFAULT_SINK="$SPDIF_SINK"
tick
assert_none "S8 init ON with SPDIF default (user manual) is non-grabbing" "$ACTIONS"

# ── S9: init with headset OFF and any non-SPDIF default reconciles to soundbar ──
reset_state; POWER="off"; ARCTIS_PRESENT=0; DEFAULT_SINK="alsa_output.pci-0000_00_1f.3.hdmi-stereo"
tick
assert_has "S9 init OFF with foreign non-SPDIF default reconciles" "move:$SPDIF_SINK" "$ACTIONS"

# ── S9b: init with headset OFF and empty/unknown default reconciles to soundbar ──
reset_state; POWER="off"; ARCTIS_PRESENT=0; DEFAULT_SINK=""
tick
assert_has "S9b init OFF with empty default reconciles" "move:$SPDIF_SINK" "$ACTIONS"

# ── S10: login race — init OFF wants soundbar but SPDIF node not created yet ──
reset_state; POWER="off"; ARCTIS_PRESENT=0; SPDIF_PRESENT=0; DEFAULT_SINK="auto_null"
tick                                   # init: wants soundbar, node absent → defer
assert_none "S10 init OFF defers while SPDIF node absent" "$ACTIONS"
SPDIF_PRESENT=1; tick                  # node now created
assert_has "S10 routes to soundbar once SPDIF node appears" "move:$SPDIF_SINK" "$ACTIONS"
ACTIONS=""; tick
assert_none "S10 no repeat after deferred soundbar switch" "$ACTIONS"

# ── S11: manual default selection is sacred — never overridden mid-session ──
# The ChatMix daemon was changed to leave default-sink ownership to this script
# (it no longer hijacks the default to Arctis_Game). So the old "reconcile to
# the soundbar every tick while off" behavior is gone: a default change while
# the headset is off — by the user or anything else — must be respected, not
# stomped every 3 seconds. This is the user's core requirement: manual wins.
reset_state; POWER="off"; ARCTIS_PRESENT=0; DEFAULT_SINK="$SPDIF_SINK"
tick; ACTIONS=""                       # init off, SPDIF already default → settles
ARCTIS_PRESENT=1                       # headset sink now exists (e.g. chatmix up)
DEFAULT_SINK="$CHATMIX_GAME_SINK"      # default changes mid-session
ticks 5
assert_none "S11 mid-session default change while OFF is not overridden" "$ACTIONS"

# ── S15: an "unknown"/unreadable power reading holds the last state ──
# headsetcontrol intermittently returns no usable battery status (HID error,
# dongle busy). Counting that as "off" is what manufactured the phantom edges
# that yanked a manual soundbar pick back to the headset. Unknown = no news.
reset_state; POWER="on"; ARCTIS_PRESENT=1; DEFAULT_SINK="$SPDIF_SINK"
tick; ACTIONS=""                       # init on, manual SPDIF default
POWER="unknown"; ticks 5               # a run of unreadable polls
assert_none "S15 unknown readings while ON never act (hold state)" "$ACTIONS"
POWER="on"; tick
assert_none "S15 recovery to ON after unknowns makes no phantom edge" "$ACTIONS"

# ── S12: transient headsetcontrol blip while headset is ON must not switch ──
# headsetcontrol -b intermittently returns no BATTERY_AVAILABLE even when the
# headset's real power state is unchanged. Each blip used to fire a phantom
# on→off→on cycle that stomped a manual soundbar selection (the user's main
# complaint from 2026-05-30). DEBOUNCE_SAMPLES consecutive opposite readings
# are now required before the tracked state flips.
reset_state; POWER="on"; ARCTIS_PRESENT=1; DEFAULT_SINK="$SPDIF_SINK"
tick; ACTIONS=""                       # init on, SPDIF default (user manual)
# Single blip: 1 off reading then back to on.
POWER="off"; tick
assert_none "S12 single off blip while powered ON is filtered" "$ACTIONS"
POWER="on"; tick
assert_none "S12 recovery after single blip stays put" "$ACTIONS"
# Two-tick blip: still below DEBOUNCE_SAMPLES=3.
POWER="off"; ticks 2
assert_none "S12 two-tick blip while powered ON is filtered" "$ACTIONS"
POWER="on"; tick
assert_none "S12 recovery after two-tick blip stays put" "$ACTIONS"

# ── S13: real power-off only registers after DEBOUNCE_SAMPLES consecutive readings ──
reset_state; POWER="on"; ARCTIS_PRESENT=1; DEFAULT_SINK="$CHATMIX_GAME_SINK"
tick; ACTIONS=""                       # init on
POWER="off"; ARCTIS_PRESENT=0
# First DEBOUNCE_SAMPLES-1 off readings are silent.
ticks $((DEBOUNCE_SAMPLES - 1))
assert_none "S13 first $((DEBOUNCE_SAMPLES - 1)) off readings do not switch" "$ACTIONS"
tick                                   # DEBOUNCE_SAMPLES'th — confirms flip
assert_has "S13 confirmed power-off routes to soundbar" "move:$SPDIF_SINK" "$ACTIONS"

# ── S14: tick() does not crash under `set -euo pipefail` ──
# Catches the bash gotcha where `((var++))` returns exit code 1 when the
# pre-increment value is 0, killing the script the first time we increment
# DEBOUNCE_COUNT from 0 to 1. The harness runs with strict mode off, so this
# only reproduces if we re-arm it for the relevant ticks.
reset_state; POWER="on"; ARCTIS_PRESENT=1; DEFAULT_SINK="$CHATMIX_GAME_SINK"
tick                                   # init on
POWER="off"
set -euo pipefail
crash=0
for _ in $(seq 1 $((DEBOUNCE_SAMPLES + 1))); do
    tick || { crash=1; break; }
done
set +e +u +o pipefail
if [[ $crash == 0 ]]; then
    echo "PASS: S14 tick() survives set -euo pipefail across a debounced flip"
    ((PASS++))
else
    echo "FAIL: S14 tick() aborted under set -euo pipefail (likely an arithmetic gotcha)"
    ((FAIL++))
fi

echo "--------"
echo "PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]]
