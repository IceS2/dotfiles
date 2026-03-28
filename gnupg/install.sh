#!/usr/bin/env bash
# GnuPG configuration installer
source "$(dirname "$0")/../lib/helpers.sh"

log_header "GnuPG"

ensure_dir "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

link_to gnupg/gpg-agent.conf "$HOME/.gnupg/gpg-agent.conf"
