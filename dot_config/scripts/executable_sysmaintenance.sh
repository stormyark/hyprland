#!/bin/bash
#
# sysmaintenance.sh - System maintenance script for Arch Linux
#
# Author: stormy
# Created: 2025-06-01
#
# Description:
# This script automates system maintenance by creating a backup using Timeshift,
# updating the system, cleaning caches and removing orphaned packages.
#
# Note:
# Run this script WITHOUT sudo. It uses sudo internally when necessary.
#
# Website: stormyark.de

set -euo pipefail

# Check Root
if [[ $UID == 0 ]]; then
    echo -e "\033[1;31mPlease run this script WITHOUT sudo:\033[0m"
    echo "$0 $*"
    exit 1
fi

# Get current date in YYYY-MM-DD format
date=$(date +"%Y-%m-%d")

# Defaults / options
AUTO_YES=0
NO_REBOOT=0
SKIP_TIMESHIFT=0
KEEP_PACCACHE=3

show_help() {
    cat <<EOF
Usage: $0 [options]
Options:
  -y, --yes           Assume yes for prompts
  --no-reboot         Don't offer to reboot at the end
  --no-timeshift      Skip creating a Timeshift backup
  -k N, --keep-cache N  Keep last N pacman package versions (default: 3)
  -h, --help          Show this help
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes) AUTO_YES=1; shift;;
        --no-reboot) NO_REBOOT=1; shift;;
        --no-timeshift) SKIP_TIMESHIFT=1; shift;;
        -k|--keep-cache) KEEP_PACCACHE="$2"; shift 2;;
        -h|--help) show_help;;
        --) shift; break;;
        *) echo "Unknown option: $1"; show_help;;
    esac
done

# Write changes to a logfile
log_dir="$HOME/.config/scripts/sysmaintenance_logs"
mkdir -p "$log_dir"
log_file="$log_dir/sysmaintenance_$date.log"
exec > >(tee -a "$log_file") 2>&1

echo -e "\033[1;36m--- System Maintenance Script ---\033[0m"
echo "Date: $date"
echo "User: $USER"

# Create a backup
# Check if timeshift is installed
#if ! command -v timeshift &> /dev/null; then
#     read -r -p $'\033[1;34mTimeshift is not installed. Would you like to install it now?(Y/n) \033[0m' install_response
#     if [[ "$install_response" =~ ^[Yy]$ || -z "$install_response" ]]; then
#         echo -e "\033[1;34mInstalling timeshift...\033[0m"
#         sudo pacman -Sy --noconfirm timeshift || {
#             echo -e "\033[1;31mTimeshift installation failed. Script aborted.\033[0m"
#             exit 1
#         }
#     else
#         echo -e "\033[1;31mTimeshift installation skipped. Script aborted.\033[0m"
#         exit 1
#     fi
# fi
#
#echo -e "\033[1;34mCreating a backup using timeshift...\033[0m"
#sudo timeshift --create --comments "sysmaintenance backup ($date)" --tags D || {
#    # Make sure the backup was successful
#    echo -e "\033[1;31mBackup failed. Script aborted.\033[0m"
#    exit 1
#}
#echo -e "\033[1;32mBackup created successfully!\033[0m"

# Keep only the last 10 Timeshift backups
# echo -e "\033[1;34mPruning Timeshift backups to keep only the latest 10...\033[0m"
# backup_count=$(sudo timeshift --list | grep -c '^Snapshot:')
# if (( backup_count > 10 )); then
#     # Get list of old snapshots (all but the 10 most recent)
#     old_snapshots=$(sudo timeshift --list | grep '^Snapshot:' | head -n -10 | awk '{print $2}')
#     for snap in $old_snapshots; do
#         echo -e "\033[1;33mDeleting old snapshot: $snap\033[0m"
#         sudo timeshift --delete --snapshot "$snap"
#     done
# else
#     echo -e "\033[1;32mNo old Timeshift backups to delete.\033[0m"
# fi

# pacman -Syu
echo -e "\033[1;34mRefreshing sudo credentials...\033[0m"
sudo -v || {
    echo -e "\033[1;31mFailed to obtain sudo credentials. Aborting.\033[0m"
    exit 1
}

echo -e "\033[1;34mUpdating system using pacman...\033[0m"
sudo pacman -Syu --noconfirm

# Update Mirrorlist
#sudo reflector --country Germany,Switzerland,Austria --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
#sudo pacman -Syyu --noconfirm

# Clear pacman cache
echo -e "\033[1;34mClearing pacman cache using paccache (keeping last $KEEP_PACCACHE)...\033[0m"
cache_before=$(du -sh /var/cache/pacman/pkg/ 2>/dev/null | awk '{print $1}' || echo "0")
if ! command -v paccache &> /dev/null; then
    echo -e "\033[1;33mpaccache not available; installing pacman-contrib...\033[0m"
    sudo pacman -Sy --noconfirm pacman-contrib || echo -e "\033[1;33mCould not install pacman-contrib, skipping cache cleanup.\033[0m"
fi
if command -v paccache &> /dev/null; then
    sudo paccache -rk"$KEEP_PACCACHE"
    cache_after=$(du -sh /var/cache/pacman/pkg/ 2>/dev/null | awk '{print $1}' || echo "0")
    echo "Pacman cache before: $cache_before"
    echo "Pacman cache after:  $cache_after"
else
    echo -e "\033[1;33mpaccache is still unavailable; skipping cache prune.\033[0m"
fi

