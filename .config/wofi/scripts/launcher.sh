#!/bin/bash

CHOICE=$(printf "🔆 Wallpaper\n📋 Clipboard\n🔍 Fuzzy Finder\n📶 WiFi\n🔵 Bluetooth\n⏻  Power" | wofi --dmenu --prompt "Wofi Control")

case "$CHOICE" in 
  "🔆 Wallpaper") ~/.config/wofi/scripts/wallpaper.sh ;;
  "📋 Clipboard") ~/.config/wofi/scripts/clipboard.sh ;;
  "🔍 Fuzzy Finder") kitty --class="floating" ~/.config/wofi/scripts/fuzzy.sh ;;
  "📶 WiFi") ~/.config/wofi/scripts/wifi.sh ;;
  "🔵 Bluetooth") ~/.config/wofi/scripts/bluetooth.sh ;;
  "⏻  Power") ~/.config/wofi/scripts/power.sh ;;
esac
