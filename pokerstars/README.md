# PokerStars (Wine)

PokerStars.es real-money client in a dedicated Wine prefix, running on **native
Wayland** under Hyprland/NVIDIA.

PokerStars has no native Linux client and no plans for one — but they
**officially recommend Wine** in their own help article. Wine is a compatibility
layer running their unmodified official client, so it is *not* covered by their
prohibited-software policy (which targets bots, HUDs on shared databases,
RTA/solvers, datamining, and hole-card sharing). There is no ban risk from Wine
itself.

## Install

```bash
paru -S wine-staging osslsigncode   # osslsigncode is required, not optional
./pokerstars/install.sh
```

Then launch with `pokerstars`, or from the app launcher.

## Why not Lutris

This was tried and abandoned for concrete reasons. Recording them so it isn't
re-attempted:

1. **The Lutris community scripts are dead.** The World script fetches
   `pokerstars.net/PokerStarsInstallPM.exe` → **404**. The EU script fetches
   `www.pokerstars-03.eu/...` → **domain does not resolve**. An expired domain in
   an install script is exactly how you get served a trojaned binary.
2. **Lutris' runners cannot do native Wayland.** Its bundled `wine-ge-8-26`
   ships **zero** `winewayland.drv`, and `ge-proton`/`umu` are built around
   XWayland. Only System `wine-staging` has the driver.
3. **The runner cannot be pinned from an installer script.** Setting
   `wine: version: system` fails the install outright:

   ```
   RunnerInstallationError: Failed to retrieve wine (system-x86_64) information
   ```

   Lutris pushes script-specified versions through
   `api.py::normalize_version_architecture()`, which unconditionally appends the
   arch → `"system-x86_64"`. `WINE_PATHS` keys the system build as the bare
   string `"system"`, so the lookup misses and Lutris tries to *download* a
   runner that does not exist.
4. **Omitting the version silently falls back to Proton.** With no version set,
   the install inherits the global default (GE-Proton) and builds a *Proton*
   prefix — `pfx/`, `version`, `tracked_files` — confirmed by
   `Proton: Executable is a unix path, launching with 'umu.exe'` in the Lutris
   log. Wrong runner, no Wayland.

Fixing this properly would mean changing the **global** Lutris Wine default,
which would also change Guild Wars 1 (it has no game-level runner set; GW2 does,
so GW2 is unaffected). Not worth disturbing working games for a non-game app —
hence a standalone prefix.

## Graphics: native Wayland

Verified against the installed `wine-staging 11.13`:

```
/usr/lib/wine/i386-windows/winewayland.drv     ← client is 32-bit, so this one matters
/usr/lib/wine/x86_64-windows/winewayland.drv
```

The two blockers in older bug threads are both **resolved** on this version:

| Old problem | Status on wine-staging 11.13 |
|---|---|
| Blank login window — missing `dcomp.dll.DCompositionCreateDevice3` | **Fixed.** `DCompositionCreateDevice`, `…2` and `…3` are all exported by both the 32- and 64-bit `dcomp.dll`. |
| Wayland driver too immature | **Largely fixed.** Wayland is the default driver since Wine 10.0; Wine 11.11 added layered-window support, which is what poker table overlays and transparency use. |

The prefix registry is set to `Graphics = "wayland,x11"` — prefer Wayland, keep
X11 as fallback. Wine loads the first driver that initialises, so the launcher
switches by hiding one env var:

```bash
pokerstars                      # native Wayland (default) — unsets DISPLAY
POKERSTARS_GFX=x11 pokerstars   # XWayland fallback      — unsets WAYLAND_DISPLAY
```

### Confirm which driver is live

Hyprland reports XWayland status per window, so this is definitive:

```bash
hyprctl clients -j | jq -r '.[] | select(.class|test("(?i)pokerstars")) | {class, xwayland}'
```

`"xwayland": false` → native Wayland. `true` → it fell back.

### The one real trade-off: window positioning

**Wayland does not let applications set their own absolute window position** —
protocol design, not a Wine bug. Wine fakes it for transient windows (menus,
tooltips, dialogs), but a top-level window calling `SetWindowPos` cannot be
honoured.

For poker this is not academic: **multi-tabling relies on the client arranging
tables in a grid.** Under native Wayland, Hyprland places the table windows
instead, so the client's own tiling/cascade options will not work as designed.

- **Let Hyprland place them** — find the window class once a table is open:
  ```bash
  hyprctl clients -j | jq -r '.[] | select(.class|test("(?i)pokerstars")) | {class,title,at,size}'
  ```
  then add rules to `hypr/configs/windowrules.conf`.
- **Or fall back** with `POKERSTARS_GFX=x11`, where the client's own table
  arrangement works normally.

Single-tabling → native Wayland is strictly better (no XWayland scaling blur,
correct HiDPI). Heavy multi-tabling → try Wayland, keep the `x11` toggle handy.

