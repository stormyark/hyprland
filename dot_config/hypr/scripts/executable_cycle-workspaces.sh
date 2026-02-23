#!/bin/bash

# Liste belegter Workspaces holen
workspaces=($(hyprctl workspaces -j | jq '.[].id' | sort -n))
current=$(hyprctl activeworkspace -j | jq '.id')

# Index des aktuellen Workspace finden
for i in "${!workspaces[@]}"; do
    if [[ "${workspaces[$i]}" == "$current" ]]; then
        next_index=$(( (i + 1) % ${#workspaces[@]} ))
        next_workspace=${workspaces[$next_index]}
        hyprctl dispatch workspace "$next_workspace"
        break
    fi
done

