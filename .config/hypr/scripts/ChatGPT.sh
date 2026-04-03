#!/bin/bash
# /* ---- 💫 ChatGPT Widget - Slide from Left 💫 ---- */  ##
# 💡 IMPORTANT: This script requires the following rules in your hyprland.conf:
# windowrule = float, title:^(.*ChatGPT.*)$
# windowrule = move -5000 -5000, title:^(.*ChatGPT.*)$

DEBUG=false
ADDR_FILE="/tmp/chatgpt_widget_addr"
WIDGET_TITLE="ChatGPT"

# Widget configuration
WIDGET_WIDTH=500
HEIGHT_PERCENT=70
X_PERCENT=0   # Position from left (0% to align with left edge)
Y_PERCENT=15  # Position from top (15% to center vertically)

# Animation settings
SLIDE_STEPS=8

# Parse debug flag
if [ "$1" = "-d" ]; then
    DEBUG=true
fi

# Debug echo function
debug_echo() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $@"
    fi
}

# Function to get monitor info
get_monitor_info() {
    hyprctl monitors -j | jq -r '.[0] | "\(.x) \(.y) \(.width) \(.height)"'
}

# Function to calculate widget position
calculate_widget_position() {
    local monitor_info=$(get_monitor_info)
    local mon_x=$(echo $monitor_info | cut -d' ' -f1)
    local mon_y=$(echo $monitor_info | cut -d' ' -f2)
    local mon_width=$(echo $monitor_info | cut -d' ' -f3)
    local mon_height=$(echo $monitor_info | cut -d' ' -f4)

    local height=$((mon_height * HEIGHT_PERCENT / 100))
    # Final X position on the left edge
    local x=$mon_x
    local y=$((mon_y + (mon_height * Y_PERCENT / 100)))

    echo "$x $y $WIDGET_WIDTH $height"
}

# Function to get stored widget address
get_widget_address() {
    if [ -f "$ADDR_FILE" ] && [ -s "$ADDR_FILE" ]; then
        cat "$ADDR_FILE"
    fi
}

# Function to check if our widget exists (using stored address and original title check)
our_widget_exists() {
    local addr=$(get_widget_address)
    if [ -n "$addr" ]; then
        local window_exists=$(hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR)')
        if [ "$window_exists" = "true" ]; then
            # Check title (case-insensitive test)
            local window_info=$(hyprctl clients -j | jq -r --arg ADDR "$addr" '.[] | select(.address == $ADDR) | select(.title | test("ChatGPT"; "i"))')
            if [ -n "$window_info" ]; then
                return 0
            fi
        fi
    fi
    return 1
}

# Function to check if widget is visible (on screen)
our_widget_is_visible() {
    local addr=$(get_widget_address)
    if [ -n "$addr" ]; then
        local window_info=$(hyprctl clients -j | jq -r --arg ADDR "$addr" '.[] | select(.address == $ADDR) | select(.title | test("ChatGPT"; "i"))')
        if [ -n "$window_info" ]; then
            local x=$(echo "$window_info" | jq -r '.at[0]')
            local y=$(echo "$window_info" | jq -r '.at[1]')
            # Check if x is near the target position (0)
            if [ "$x" -lt 100 ] && [ "$y" -lt 2000 ]; then
                return 0
            fi
        fi
    fi
    return 1
}

