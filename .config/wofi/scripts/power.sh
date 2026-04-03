#!/bin/bash
OPTION=$(printf "⏻  Shutdown\n🔄 Reboot\n🔒 Lock" | wofi --dmenu --prompt "Power options")

case "$OPTION" in
  " ⏻  Shutdown") systemctl shutdown now ;;
  "🔄 Reboot") systemctl reboot ;;
  "🔒 Lock") hyprlock ;;
esac
