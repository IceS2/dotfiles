#!/usr/bin/env bash
# Authenticode verification for the PokerStars installer.
#
# This is the security core of the module: it proves the downloaded .exe was
# signed by PokerStars' real corporate entity and that the signature actually
# covers the file's contents. Run standalone on any PE binary:
#
#   ./pokerstars/verify-installer.sh /path/to/PokerStarsInstallES.exe
#
# Exits non-zero on ANY doubt. Callers must treat failure as fatal.

set -euo pipefail

# The Isle of Man entity behind PokerStars (TSG = The Stars Group, now Flutter).
# Cross-corroborated by two independent PKI paths:
#   - TLS cert on www.pokerstars.* : O=TSG INTERACTIVE SERVICES LIMITED (DigiCert)
#   - Authenticode signer on the installer: same O (DigiCert Code Signing G4)
# Pinning the publisher is what makes this meaningful — a valid signature from
# some *other* company must fail, so checking "is it signed" is not enough.
EXPECTED_SIGNER_O="TSG INTERACTIVE SERVICES LIMITED"

CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"

_red()   { printf '\033[0;31m%s\033[0m\n' "$*" >&2; }
_green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
_dim()   { printf '\033[2m%s\033[0m\n' "$*"; }

exe="${1:-}"

if [[ -z "$exe" ]]; then
    _red "usage: verify-installer.sh <installer.exe>"
    exit 2
fi

if [[ ! -f "$exe" ]]; then
    _red "FAIL: no such file: $exe"
    exit 2
fi

if ! command -v osslsigncode &>/dev/null; then
    _red "FAIL: osslsigncode is not installed — cannot verify the signature."
    _red "      Install it first:  paru -S osslsigncode"
    # Hard failure, not a warning: skipping verification would defeat the
    # entire point of this script.
    exit 3
fi

if [[ ! -r "$CA_BUNDLE" ]]; then
    _red "FAIL: CA bundle not readable: $CA_BUNDLE"
    exit 3
fi

echo "Verifying: $exe"
echo "  size:    $(stat -c%s "$exe") bytes"
echo "  sha256:  $(sha256sum "$exe" | cut -d' ' -f1)"
echo

# osslsigncode checks BOTH that the chain is valid AND that the signature's
# message digest matches the actual file bytes. The digest match is why we use
# it rather than just parsing the certificate out of the PE — a tampered binary
# with a genuine-but-stapled cert blob fails here.
output="$(osslsigncode verify \
    -CAfile "$CA_BUNDLE" \
    -TSA-CAfile "$CA_BUNDLE" \
    -in "$exe" 2>&1)" || {
        _red "FAIL: osslsigncode reported an invalid signature."
        echo "$output" >&2
        exit 1
    }

    output=${output//$'\n'/$'\n  | '}
    _dim "  | $output"
echo

# Verify the digest actually matched (belt-and-braces alongside the exit code).
if ! grep -qi 'Signature verification: ok' <<<"$output"; then
    _red "FAIL: signature did not verify against the file contents."
    exit 1
fi

# Pin the publisher identity.
if ! grep -qiF "$EXPECTED_SIGNER_O" <<<"$output"; then
    _red "FAIL: signed, but NOT by the expected publisher."
    _red "      expected organization: $EXPECTED_SIGNER_O"
    _red "      -> Do not run this binary."
    exit 1
fi

_green "PASS: valid Authenticode signature by '$EXPECTED_SIGNER_O'"
_green "      chain verified against the system CA bundle."