## Microsoft Edge WebView2

The installer offers to download WebView2. **Decline it during install.**

PokerStars renders its web content through WebView2 — most importantly the
**Cashier** (deposits/withdrawals). The poker tables themselves are native, so
declining costs you banking inside the client, not play.

Two installers exist, and the difference matters under Wine:

| Installer | Size | Under Wine |
|---|---|---|
| **Evergreen Bootstrapper** (`MicrosoftEdgeWebview2Setup.exe`) | 1.7 MB | ✗ What the client invokes. Downloads, then **hangs ~an hour and fails** — the widely reported failure mode. |
| **Evergreen Standalone** (`MicrosoftEdgeWebView2RuntimeInstallerX64.exe`) | 194 MB | ✓ Fully offline, nothing to fetch mid-install. The route that works. |

If you want to attempt it (both URLs verified live and official):

```bash
# Standalone runtime, straight from Microsoft
curl -fL -o /tmp/webview2.exe 'https://go.microsoft.com/fwlink/?linkid=2124701'

# Same trust standard as the client — expect signer "Microsoft Corporation"
osslsigncode verify -CAfile /etc/ssl/certs/ca-certificates.crt -in /tmp/webview2.exe

export WINEPREFIX=~/.local/share/wineprefixes/pokerstars
winecfg                      # set Windows version to 10 or 11 first
wine /tmp/webview2.exe
```

Reality check: WebView2 on Wine is reported as *functional but erratic* even
when it installs. Microsoft does not support Linux and has an open upstream
Proton/Wine issue. `winetricks` has **no** `webview2` verb, so this is manual.

**Recommended:** skip it and do deposits/withdrawals on the PokerStars website in
a normal browser. That avoids WebView2 entirely.

## How we know the client is genuine

The obvious approaches are all weak:

| Approach | Why it fails |
|---|---|
| Lutris community scripts | Dead URLs (see above) — one domain no longer resolves at all. |
| "Checksum" sites (exedb, pconlife) | Unaccountable SEO file-info sites, hashes for unknown builds, and MD5 is broken for tamper detection. |
| Official published checksums | PokerStars doesn't publish any. |

Instead, four independent layers:

**1. Pin the download to a host proven official via TLS.**

```
www.pokerstars.net      → O=TSG INTERACTIVE SERVICES LIMITED, C=IM, L=Onchan
                          issuer: DigiCert Global G2 TLS RSA SHA256 2020 CA1
download.pokerstars.es  → CN=download.pokerstars.com (SAN covers .es)
                          issuer: Amazon RSA 2048 M04  (CloudFront)
```

The `www` cert's SAN list is effectively PokerStars declaring which domains are
theirs — `pokerstars.com/.net/.es/.pt/.de/.fr/...` plus numbered mirrors
`pokerstars-01.com` … `-10.com`. Note `www.pokerstars-03.eu` (the dead Lutris
URL) is **absent**, while `www.pokerstars-03.com` **is** present.

`install.sh` allowlists the landing host and aborts on an unexpected redirect.

**2. TLS verification on download** — `curl --proto '=https'`, fails closed.

**3. Authenticode signature — the one that actually proves it.**

```
signer: C=IM, L=Onchan, O=TSG INTERACTIVE SERVICES LIMITED,
        CN=TSG INTERACTIVE SERVICES LIMITED
issuer: DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA1
  root: DigiCert Trusted Root G4   (+ RFC3161 timestamped)
```

`TSG INTERACTIVE SERVICES LIMITED` is the real PokerStars entity — The Stars
Group, now Flutter, registered in Onchan, Isle of Man.

The strong part: **two independent PKI paths — the TLS cert and the code-signing
cert — both attest to the same Isle of Man entity.** Cross-corroboration a
checksum can never give you.

`verify-installer.sh` **pins the publisher**, so a validly signed binary from
another company still fails. "Is it signed?" alone is not enough.

**4. Digest match.** `osslsigncode` is required rather than just reading the
certificate out of the PE, because it also verifies the signature's message
digest against the actual file bytes. Without that, an attacker could staple a
genuine cert blob onto a modified binary.

Verification is a **hard gate** — `install.sh` refuses to run the installer if
any layer fails.

Verify manually any time:

```bash
./pokerstars/verify-installer.sh ~/.cache/pokerstars/PokerStarsInstallES.exe
```

## Files

| File | Purpose |
|---|---|
| `install.sh` | Download → verify → prefix → install → link launcher |
| `verify-installer.sh` | Standalone Authenticode verification (the security core) |
| `pokerstars.sh` | Launcher (`~/.local/bin/pokerstars`), Wayland/X11 toggle |
| `pokerstars.desktop` | Desktop entry |

Prefix: `~/.local/share/wineprefixes/pokerstars`
Installer cache: `~/.cache/pokerstars/`
