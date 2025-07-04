#!/usr/bin/env bash

# Global development tools installer for Arch Linux, Ubuntu, and macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/alantian/setup-scripts/main/global.sh | bash

set -euo pipefail

# Package definitions
declare -A PACKAGES=(
    [shared]="git wget curl unzip bzip2 rsync tar vim htop tree tmux zsh"
    [arch]="base-devel zsh-completions eza bat git-delta fd duf dust bottom btop sd difftastic plocate hexyl zoxide broot direnv fzf croc hyperfine xh entr tig lazygit thefuck ctop xplr glances gtop zenith ttf-meslo-nerd"
    [arch_aur]="nodejs-tldr lazydocker"
    [ubuntu]="build-essential byobu software-properties-common apt-transport-https ca-certificates gnupg lsb-release batcat fd-find plocate zoxide direnv fzf btop entr tig glances"
    [macos]="zsh-completions coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-getopt eza bat git-delta fd duf dust bottom btop sd difftastic hexyl zoxide broot direnv fzf croc hyperfine xh entr tig lazygit thefuck ctop xplr glances gtop zenith tldr lazydocker"
)

# Colors and logging
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' DIM='\033[2m' NC='\033[0m'
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Run command with clean output (success: silent, failure: show last 10 lines)
run_cmd() {
    local prefix="$1" cmd="$2" temp_file=$(mktemp) exit_code=0
    
    eval "$cmd" >"$temp_file" 2>&1 || exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        rm -f "$temp_file"
        return 0
    else
        local line_count=$(wc -l < "$temp_file" 2>/dev/null || echo 0)
        if [[ $line_count -gt 10 ]]; then
            echo -e "${DIM}[$prefix]${NC} ... ($((line_count - 10)) more lines above)"
            tail -n 10 "$temp_file" | while IFS= read -r line; do
                echo -e "${DIM}[$prefix]${NC} $line"
            done
        else
            while IFS= read -r line; do
                echo -e "${DIM}[$prefix]${NC} $line"
            done < "$temp_file"
        fi
        rm -f "$temp_file"
        return 1
    fi
}

# Detect operating system
detect_os() {
    [[ "$OSTYPE" == "darwin"* ]] && echo "macos" && return
    [[ -f /etc/os-release ]] || { error "Cannot detect OS"; exit 1; }
    . /etc/os-release
    case "$ID" in
        arch|ubuntu) echo "$ID" ;;
        *) error "Unsupported OS: $ID"; exit 1 ;;
    esac
}

# Check not running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run as root"
        exit 1
    fi
}

# Install yay AUR helper for Arch Linux
install_yay() {
    command -v yay &>/dev/null && return 0
    
    info "Installing yay AUR helper"
    local temp_dir=$(mktemp -d)
    run_cmd "yay" "cd '$temp_dir' && git clone https://aur.archlinux.org/yay.git" &&
    run_cmd "yay" "cd '$temp_dir/yay' && makepkg -si --noconfirm" &&
    rm -rf "$temp_dir"
}

# Change shell to zsh
change_shell() {
    local current_shell=$(basename "$SHELL")
    [[ "$current_shell" == "zsh" ]] && return 0
    
    info "Changing shell from $current_shell to zsh"
    local zsh_path=$(command -v zsh || { error "zsh not found"; return 1; })
    
    # Add to /etc/shells if needed
    grep -q "^$zsh_path$" /etc/shells 2>/dev/null || 
        run_cmd "shell" "echo '$zsh_path' | sudo tee -a /etc/shells" || return 1
    
    # Change shell
    run_cmd "shell" "sudo chsh -s '$zsh_path' '$USER'" || return 1
    success "Shell changed to zsh"
    return 0  # Success
}

# Display packages to be installed
show_packages() {
    local os="$1"
    local shared_packages="${PACKAGES[shared]}"
    local os_packages="${PACKAGES[$os]}"
    
    info "Packages to be installed on $os:"
    echo -e "${DIM}Shared packages:${NC} $shared_packages"
    echo -e "${DIM}$os packages:${NC} $os_packages"
    
    if [[ "$os" == "arch" ]]; then
        local aur_packages="${PACKAGES[arch_aur]}"
        if [[ -n "$aur_packages" ]]; then
            echo -e "${DIM}AUR packages:${NC} $aur_packages"
        fi
    fi
}

# Install packages for each OS
install_packages() {
    local os="$1" packages="${PACKAGES[shared]} ${PACKAGES[$os]}"
    
    case "$os" in
        arch)
            run_cmd "pacman" "sudo pacman -Syu --noconfirm" &&
            run_cmd "pacman" "sudo pacman -S --noconfirm $packages"
            
            # Install AUR packages if any
            local aur_packages="${PACKAGES[arch_aur]}"
            if [[ -n "$aur_packages" ]]; then
                install_yay || { error "yay installation failed"; return 1; }
                run_cmd "yay" "yay -S --noconfirm $aur_packages"
            fi
            ;;
        ubuntu)
            run_cmd "apt" "sudo apt update" &&
            run_cmd "apt" "sudo apt upgrade -y" &&
            run_cmd "apt" "sudo apt install -y $packages"
            ;;
        macos)
            # Install Homebrew if needed
            if ! command -v brew &>/dev/null; then
                info "Installing Homebrew"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                [[ -f "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
                [[ -f "/usr/local/bin/brew" ]] && eval "$(/usr/local/bin/brew shellenv)"
            fi
            run_cmd "brew" "brew update" &&
            run_cmd "brew" "brew upgrade" &&
            run_cmd "brew" "brew install $packages" &&
            run_cmd "brew" "brew install --cask font-meslo-lg-nerd-font"
            ;;
    esac
}

# Main function
main() {
    local shell_changed=false
    
    info "Starting basic development tools installation"
    check_root
    
    local os=$(detect_os)
    info "Detected OS: $os"
    
    show_packages "$os"
    install_packages "$os" || { error "Package installation failed"; exit 1; }
    success "Package installation completed"
    
    # Check if shell needs to be changed
    local current_shell=$(basename "$SHELL")
    if [[ "$current_shell" != "zsh" ]]; then
        change_shell && shell_changed=true
    fi
    success "Installation completed successfully!"
    if [[ "$shell_changed" == "true" ]]; then
        warn "IMPORTANT: Your shell has been changed to zsh"
        info "Please restart your terminal or log out and back in"
    fi
}

# Script only executes if we reach this line (protection against partial downloads)
main "$@"