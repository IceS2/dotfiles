#!/usr/bin/env bash
# PokerStars.es under Wine, managed by Lutris (system wine, native Wayland)
#
# Downloads the OFFICIAL Windows client, refuses to continue unless it carries a
# valid Authenticode signature from PokerStars' real corporate entity, installs
# it into a Wine prefix using SYSTEM wine, then registers it in Lutris and pins
# the runner so Lutris manages it day to day.
#
# The install is done here rather than by Lutris because a Lutris installer
# script cannot be pinned to system wine — it would silently build a Proton
# prefix and lose native Wayland. See README.md.
source "$(dirname "$0")/../lib/helpers.sh"

MODULE_DIR="$(cd "$(dirname "$0")" && pwd)"

log_header "PokerStars"

# ── Configuration ─────────────────────────────────────────────────────────────

# Stable entry point on the .es download host. This is a redirector: it 302s to
# PokerStarsInstallES.exe, then 301s to a one-shot tokenised CGI URL. Do NOT
# hardcode the tokenised URL — it is per-request and expires.
#
# NOTE: the redirector is User-Agent gated. With a Linux UA it bounces back to
# the HTML download page and you get HTML instead of the binary.
DOWNLOAD_URL="https://download.pokerstars.es/poker/client/download/"
WINDOWS_UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'

# Every host the download is permitted to land on. Verified present in the SAN
# list of the official certs (DigiCert for www.*, Amazon/CloudFront for
# download.*). A redirect anywhere else aborts the install.
ALLOWED_HOSTS=(
    download.pokerstars.es
    download.pokerstars.com
)

# Lives in ~/Games/ alongside guild-wars-2 / guild-wars, matching the existing
# Lutris convention. Referenced by pokerstars.yml, so keep them in sync.
WINEPREFIX_DIR="$HOME/Games/pokerstars"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/pokerstars"
INSTALLER="$CACHE_DIR/PokerStarsInstallES.exe"

# ── Dependency checks ─────────────────────────────────────────────────────────

missing=()
command -v wine         &>/dev/null || missing+=("wine-staging")
command -v lutris       &>/dev/null || missing+=("lutris")
command -v curl         &>/dev/null || missing+=("curl")
command -v osslsigncode &>/dev/null || missing+=("osslsigncode  (AUR)")

if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing dependencies: ${missing[*]}"
    log_error "Install them first:"
    log_error "  paru -S wine-staging lutris osslsigncode"
    exit 1
fi

log_ok "Dependencies present (wine $(wine --version 2>/dev/null))"

# Wine prompts to download Mono/Gecko into every new prefix unless the distro
# packages are present. Arch ships both, and Wine picks them up from
# /usr/share/wine/{mono,gecko} — shared across prefixes and updated by pacman,
# which is what the Wine dialog itself recommends over its per-prefix download.
wine_runtime_missing=()
pacman -Q wine-mono  &>/dev/null || wine_runtime_missing+=("wine-mono")
pacman -Q wine-gecko &>/dev/null || wine_runtime_missing+=("wine-gecko")

