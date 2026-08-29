#!/usr/bin/env bash
# Pin the PokerStars Lutris game to the System wine runner.
#
# Runs AFTER registration, because the game config only exists once Lutris has
# created the game. Idempotent — safe to re-run.
#
# This is GAME-level config, which read_version_from_config() checks BEFORE the
# runner-level default:
#     for level in [self.config.game_level, self.config.runner_level]:
# So it overrides the global GE-Proton default for this game only — Guild Wars 1
# and 2 are unaffected. It is also read verbatim (no arch normalisation), which
# is why "system" works here but not in an installer script.

set -euo pipefail

# Overridable so the pinning logic can be tested against a fixture directory.
GAMES_DIR="${LUTRIS_GAMES_DIR:-$HOME/.local/share/lutris/games}"

_red()   { printf '\033[0;31m%s\033[0m\n' "$*" >&2; }
_green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
_yellow(){ printf '\033[0;33m%s\033[0m\n' "$*"; }

shopt -s nullglob
configs=("$GAMES_DIR"/pokerstars*.yml)
shopt -u nullglob

if [[ ${#configs[@]} -eq 0 ]]; then
    _yellow "No PokerStars game config found in $GAMES_DIR"
    _yellow "Register the game first, then re-run:"
    _yellow "  ./pokerstars/pin-runner.sh"
    exit 1
fi

for cfg in "${configs[@]}"; do
    python3 - "$cfg" <<'PY'
import sys, yaml

path = sys.argv[1]
with open(path) as f:
    d = yaml.safe_load(f) or {}

current = (d.get("wine") or {}).get("version")
if current == "system":
    print(f"[SKIP]  {path} (already pinned to system)")
    sys.exit(0)

d.setdefault("wine", {})["version"] = "system"

with open(path, "w") as f:
    yaml.safe_dump(d, f, default_flow_style=False, sort_keys=True)

was = current or "unset (would inherit the global default = GE-Proton)"
print(f"[OK]    {path}")
print(f"        wine.version: {was} -> system")
PY
done

_green "Runner pinned to System wine (native Wayland capable)."
echo "Restart Lutris if it is running, so the change is picked up."
