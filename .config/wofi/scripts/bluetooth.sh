#!/bin/bash

# Get list of devices with status
get_devices() {
    while read -r mac name; do
        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
            echo "🟢 $name (Connected)"
        else
            echo "⭕ $name"
        fi
    done < <(bluetoothctl devices | cut -d ' ' -f 2-)
}

# Show device list in wofi
CHOICE=$(get_devices | wofi --dmenu --prompt "Bluetooth devices")

# Exit if no selection
[ -z "$CHOICE" ] && exit 0

# Extract device name without status
NAME=$(echo "$CHOICE" | sed 's/^.. \(.*\) (Connected)*/\1/')

# Get MAC address for selected device
MAC=$(bluetoothctl devices | grep "$NAME" | cut -d ' ' -f 2)

if echo "$CHOICE" | grep -q "Connected"; then
    # Disconnect if connected
    bluetoothctl disconnect "$MAC"
else
    # Connect if disconnected
    bluetoothctl connect "$MAC"
fi