# Function to animate slide in from left (Start off-screen left, move to target_x)
animate_slide_in() {
    local addr="$1"
    local target_x="$2"
    local target_y="$3"
    local width="$4"
    local height="$5"

    debug_echo "Animating slide in for window $addr to position $target_x,$target_y"

    # Calculate starting position off-screen left
    local start_x=$((target_x - width - 100))

    # Move instantly to the start position (Uses the FINAL target_y to avoid vertical shift/drop)
    hyprctl dispatch movewindowpixel "exact $start_x $target_y,address:$addr" >/dev/null 2>&1
    sleep 0.05

    # Animate movement towards the target position (left to right)
    local step_x=$(((target_x - start_x) / SLIDE_STEPS))

    for i in $(seq 1 $SLIDE_STEPS); do
        local current_x=$((start_x + (step_x * i)))
        hyprctl dispatch movewindowpixel "exact $current_x $target_y,address:$addr" >/dev/null 2>&1
        sleep 0.03
    done

    # Final snap to ensure exact position
    hyprctl dispatch movewindowpixel "exact $target_x $target_y,address:$addr" >/dev/null 2>&1
}

# Function to animate slide out to left
animate_slide_out() {
    local addr="$1"
    local start_x="$2"
    local start_y="$3"
    local width="$4"
    local height="$5"

    debug_echo "Animating slide out for window $addr from position $start_x,$start_y"

    # End position (off-screen to the left)
    local end_x=$((start_x - width - 100))

    # Calculate step size (for movement to the left)
    local step_x=$(((start_x - end_x) / SLIDE_STEPS))

    # Animate slide out
    for i in $(seq 1 $SLIDE_STEPS); do
        local current_x=$((start_x - (step_x * i)))
        hyprctl dispatch movewindowpixel "exact $current_x $start_y,address:$addr" >/dev/null 2>&1
        sleep 0.03
    done

    # Move completely off-screen
    hyprctl dispatch movewindowpixel "exact -5000 -5000,address:$addr" >/dev/null 2>&1
}

# Function to spawn new widget
spawn_widget() {
    debug_echo "Creating new ChatGPT widget with title: $WIDGET_TITLE"

    local pos_info=$(calculate_widget_position)
    local target_x=$(echo $pos_info | cut -d' ' -f1)
    local target_y=$(echo $pos_info | cut -d' ' -f2)
    local width=$(echo $pos_info | cut -d' ' -f3)
    local height=$(echo $pos_info | cut -d' ' -f4)

    debug_echo "Target position: ${target_x}x${target_y}, size: ${width}x${height}"

    # Launch Brave ChatGPT app (using user's URL: chatgpt.com)
    hyprctl dispatch exec "[float; size $width $height] brave --app=\"https://chatgpt.com\"" >/dev/null 2>&1

    # Wait for window to appear
    # **زيادة وقت الانتظار هنا لضمان تطبيق قاعدة الإخفاء (-5000 -5000)**
    sleep 2.0

    local new_addr=""
    local attempts=0
    while [ $attempts -lt 20 ] && [ -z "$new_addr" ]; do
        # Find the new widget window by title (case-insensitive test)
        new_addr=$(hyprctl clients -j | jq -r '.[] | select(.title | test("ChatGPT"; "i")) | .address' | head -1)
        if [ -z "$new_addr" ] || [ "$new_addr" = "null" ]; then
            sleep 0.1
            attempts=$((attempts + 1))
        else
            break
        fi
    done

    if [ -n "$new_addr" ] && [ "$new_addr" != "null" ]; then
        echo "$new_addr" > "$ADDR_FILE"
        debug_echo "Widget created with address: $new_addr"

        # NOTE: The Hyprland rule 'move -5000 -5000' should hide it. This is a fallback.
        hyprctl dispatch movewindowpixel "exact -5000 -5000,address:$new_addr" >/dev/null 2>&1
        # **زيادة وقت الانتظار هنا للتأكد من أن النافذة اختفت تماماً قبل التحريك**
        sleep 0.3

        # Force resize to correct dimensions
        hyprctl dispatch resizewindowpixel "exact $width $height,address:$new_addr" >/dev/null 2>&1
        sleep 0.1

        # Show with animation (slides in from the left)
        animate_slide_in "$new_addr" "$target_x" "$target_y" "$width" "$height"

        # Focus the window
        hyprctl dispatch focuswindow "address:$new_addr" >/dev/null 2>&1

        return 0
    fi

    debug_echo "Failed to create widget"
    return 1
}

