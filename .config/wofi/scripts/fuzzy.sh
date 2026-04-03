#!/bin/bash
FILE=$(find -type f 2>/dev/null | fzf --prompt="Fuzzy open > ")
[ -n "$FILE" ] && xdg-open "$FILE"
