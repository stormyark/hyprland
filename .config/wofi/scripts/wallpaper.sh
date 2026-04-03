#!/bin/bash

# Initialize swww if not running
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww init
    #sleep 1  # Give daemon time to start
fi

# Use wallpapers directory in home
DIR="$HOME/wallpapers/wallpaper"

# Get full path of selected wallpaper
WALL=$(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wofi --dmenu --prompt "Select wallpaper")

# Set wallpaper if selection was made
if [ -n "$WALL" ]; then
    swww img "$WALL" \
        --transition-type grow \
        --transition-pos center \
        --transition-fps 60
fi