# Function to show existing widget
show_widget() {
    local addr="$1"
    if [ -n "$addr" ]; then
        debug_echo "Showing widget: $addr"

        local window_info=$(hyprctl clients -j | jq -r --arg ADDR "$addr" '.[] | select(.address == $ADDR) | select(.title | test("ChatGPT"; "i"))')
        if [ -z "$window_info" ]; then
            debug_echo "Window $addr is not our widget anymore, removing from tracking"
            rm -f "$ADDR_FILE"
            return 1
        fi

        local pos_info=$(calculate_widget_position)
        local target_x=$(echo $pos_info | cut -d' ' -f1)
        local target_y=$(echo $pos_info | cut -d' ' -f2)
        local width=$(echo $pos_info | cut -d' ' -f3)
        local height=$(echo $pos_info | cut -d' ' -f4)

        # Resize first
        hyprctl dispatch resizewindowpixel "exact $width $height,address:$addr" >/dev/null 2>&1
        sleep 0.1

        # Animate slide in (slides in from the left)
        animate_slide_in "$addr" "$target_x" "$target_y" "$width" "$height"

        # Focus the window
        hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1

        return 0
    fi
    return 1
}

# Function to close widget with animation
close_widget() {
    local addr="$1"
    if [ -n "$addr" ]; then
        debug_echo "Closing widget with animation: $addr"

        local window_info=$(hyprctl clients -j | jq -r --arg ADDR "$addr" '.[] | select(.address == $ADDR) | select(.title | test("ChatGPT"; "i"))')
        if [ -z "$window_info" ]; then
            debug_echo "Window $addr is not our widget anymore, removing from tracking"
            rm -f "$ADDR_FILE"
            return 1
        fi

        local x=$(echo "$window_info" | jq -r '.at[0]')
        local y=$(echo "$window_info" | jq -r '.at[1]')
        local width=$(echo "$window_info" | jq -r '.size[0]')
        local height=$(echo "$window_info" | jq -r '.size[1]')

        # Animate slide out to the left
        animate_slide_out "$addr" "$x" "$y" "$width" "$height"

        sleep 0.3
        hyprctl dispatch closewindow "address:$addr" >/dev/null 2>&1

        rm -f "$ADDR_FILE"

        return 0
    fi
    return 1
}

# Main logic
debug_echo "Starting ChatGPT widget script"

# Clean up old address file if widget doesn't exist
if [ -f "$ADDR_FILE" ]; then
    stored_addr=$(cat "$ADDR_FILE")
    if [ -n "$stored_addr" ]; then
        window_exists=$(hyprctl clients -j | jq -e --arg ADDR "$stored_addr" 'any(.[]; .address == $ADDR)')
        if [ "$window_exists" != "true" ]; then
            debug_echo "Stored widget no longer exists, cleaning up"
            rm -f "$ADDR_FILE"
        else
            window_info=$(hyprctl clients -j | jq -r --arg ADDR "$stored_addr" '.[] | select(.address == $ADDR) | select(.title | test("ChatGPT"; "i"))')
            if [ -z "$window_info" ]; then
                debug_echo "Stored widget is no longer a chatgpt widget, cleaning up"
                rm -f "$ADDR_FILE"
            fi
        fi
    fi
fi

WIDGET_ADDR=$(get_widget_address)

if [ -n "$WIDGET_ADDR" ] && our_widget_exists; then
    debug_echo "Found existing widget: $WIDGET_ADDR"

    if our_widget_is_visible; then
        debug_echo "Widget is visible, closing it completely"
        close_widget "$WIDGET_ADDR"
    else
        debug_echo "Widget exists but hidden, showing it"
        show_widget "$WIDGET_ADDR"
    fi
else
    debug_echo "No widget found, creating new one"
    spawn_widget
fi

debug_echo "Script completed"
