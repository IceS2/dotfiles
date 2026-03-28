#!/usr/bin/env bash
set -euo pipefail

# ╔═══════════════════════════════════════════════════════════╗
# ║              Guided Arch Linux System Update              ║
# ║          Interactive, educational, step-by-step           ║
# ╚═══════════════════════════════════════════════════════════╝

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- State tracking for summary ---
declare -A SUMMARY
SUMMARY[news]="○ Skipped"
SUMMARY[backup]="○ Skipped"
SUMMARY[update]="○ Skipped"
SUMMARY[pacnew]="○ Skipped"
SUMMARY[orphans]="○ Skipped"
SUMMARY[cache]="○ Skipped"
SUMMARY[reboot]="  No"
NEEDS_REBOOT=false

# --- Helpers ---
box() {
    local msg="$1"
    local color="${2:-$BLUE}"
    local len=${#msg}
    local border
    border=$(printf '═%.0s' $(seq 1 $((len + 2))))
    echo -e "${color}╔${border}╗${NC}"
    echo -e "${color}║${NC} ${BOLD}${msg}${NC} ${color}║${NC}"
    echo -e "${color}╚${border}╝${NC}"
}

info()  { echo -e "${BLUE}::${NC} $*"; }
warn()  { echo -e "${YELLOW}:: WARNING:${NC} $*"; }
error() { echo -e "${RED}:: ERROR:${NC} $*"; }
success() { echo -e "${GREEN}::${NC} $*"; }
dim()   { echo -e "${DIM}   $*${NC}"; }

confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local hint
    if [[ "$default" == "y" ]]; then
        hint="[Y/n]"
    else
        hint="[y/N]"
    fi

    local answer
    read -rp "$(echo -e "${BOLD}${prompt}${NC} ${hint} ")" answer
    answer="${answer:-$default}"
    [[ "${answer,,}" == "y" ]]
}

show_summary() {
    echo ""
    box "Update Summary" "$GREEN"
    echo ""
    printf "  %-20s %s\n" "Arch news checked"  "${SUMMARY[news]}"
    printf "  %-20s %s\n" "Package backup"     "${SUMMARY[backup]}"
    printf "  %-20s %s\n" "System update"      "${SUMMARY[update]}"
    printf "  %-20s %s\n" ".pacnew files"      "${SUMMARY[pacnew]}"
    printf "  %-20s %s\n" "Orphan cleanup"     "${SUMMARY[orphans]}"
    printf "  %-20s %s\n" "Cache cleanup"      "${SUMMARY[cache]}"

    if $NEEDS_REBOOT; then
        printf "  %-20s %s\n" "Reboot required" "$(echo -e "${YELLOW}!! Yes (kernel/NVIDIA updated)${NC}")"
    else
        printf "  %-20s %s\n" "Reboot required" "  No"
    fi
    echo ""
}

# --- Ctrl+C handler ---
trap 'echo ""; warn "Interrupted by user."; show_summary; exit 130' INT

# --- Refuse to run as root (paru handles sudo internally) ---
if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root. Paru handles privilege escalation internally."
    exit 1
fi

# ═══════════════════════════════════════════════════════════
# Phase 0: Arch News Gate
# ═══════════════════════════════════════════════════════════
echo ""
box "Phase 0: Arch News Check" "$RED"
echo ""
echo -e "  ${RED}${BOLD}IMPORTANT:${NC} Before updating, check the Arch Linux news for"
echo -e "  breaking changes, manual interventions, or known issues."
echo ""
echo -e "  ${BOLD}https://archlinux.org/news/${NC}"
echo ""

if confirm "  Open Arch news in your browser?" "y"; then
    xdg-open "https://archlinux.org/news/" 2>/dev/null &
    disown
    echo ""
    info "Browser opened. Take a moment to review recent posts."
fi

echo ""
if ! confirm "  Have you checked the news and want to proceed?" "n"; then
    info "Aborting. Check the news and run again when ready."
    SUMMARY[news]="○ Not confirmed"
    show_summary
    exit 0
fi
SUMMARY[news]="✓ Confirmed"
echo ""

# ═══════════════════════════════════════════════════════════
# Phase 1: Pre-flight Checks
# ═══════════════════════════════════════════════════════════
box "Phase 1: Pre-flight Checks"
echo ""

