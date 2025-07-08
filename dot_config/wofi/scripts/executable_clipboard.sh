#!/bin/bash
cliphist list | wofi --dmenu --prompt "Clipboard content" | cliphist decode | wl-copy