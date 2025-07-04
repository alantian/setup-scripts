#!/usr/bin/env bash

# Complete setup script - runs both global and local installers
# Usage: curl -fsSL https://raw.githubusercontent.com/alantian/setup-scripts/main/all.sh | bash

set -euo pipefail

# GitHub URLs
GLOBAL_URL="https://raw.githubusercontent.com/alantian/setup-scripts/main/global.sh"
LOCAL_URL="https://raw.githubusercontent.com/alantian/setup-scripts/main/local.sh"

# Ask user with timeout
ask_user() {
    local response
    echo -n "Install global packages (requires sudo)? [y/N]: "
    if read -t 30 -r response </dev/tty 2>/dev/null; then
        [[ "$response" =~ ^[yY]([eE][sS])?$ ]]
    else
        echo
        false
    fi
}

# Main function
main() {
    # Run global script if user agrees
    if ask_user; then
        curl -fsSL "$GLOBAL_URL" | bash || true
    fi
    
    # Always run local script
    curl -fsSL "$LOCAL_URL" | bash
}

# Script only executes if we reach this line (protection against partial downloads)
main "$@"