#!/usr/bin/env bash

# Automated testing script for setup-scripts
# Tests all supported Linux distributions via Docker containers

set -euo pipefail

# Colors and logging
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
info() { echo -e "${BLUE}[TEST]${NC} $1"; }
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check prerequisites
check_prereqs() {
    [[ "$OSTYPE" != "linux-gnu"* ]] && {
        fail "Container testing requires Linux host (Docker needs Linux kernel)"
        info "On macOS/Windows, test locally: chmod +x basic.sh && ./basic.sh"
        exit 1
    }
    
    command -v docker &>/dev/null || { fail "Docker not installed or not in PATH"; exit 1; }
    docker info &>/dev/null || { fail "Docker daemon not running or not accessible"; exit 1; }
}

# Clean up any existing HTTP servers on port 8000
cleanup_port() {
    pkill -f "python3 -m http.server 8000" 2>/dev/null || true
    local port_pid=$(lsof -ti:8000 2>/dev/null || true)
    [[ -n "$port_pid" ]] && kill -9 $port_pid 2>/dev/null || true
    sleep 1
}

# Start HTTP server
start_server() {
    cleanup_port
    info "Starting HTTP server on port 8000"
    python3 -m http.server 8000 >/dev/null 2>&1 &
    SERVER_PID=$!
    sleep 2
    kill -0 $SERVER_PID 2>/dev/null || { fail "Failed to start HTTP server"; return 1; }
    info "HTTP server started (PID: $SERVER_PID)"
}

# Stop HTTP server
stop_server() {
    [[ -n "${SERVER_PID:-}" ]] && {
        info "Stopping HTTP server"
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    }
    cleanup_port
}

# Docker test setup command
docker_setup() {
    echo "set -e
          useradd -m testuser >/dev/null 2>&1
          # Add to sudo group (Ubuntu) or wheel group (Arch)  
          usermod -aG sudo testuser >/dev/null 2>&1 || usermod -aG wheel testuser >/dev/null 2>&1
          ($1) >/dev/null 2>&1
          echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
          su - testuser -c '$2'"
}

# Test single platform
test_platform() {
    local platform="$1" image="$2" setup_cmd="$3" script_url="$4"
    local temp_file=$(mktemp)
    
    info "Testing $platform"
    
    local docker_cmd="$(docker_setup "$setup_cmd" "curl -fsSL $script_url | bash")"
    local exit_code=0
    
    docker run -it --rm --network host "$image" bash -c "$docker_cmd" > "$temp_file" 2>&1 || exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        pass "$platform test passed"
        rm -f "$temp_file"
        return 0
    else
        fail "$platform test failed (exit code: $exit_code)"
        echo "--- Docker command was ---"
        echo "$docker_cmd"
        echo "--- Test output ---"
        cat "$temp_file"
        echo "--- End of test output ---"
        rm -f "$temp_file"
        return 1
    fi
}

# Test local script
test_local() {
    info "Testing local script"
    start_server || return 1
    
    local failed=0
    test_platform "Ubuntu" "ubuntu:latest" "apt update && apt install -y curl sudo" "http://localhost:8000/basic.sh" || ((failed++))
    test_platform "Arch Linux" "archlinux:latest" "pacman -Sy --noconfirm curl sudo" "http://localhost:8000/basic.sh" || ((failed++))
    
    stop_server
    return $failed
}

# Test GitHub deployment
test_github() {
    info "Testing GitHub deployment"
    local failed=0
    local github_url="https://raw.githubusercontent.com/alantian/setup-scripts/main/basic.sh"
    
    test_platform "Ubuntu" "ubuntu:latest" "apt update && apt install -y curl sudo" "$github_url" || ((failed++))
    test_platform "Arch Linux" "archlinux:latest" "pacman -Sy --noconfirm curl sudo" "$github_url" || ((failed++))
    
    return $failed
}

# Main function
main() {
    local test_type="${1:-local}" failed=0
    
    info "Starting automated testing"
    trap stop_server EXIT
    check_prereqs
    
    case "$test_type" in
        local)   test_local || failed=$? ;;
        github)  test_github || failed=$? ;;
        *)       echo "Usage: $0 [local|github]"; exit 1 ;;
    esac
    
    echo
    if [[ $failed -eq 0 ]]; then
        pass "All tests passed!"
    else
        fail "$failed test(s) failed"
        exit 1
    fi
}

# Show usage
[[ "${1:-}" =~ ^(-h|--help)$ ]] && {
    echo "Usage: $0 [local|github]"
    echo "  local  - Test locally served script (default)"
    echo "  github - Test script deployed on GitHub"
    echo ""
    echo "Note: Requires Linux host for Docker container testing"
    exit 0
}

main "${1:-local}"