if [[ ${#wine_runtime_missing[@]} -gt 0 ]]; then
    log_error "Missing Wine runtime packages: ${wine_runtime_missing[*]}"
    log_error "Without them Wine pops a 'could not find wine-mono/gecko' download"
    log_error "prompt while creating the prefix. Install the distro packages:"
    log_error "  sudo pacman -S ${wine_runtime_missing[*]}"
    log_error "Then re-run ./pokerstars/install.sh"
    exit 1
fi
log_ok "wine-mono + wine-gecko present (no download prompts)"

# Native Wayland is the whole reason this bypasses Lutris. Verify up front.
if ! ls /usr/lib/wine/*/winewayland.drv &>/dev/null; then
    log_warn "System wine has no winewayland.drv — the client will use XWayland."
    log_warn "Install wine-staging (11.x) for native Wayland."
else
    log_ok "winewayland.drv present (i386 + x86_64) — native Wayland available"
fi

# ── 1. Download the installer from the pinned official host ───────────────────

ensure_dir "$CACHE_DIR"

if [[ -f "$INSTALLER" ]]; then
    log_skip "Installer already downloaded: $INSTALLER"
else
    log_info "Downloading from $DOWNLOAD_URL"

    # --proto '=https' + default cert checking: fails closed on a bad TLS cert.
    effective_url="$(curl -fsSL \
        --proto '=https' --tlsv1.2 \
        --max-redirs 8 \
        -A "$WINDOWS_UA" \
        -o "$INSTALLER.part" \
        -w '%{url_effective}' \
        "$DOWNLOAD_URL")" || {
            log_error "Download failed."
            rm -f "$INSTALLER.part"
            exit 1
        }

    # Confirm we landed on an approved host and not an unexpected redirect.
    landed_host="$(sed -E 's#^https://([^/]+).*#\1#' <<<"$effective_url")"
    if ! printf '%s\n' "${ALLOWED_HOSTS[@]}" | grep -qxF "$landed_host"; then
        log_error "Download landed on an UNAPPROVED host: $landed_host"
        log_error "Expected one of: ${ALLOWED_HOSTS[*]}"
        rm -f "$INSTALLER.part"
        exit 1
    fi
    log_ok "Redirect chain terminated on approved host: $landed_host"

    # Reject HTML error pages masquerading as a download.
    if ! file -b "$INSTALLER.part" | grep -q '^PE32'; then
        log_error "Downloaded file is not a Windows executable:"
        log_error "  $(file -b "$INSTALLER.part")"
        log_error "  (usually means the User-Agent gate returned the HTML page)"
        rm -f "$INSTALLER.part"
        exit 1
    fi

    mv "$INSTALLER.part" "$INSTALLER"
    log_ok "Downloaded: $INSTALLER"
fi

# ── 2. Verify the Authenticode signature (HARD GATE) ──────────────────────────

log_info "Verifying Authenticode signature..."

if ! "$MODULE_DIR/verify-installer.sh" "$INSTALLER"; then
    log_error "SIGNATURE VERIFICATION FAILED — refusing to run the installer."
    log_error "The cached file may be corrupt or tampered with. Remove it and retry:"
    log_error "  rm -f '$INSTALLER' && ./pokerstars/install.sh"
    exit 1
fi

# ── 3. Wine prefix ────────────────────────────────────────────────────────────

export WINEPREFIX="$WINEPREFIX_DIR"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:--all}"

if [[ -f "$WINEPREFIX_DIR/system.reg" ]]; then
    log_skip "Wine prefix exists: $WINEPREFIX_DIR"
else
    log_info "Creating Wine prefix: $WINEPREFIX_DIR"
    ensure_dir "$(dirname "$WINEPREFIX_DIR")"
    wineboot --init >/dev/null 2>&1
    log_ok "Wine prefix created"
fi

# Prefer the native Wayland driver, keep X11 as fallback. Wine loads the first
# driver in the list that initialises, so the launcher can switch between them
# by hiding DISPLAY or WAYLAND_DISPLAY — no registry edit needed.
wine reg add 'HKCU\Software\Wine\Drivers' /v Graphics /d 'wayland,x11' /f >/dev/null 2>&1
log_ok "Graphics driver: wayland (fallback x11)"

# ── 4. Run the installer ──────────────────────────────────────────────────────

CLIENT_EXE="$WINEPREFIX_DIR/drive_c/Program Files (x86)/PokerStars.ES/PokerStars.exe"

if [[ -f "$CLIENT_EXE" ]]; then
    log_skip "PokerStars client already installed"
else
    log_info "Launching the PokerStars installer (GUI — click through it)"
    log_info "  • If it offers to install Microsoft Edge WebView2: DECLINE for now."
    log_info "    The bootstrapper hangs under Wine. See README for the working route."
    wine "$INSTALLER" || log_warn "Installer exited non-zero (often harmless)"

    if [[ -f "$CLIENT_EXE" ]]; then
        log_ok "Client installed: $CLIENT_EXE"
    else
        log_warn "Client not found at the expected path:"
        log_warn "  $CLIENT_EXE"
        log_warn "If you chose a custom install location, update pokerstars.sh"
    fi
fi

# ── 5. Register in Lutris ─────────────────────────────────────────────────────
#
# Registration only — pokerstars.yml has no installer tasks, so Lutris runs
# nothing and cannot fall back to Proton. It just adds the game to the library.

if sqlite3 "$HOME/.local/share/lutris/pga.db" \
       "select 1 from games where slug='pokerstars';" 2>/dev/null | grep -q 1; then
    log_skip "Already registered in Lutris"
else
    log_info "Registering the game in Lutris"
    lutris --install "$MODULE_DIR/pokerstars.yml"
fi

# ── 6. Pin the runner to System wine ──────────────────────────────────────────
#
# GAME-level config, checked before the runner-level default, so this overrides
# the global GE-Proton default for PokerStars only — Guild Wars 1/2 unaffected.

if ! "$MODULE_DIR/pin-runner.sh"; then
    log_warn "Could not pin the runner yet."
    log_warn "Once PokerStars appears in your Lutris library, run:"
    log_warn "  ./pokerstars/pin-runner.sh"
    exit 1
fi

log_ok "PokerStars installed, registered in Lutris, pinned to System wine"
log_info "Restart Lutris to pick up the change, then launch from your library."
