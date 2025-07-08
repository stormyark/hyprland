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

set -euo pipefail

# Check Root
if [[ $UID == 0 ]]; then
    echo -e "\033[1;31mPlease run this script WITHOUT sudo:\033[0m"
    echo "$0 $*"
    exit 1
fi

# Get current date in YYYY-MM-DD format
date=$(date +"%Y-%m-%d")

# Write changes to a logfile
log_file="$HOME/.config/scripts/sysmaintenancelogs/sysmaintenance_$date.log"
exec > >(tee -a "$log_file") 2>&1

echo -e "\033[1;36m--- System Maintenance Script ---\033[0m"
echo "Date: $date"
echo "User: $USER"

# Create a backup
# Check if timeshift is installed
if ! command -v timeshift &> /dev/null; then
     read -r -p $'\033[1;34mTimeshift is not installed. Would you like to install it now?(Y/n) \033[0m' install_response
     if [[ "$install_response" =~ ^[Yy]$ || -z "$install_response" ]]; then
         echo -e "\033[1;34mInstalling timeshift...\033[0m"
         sudo pacman -Sy --noconfirm timeshift || {
             echo -e "\033[1;31mTimeshift installation failed. Script aborted.\033[0m"
             exit 1
         }
     else
         echo -e "\033[1;31mTimeshift installation skipped. Script aborted.\033[0m"
         exit 1
     fi
 fi

echo -e "\033[1;34mCreating a backup using timeshift...\033[0m"
sudo timeshift --create --comments "sysmaintenance backup ($date)" --tags D || {
    # Make sure the backup was successful
    echo -e "\033[1;31mBackup failed. Script aborted.\033[0m"
    exit 1
}
echo -e "\033[1;32mBackup created successfully!\033[0m"

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
echo -e "\033[1;34mUpdating system using pacman...\033[0m"
sudo pacman -Syu --noconfirm

# Clear pacman cache
echo -e "\033[1;34mClearing pacman cache using paccache...\033[0m"
cache_before=$(du -sh /var/cache/pacman/pkg/ | awk '{print $1}')
# Check if paccache is installed
if ! command -v paccache &> /dev/null; then
    read -r -p $'\033[1;34mpaccache is not installed. Do you want to install it? (Y/n) \033[0m' response
    if [[ "$response" =~ ^[Yy]$ || -z "$response" ]]; then
        echo -e "\033[1;34mInstalling paccache...\033[0m"
        sudo pacman -Sy pacman-contrib
    else
        echo -e "\033[1;31mInstallation skipped.\033[0m"
    fi
fi
if command -v paccache &> /dev/null; then
    paccache -r
    cache_after=$(du -sh /var/cache/pacman/pkg/ | awk '{print $1}')
    echo "Pacman cache before: $cache_before"
    echo "Pacman cache after:  $cache_after"
fi

# Remove Orphans (unneeded dependencies)
orphans=$(pacman -Qdtq)
if [ -n "$orphans" ]; then # Check if there are any orphans
    echo -e "\033[1;34mRemoving listed orphan packages:\033[0m"
    echo "$orphans"
    sudo pacman -Rns "$orphans" --noconfirm
else
    echo -e "\033[1;31mNo orphans found.\033[0m"
fi

# Update AUR packages
read -r -p $'\033[1;34mUpdate AUR Packages? (Y/n) \033[0m' reply
if [[ "$reply" =~ ^[Yy]$ || -z "$reply" ]]; then
    if command -v yay &> /dev/null; then
        yay -Syu --noconfirm
    else
        echo -e "\033[1;31m'yay' not found, skipping AUR update.\033[0m"
    fi
fi

: '
#echo "Clearing ~/.cache..."
#home_cache_used="$(du -sh ~/.cache)"
#rm -rf ~/.cache/
#echo "Spaced saved: $home_cache_used"
'

echo -e "\033[1;34mClearing system logs...\033[0m"
journal_size_before=$(journalctl --disk-usage | awk '{print $4$5}' | numfmt --from=iec) # Get initial journal size
# awk '{print $4, $5}' extracts the size and the unit (e.g., 512.3 M).
sudo journalctl --vacuum-time=7d # Clear logs older than 7 days
journal_size_after=$(journalctl --disk-usage | awk '{print $4$5}' | numfmt --from=iec) #Get new journal size

space_freed=$((journal_size_before - journal_size_after))
echo -e "\033[1;32mJournal space saved:\033[0m $(numfmt --to=iec $space_freed)"

# Ask the user if they want to reboot
read -r -p $'\033[1;34mDo you want to reboot the system? (Y/n) \033[0m' reboot_response
if [[ "$reboot_response" =~ ^[Yy]$ || -z "$reboot_response" ]]; then
    echo -e "\033[1;32mRebooting now...\033[0m"
    sudo reboot
else
    echo -e "\033[1;31mReboot skipped, please reboot later.\033[0m"
    notify-send "Reboot is recommended."
fi

# --- Summary ---
echo -e "\n\033[1;36m--- Maintenance Summary ---\033[0m"
echo "Backup created: Yes"
echo "Old Timeshift backups pruned: Yes"
echo "System updated: Yes"
echo "Pacman cache cleaned: Yes"
echo "Orphan packages removed: $([[ -n "$orphans" ]] && echo Yes || echo No)"
echo "AUR updated: $([[ "$reply" =~ ^[Yy]$ || -z "$reply" ]] && command -v yay &> /dev/null && echo Yes || echo No)"
echo "System logs cleaned: Yes"
echo "Reboot: $([[ "$reboot_response" =~ ^[Yy]$ || -z "$reboot_response" ]] && echo Yes || echo No)"

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