# Internet connectivity
info "Checking internet connectivity..."
if ping -c 1 -W 3 archlinux.org &>/dev/null; then
    success "Internet connection OK"
else
    warn "Cannot reach archlinux.org — updates may fail without internet."
fi

# Disk space
info "Checking disk space..."
root_usage=$(df / --output=pcent | tail -1 | tr -d ' %')
root_avail=$(df / --output=avail -BG | tail -1 | tr -d ' G')
if (( root_usage > 90 )) || (( root_avail < 2 )); then
    warn "Root partition is ${root_usage}% full (${root_avail}G free). Consider freeing space first."
else
    success "Disk space OK (${root_usage}% used, ${root_avail}G free)"
fi

# Pacman lock
if [[ -f /var/lib/pacman/db.lck ]]; then
    warn "Pacman database is locked (/var/lib/pacman/db.lck)."
    dim "Another package manager may be running, or a previous run crashed."
    dim "If no other package manager is running: sudo rm /var/lib/pacman/db.lck"
fi

# Backup package lists
echo ""
if confirm "  Backup installed package lists?" "y"; then
    backup_dir="$HOME/.cache/pkg-backups"
    mkdir -p "$backup_dir"
    timestamp=$(date +%Y%m%d-%H%M%S)

    pacman -Qqen > "${backup_dir}/official-${timestamp}.txt"
    pacman -Qqem > "${backup_dir}/aur-${timestamp}.txt"

    # Rotate: keep only the last 10 backups of each type
    for prefix in official aur; do
        # shellcheck disable=SC2012
        ls -1t "${backup_dir}/${prefix}-"*.txt 2>/dev/null | tail -n +11 | xargs -r rm --
    done

    success "Package lists saved to ${backup_dir}/ (${timestamp})"
    dim "Official: $(wc -l < "${backup_dir}/official-${timestamp}.txt") packages"
    dim "AUR:      $(wc -l < "${backup_dir}/aur-${timestamp}.txt") packages"
    SUMMARY[backup]="✓ Done"
else
    dim "Skipped package backup."
fi
echo ""

# ═══════════════════════════════════════════════════════════
# Phase 2: Preview Updates
# ═══════════════════════════════════════════════════════════
box "Phase 2: Preview Available Updates"
echo ""

# Official updates
info "Checking official repository updates..."
official_updates=""
if command -v checkupdates &>/dev/null; then
    official_updates=$(checkupdates 2>/dev/null || true)
else
    warn "checkupdates not found (install pacman-contrib for safer update checks)."
    dim "Falling back to paru -Qu..."
    official_updates=$(paru -Qu 2>/dev/null || true)
fi

official_count=0
if [[ -n "$official_updates" ]]; then
    official_count=$(echo "$official_updates" | wc -l)
    echo -e "  ${GREEN}${official_count}${NC} official updates available:"
    echo "$official_updates" | sed 's/^/    /'
else
    dim "No official updates."
fi

# AUR updates
echo ""
info "Checking AUR updates..."
aur_updates=""
aur_updates=$(paru -Qua 2>/dev/null || true)

aur_count=0
if [[ -n "$aur_updates" ]]; then
    aur_count=$(echo "$aur_updates" | wc -l)
    echo -e "  ${GREEN}${aur_count}${NC} AUR updates available:"
    echo "$aur_updates" | sed 's/^/    /'
else
    dim "No AUR updates."
fi

total=$((official_count + aur_count))
echo ""

# Exit early if nothing to do
if (( total == 0 )); then
    success "System is up to date! Nothing to do."
    SUMMARY[update]="✓ Already up to date"
    show_summary
    exit 0
fi

# Critical package detection
all_updates="${official_updates}"$'\n'"${aur_updates}"
critical_pkgs=""
for pkg in linux linux-headers linux-lts linux-lts-headers nvidia-dkms nvidia-utils lib32-nvidia-utils; do
    if echo "$all_updates" | grep -q "^${pkg} "; then
        critical_pkgs="${critical_pkgs}  ${pkg}\n"
    fi
done

if [[ -n "$critical_pkgs" ]]; then
    NEEDS_REBOOT=true
    echo ""
    box "CRITICAL PACKAGES UPDATING" "$RED"
    echo -e "${RED}  The following kernel/NVIDIA packages will be updated:${NC}"
    echo -e "${YELLOW}${critical_pkgs}${NC}"
    echo -e "  ${DIM}A reboot will be required after this update.${NC}"
    echo ""
