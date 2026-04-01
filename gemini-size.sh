#!/bin/bash

# Find the most recent session file
SESSION_FILE=$(ls -t ~/.gemini/tmp/hi/*.json | head -n 1)

if [ -z "$SESSION_FILE" ]; then
    echo "No session files found in ~/.gemini/tmp/hi/"
    exit 1
fi

echo "Analyzing session: $SESSION_FILE"
echo "-----------------------------------"

# Parse the JSON to list turn index and character count (proxy for tokens)
# Sorts by size (largest at the bottom)
jq -r '.history | to_entries[] | 
    "Turn: \(.key) | Size: \(.value.content | tostring | length) chars | Role: \(.value.role)"' \
    "$SESSION_FILE" | sort -t: -k3 -n