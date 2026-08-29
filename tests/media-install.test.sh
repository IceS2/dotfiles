#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/bin"

cat > "$TEST_ROOT/bin/sudo" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

cat > "$TEST_ROOT/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
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