# Remove Orphans (unneeded dependencies)
orphans=$(pacman -Qdtq 2>/dev/null || true)
if [[ -n "$orphans" ]]; then
    echo -e "\033[1;34mRemoving orphan packages:\033[0m"
    echo "$orphans"
    sudo pacman -Rns --noconfirm $orphans || echo -e "\033[1;33mFailed to remove some orphans (continuing).\033[0m"
else
    echo -e "\033[1;32mNo orphan packages found.\033[0m"
fi

# Update AUR packages
if (( AUTO_YES == 1 )); then
    aur_update_choice=1
else
    read -r -p $'\033[1;34mUpdate AUR packages? (Y/n) \033[0m' reply
    if [[ "$reply" =~ ^[Yy]$ || -z "$reply" ]]; then
        aur_update_choice=1
    else
        aur_update_choice=0
    fi
fi
if (( aur_update_choice == 1 )); then
    if command -v yay &> /dev/null; then
        yay -Syu --noconfirm || echo -e "\033[1;33m'yay' update failed (continuing).\033[0m"
    elif command -v paru &> /dev/null; then
        paru -Syu --noconfirm || echo -e "\033[1;33m'paru' update failed (continuing).\033[0m"
    elif command -v pamac &> /dev/null; then
        pamac upgrade --no-confirm || echo -e "\033[1;33mpamac update failed (continuing).\033[0m"
    else
        echo -e "\033[1;33mNo AUR helper found (yay/paru/pamac); skipping AUR updates.\033[0m"
    fi
else
    echo -e "\033[1;33mSkipping AUR updates.\033[0m"
fi

: '
#echo "Clearing ~/.cache..."
#home_cache_used="$(du -sh ~/.cache)"
#rm -rf ~/.cache/
#echo "Spaced saved: $home_cache_used"
'

echo -e "\033[1;34mClearing system journal older than 7 days...\033[0m"
journal_size_before_bytes=0
journal_size_after_bytes=0
disk_usage_line=$(journalctl --disk-usage 2>/dev/null || true)
if [[ -n "$disk_usage_line" ]]; then
    # Extract the human-readable size (e.g. 1.3G)
    before_hr=$(echo "$disk_usage_line" | sed -E 's/.*take up ([0-9\.]+[KMGTPE]?)( in .*| in the .*).*/\1/')
    if [[ -n "$before_hr" ]]; then
        journal_size_before_bytes=$(numfmt --from=iec "$before_hr" 2>/dev/null || echo 0)
    fi
fi
sudo journalctl --vacuum-time=7d || echo -e "\033[1;33mjournalctl vacuum had an issue (continuing).\033[0m"
disk_usage_line_after=$(journalctl --disk-usage 2>/dev/null || true)
if [[ -n "$disk_usage_line_after" ]]; then
    after_hr=$(echo "$disk_usage_line_after" | sed -E 's/.*take up ([0-9\.]+[KMGTPE]?)( in .*| in the .*).*/\1/')
    if [[ -n "$after_hr" ]]; then
        journal_size_after_bytes=$(numfmt --from=iec "$after_hr" 2>/dev/null || echo 0)
    fi
fi
space_freed_bytes=$((journal_size_before_bytes - journal_size_after_bytes))
if (( space_freed_bytes > 0 )); then
    echo -e "\033[1;32mJournal space saved:\033[0m $(numfmt --to=iec $space_freed_bytes)"
else
    echo -e "\033[1;32mNo journal space freed (or unable to calculate).\033[0m"
fi

# Ask the user if they want to reboot
if (( NO_REBOOT == 1 )); then
    echo -e "\033[1;33mReboot suppressed by option.\033[0m"
    reboot_wanted=0
else
    if (( AUTO_YES == 1 )); then
        reboot_wanted=1
    else
        read -r -p $'\033[1;34mDo you want to reboot the system now? (Y/n) \033[0m' reboot_response
        if [[ "$reboot_response" =~ ^[Yy]$ || -z "$reboot_response" ]]; then
            reboot_wanted=1
        else
            reboot_wanted=0
        fi
    fi
fi
if (( reboot_wanted == 1 )); then
    echo -e "\033[1;32mRebooting now...\033[0m"
    sudo reboot
else
    echo -e "\033[1;31mReboot skipped; please reboot later if needed.\033[0m"
    if command -v notify-send &> /dev/null; then
        notify-send "System maintenance completed — reboot recommended."
    fi
fi

# --- Summary ---
echo -e "\n\033[1;36m--- Maintenance Summary ---\033[0m"
echo "Timeshift backup: $(( SKIP_TIMESHIFT == 1 ))"
echo "System updated: Yes"
echo "Pacman cache kept last: $KEEP_PACCACHE"
echo "Orphans removed: $([[ -n "$orphans" ]] && echo Yes || echo No)"
echo "AUR updated: $([[ $aur_update_choice -eq 1 ]] && echo Yes || echo No)"
echo "System logs cleaned: Yes"
echo "Reboot: $([[ $reboot_wanted -eq 1 ]] && echo Yes || echo No)"

# Reset color
echo -e "\033[0m"

: '
# --- Systemd Timer/Service Example ---
# To automate, create these files:

# ~/.config/systemd/user/sysmaintenance.service
[Unit]
Description=Arch System Maintenance

[Service]
Type=oneshot
ExecStart=/home/stormy/.config/scripts/sysmaintenance.sh

# ~/.config/systemd/user/sysmaintenance.timer
[Unit]
Description=Run Arch System Maintenance weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target

# Then enable with:
# systemctl --user enable --

# End example
'
