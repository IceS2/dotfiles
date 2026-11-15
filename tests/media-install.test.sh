#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
export TEST_ROOT
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/bin"

cat > "$TEST_ROOT/bin/sudo" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat > "$TEST_ROOT/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_ROOT/systemctl.log"
exit 0
EOF

chmod +x "$TEST_ROOT/bin/sudo" "$TEST_ROOT/bin/systemctl"

HOME="$TEST_ROOT/home" \
PATH="$TEST_ROOT/bin:$PATH" \
DOTFILES_DIR="$REPO_ROOT" \
    "$REPO_ROOT/media/install.sh" >/dev/null

test -L "$TEST_ROOT/home/.config/wireplumber/wireplumber.conf.d/10-bluetooth.conf"
test -L "$TEST_ROOT/home/.config/wireplumber/wireplumber.conf.d/50-device-priorities.conf"
test -L "$TEST_ROOT/home/.config/wireplumber/scripts/arctis-auto-switch.sh"
test -L "$TEST_ROOT/home/.config/rescrobbled/config.toml"
test -f "$TEST_ROOT/home/.config/rescrobbled/lastfm-key"
test -f "$TEST_ROOT/home/.config/rescrobbled/lastfm-secret"
test "$(stat -c '%a' "$TEST_ROOT/home/.config/rescrobbled/lastfm-key")" = 600
test "$(stat -c '%a' "$TEST_ROOT/home/.config/rescrobbled/lastfm-secret")" = 600
test ! -e "$TEST_ROOT/home/.config/rescrobbled/session"

HOME="$TEST_ROOT/home" \
PATH="$TEST_ROOT/bin:$PATH" \
DOTFILES_DIR="$REPO_ROOT" \
    "$REPO_ROOT/media/install.sh" --restart >/dev/null

if grep -Fxq -- '--user enable rescrobbled.service' "$TEST_ROOT/systemctl.log"; then
    printf 'empty credentials must not enable rescrobbled\n' >&2
    exit 1
fi

printf '%s\n' 'manual-key' > "$TEST_ROOT/home/.config/rescrobbled/lastfm-key"
printf '%s\n' 'manual-secret' > "$TEST_ROOT/home/.config/rescrobbled/lastfm-secret"

HOME="$TEST_ROOT/home" \
PATH="$TEST_ROOT/bin:$PATH" \
DOTFILES_DIR="$REPO_ROOT" \
    "$REPO_ROOT/media/install.sh" --restart >/dev/null

test "$(<"$TEST_ROOT/home/.config/rescrobbled/lastfm-key")" = 'manual-key'
test "$(<"$TEST_ROOT/home/.config/rescrobbled/lastfm-secret")" = 'manual-secret'
grep -Fxq -- '--user enable rescrobbled.service' "$TEST_ROOT/systemctl.log"
grep -Fxq -- '--user restart rescrobbled.service' "$TEST_ROOT/systemctl.log"