fi

echo -e "  ${BOLD}Total: ${official_count} official + ${aur_count} AUR = ${total} packages${NC}"
echo ""
if ! confirm "  Proceed with update?" "y"; then
    info "Update cancelled."
    show_summary
    exit 0
fi
echo ""

# ═══════════════════════════════════════════════════════════
# Phase 3: System Update
# ═══════════════════════════════════════════════════════════
box "Phase 3: System Update"
echo ""
info "Running paru -Syu..."
dim "Paru will handle both official and AUR packages."
dim "You'll see paru's own prompts for confirmations."
echo ""

if paru -Syu; then
    success "Update completed successfully!"
    SUMMARY[update]="✓ Completed"
else
    exit_code=$?
    if (( exit_code == 130 )); then
        warn "Update cancelled by user."
        SUMMARY[update]="○ Cancelled"
    else
        error "Update failed (exit code: ${exit_code})."
        SUMMARY[update]="✗ Failed"
    fi
fi
echo ""

# ═══════════════════════════════════════════════════════════
# Phase 4: Post-update Tasks
# ═══════════════════════════════════════════════════════════
box "Phase 4: Post-update Tasks"
echo ""

# .pacnew files
info "Checking for .pacnew configuration files..."
if command -v pacdiff &>/dev/null; then
    pacnew_files=$(pacdiff -o 2>/dev/null || true)
    if [[ -n "$pacnew_files" ]]; then
        echo -e "  ${YELLOW}Found .pacnew files:${NC}"
        echo "$pacnew_files" | sed 's/^/    /'
        echo ""
        dim ".pacnew files are new default configs from updated packages."
        dim "pacdiff helps you merge them with your current configs."
        echo ""
        if confirm "  Run pacdiff to review them?" "n"; then
            sudo pacdiff
            SUMMARY[pacnew]="✓ Reviewed"
        else
            SUMMARY[pacnew]="○ Deferred"
            dim "You can run 'sudo pacdiff' later to review these."
        fi
    else
        success "No .pacnew files found."
        SUMMARY[pacnew]="✓ None found"
    fi
else
    dim "pacdiff not available (install pacman-contrib). Skipping .pacnew check."
    SUMMARY[pacnew]="○ pacdiff not installed"
fi
echo ""

# Orphaned packages
info "Checking for orphaned packages..."
orphans=$(pacman -Qdtq 2>/dev/null || true)
if [[ -n "$orphans" ]]; then
    orphan_count=$(echo "$orphans" | wc -l)
    echo -e "  ${YELLOW}${orphan_count} orphaned packages found:${NC}"
    echo "$orphans" | sed 's/^/    /'
    echo ""
    dim "Orphans are packages installed as dependencies that are no longer needed."
    echo ""
    if confirm "  Remove orphaned packages?" "n"; then
        # shellcheck disable=SC2086
        paru -Rns $orphans
        SUMMARY[orphans]="✓ Removed ${orphan_count} packages"
    else
        SUMMARY[orphans]="○ Skipped (${orphan_count} found)"
        dim "You can remove them later: paru -Rns \$(pacman -Qdtq)"
    fi
else
    success "No orphaned packages."
    SUMMARY[orphans]="✓ None found"
fi
echo ""

# Reboot reminder
if $NEEDS_REBOOT; then
    box "REBOOT RECOMMENDED" "$YELLOW"
    echo -e "  ${YELLOW}Kernel or NVIDIA drivers were updated.${NC}"
    echo -e "  ${YELLOW}A reboot is required for changes to take effect.${NC}"
    SUMMARY[reboot]="$(echo -e "${YELLOW}!! Yes (kernel/NVIDIA updated)${NC}")"
    echo ""
fi

# Cache cleanup
info "Checking package cache..."
cache_size=$(du -sh /var/cache/pacman/pkg/ 2>/dev/null | cut -f1)
echo -e "  Package cache size: ${BOLD}${cache_size}${NC}"
echo ""
dim "paru -Sc removes old cached package versions (keeps installed versions)."
echo ""
if confirm "  Clean package cache?" "n"; then
    paru -Sc
    SUMMARY[cache]="✓ Done"
else
    SUMMARY[cache]="○ Skipped"
fi

# ═══════════════════════════════════════════════════════════
# Final Summary
# ═══════════════════════════════════════════════════════════
show_summary
