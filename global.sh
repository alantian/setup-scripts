#!/usr/bin/env bash

# Global development tools installer for Arch Linux, Ubuntu, and macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/alantian/setup-scripts/main/global.sh | bash

set -euo pipefail

# Global variables for interrupt handling
CURRENT_OUTPUT_FILE=""
CURRENT_COMMAND=""
CURRENT_PREFIX=""

# Pre-cleaned packages (set in main function)
declare -A CLEAN_PACKAGES

# Trap handler for Ctrl+C
cleanup_and_show_output() {
    echo
    warn "Script interrupted by user (Ctrl+C)"
    
    if [[ -n "$CURRENT_COMMAND" ]]; then
        info "Interrupted while running: $CURRENT_COMMAND"
    fi
    
    if [[ -n "$CURRENT_OUTPUT_FILE" && -f "$CURRENT_OUTPUT_FILE" ]]; then
        local line_count
        line_count=$(wc -l < "$CURRENT_OUTPUT_FILE" 2>/dev/null || echo 0)
        if [[ $line_count -gt 0 ]]; then
            info "Output from interrupted command:"
            echo "--- Command Output ---"
            while IFS= read -r line; do
                echo -e "${DIM}[$CURRENT_PREFIX]${NC} $line"
            done < "$CURRENT_OUTPUT_FILE"
            echo "--- End Output ---"
        fi
        rm -f "$CURRENT_OUTPUT_FILE"
    fi
    
    exit 130
}

# Set up the trap
trap cleanup_and_show_output SIGINT

# Package definitions
# Structure: shared, shared_gui, [os], [os]_gui, [os]_aur, [os]_aur_gui
# CLI packages: shared + [os] + [os]_aur
# GUI packages: shared_gui + [os]_gui + [os]_aur_gui
# 
# Note: Multi-line format is used for readability. All package strings are
# automatically cleaned and converted to single-line space-separated lists
# before being passed to package managers. This removes extra whitespace,
# newlines, and prevents formatting issues.
declare -A PACKAGES=(
    [shared]="
        # Development and network tools
        git wget curl unzip bzip2 rsync
        # System utilities and editors
        vim htop tree tmux zsh
    "
    [shared_gui]="
        # Cross-platform GUI applications
        firefox vlc gimp
    "
    [arch]="
        # Build tools and shell
        base-devel zsh-completions
        # Modern CLI tools
        eza bat tar git-delta fd duf dust bottom btop sd difftastic
        plocate hexyl zoxide broot direnv fzf croc hyperfine xh
        entr tig lazygit thefuck ctop xplr glances gtop zenith
        # Fonts
        ttf-meslo-nerd
        # Language servers for development
        bash-language-server gopls lua-language-server marksman
        python-lsp-server rust-analyzer taplo texlab
        typescript-language-server vscode-css-languageserver
        vscode-html-languageserver vscode-json-languageserver
        yaml-language-server
    "
    [arch_gui]="
        # Development and creative tools
        inkscape obs-studio
    "
    [arch_aur]="
        # Additional CLI tools from AUR
        nodejs-tldr lazydocker
    "
    [arch_aur_gui]="
        # Communication and collaboration tools
        visual-studio-code-bin discord slack-desktop
    "
    [ubuntu]="
        # Build tools and system utilities
        build-essential byobu software-properties-common
        apt-transport-https ca-certificates tar gnupg lsb-release
        # Available modern CLI tools
        bat fd-find plocate zoxide direnv fzf btop entr tig glances
    "
    [ubuntu_gui]="
        # Creative tools available in apt
        inkscape
    "
    [macos]="
        # Shell enhancements and GNU tools
        zsh-completions coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-getopt
        # Modern CLI tools via Homebrew
        eza bat git-delta fd duf dust bottom btop sd difftastic hexyl zoxide broot
        direnv fzf croc hyperfine xh entr tig lazygit thefuck ctop xplr glances
        gtop zenith tldr lazydocker
    "
    [macos_gui]="
        # Development and communication tools
        visual-studio-code discord slack inkscape obs zed@preview
        # Fonts
        font-meslo-lg-nerd-font
    "
)

# Colors and logging
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' DIM='\033[2m' NC='\033[0m'
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Run command with clean output (success: silent, failure: show last 10 lines)
run_cmd() {
    local prefix="$1" cmd="$2" temp_file exit_code=0
    temp_file=$(mktemp)
    
    # Set global variables for trap handler
    CURRENT_OUTPUT_FILE="$temp_file"
    CURRENT_COMMAND="$cmd"
    CURRENT_PREFIX="$prefix"
    
    # Run command in background so main script can catch signals
    eval "$cmd" >"$temp_file" 2>&1 &
    local cmd_pid=$!
    
    # Show elapsed time while command runs
    local start_time spin_index=0
    start_time=$(date +%s)
    local spinner='|/-\'
    
    printf "${DIM}[$prefix]${NC} Running"
    
    while kill -0 $cmd_pid 2>/dev/null; do
        local elapsed=$(($(date +%s) - start_time))
        local minutes=$((elapsed / 60))
        local seconds=$((elapsed % 60))
        
        printf "\r${DIM}[$prefix]${NC} Running ${spinner:$((spin_index % 4)):1} ${minutes}m ${seconds}s"
        
        sleep 0.5
        ((spin_index++))
    done
    
    # Wait for command to complete and get exit code
    wait $cmd_pid || exit_code=$?
    
    # Clear the progress line
    printf "\r${DIM}[$prefix]${NC} "
    if [[ $exit_code -eq 0 ]]; then
        local elapsed=$(($(date +%s) - start_time))
        local minutes=$((elapsed / 60))
        local seconds=$((elapsed % 60))
        printf "Completed in ${minutes}m ${seconds}s\n"
    else
        printf "Failed\n"
    fi
    
    # Clear global variables
    CURRENT_OUTPUT_FILE=""
    CURRENT_COMMAND=""
    CURRENT_PREFIX=""
    
    if [[ $exit_code -eq 0 ]]; then
        rm -f "$temp_file"
        return 0
    else
        local line_count
        line_count=$(wc -l < "$temp_file" 2>/dev/null || echo 0)
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

# Clean and filter package list - removes extra whitespace, empty lines, and comments
# Converts multi-line package definitions to single-line space-separated list
clean_packages() {
    local packages="$1"
    echo "$packages" | grep -v '^[[:space:]]*#' | tr '\n' ' ' | tr -s ' ' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'
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
    info "Setting zsh as default shell"
    local zsh_path=$(command -v zsh)
    
    # Add zsh to /etc/shells and change user shell
    run_cmd "shell" "echo '$zsh_path' | sudo tee -a /etc/shells"
    run_cmd "shell" "sudo chsh -s '$zsh_path' '$USER'"
    success "Shell changed to zsh"
}

# Ask user about GUI applications with 30-second timeout
ask_gui() {
    local response
    echo -n "Install GUI applications (browsers, editors, media tools)? [y/N]: "
    if read -t 30 -r response </dev/tty 2>/dev/null; then
        [[ "$response" =~ ^[yY]([eE][sS])?$ ]]
    else
        echo
        echo "No response within 30 seconds, skipping GUI applications"
        false
    fi
}

# Display packages to be installed
show_packages() {
    local os="$1" include_gui="$2"
    local shared_packages="${CLEAN_PACKAGES[shared]}"
    local os_packages="${CLEAN_PACKAGES[$os]}"
    
    info "Packages to be installed on $os:"
    echo -e "${DIM}shared packages:${NC} $shared_packages"
    echo -e "${DIM}$os packages:${NC} $os_packages"
    
    if [[ "$os" == "arch" ]]; then
        local aur_packages="${CLEAN_PACKAGES[arch_aur]}"
        if [[ -n "$aur_packages" ]]; then
            echo -e "${DIM}aur packages:${NC} $aur_packages"
        fi
    fi
    
    if [[ "$include_gui" == "true" ]]; then
        local shared_gui_packages="${CLEAN_PACKAGES[shared_gui]}"
        if [[ -n "$shared_gui_packages" ]]; then
            echo -e "${DIM}shared gui packages:${NC} $shared_gui_packages"
        fi
        
        local gui_packages="${CLEAN_PACKAGES[${os}_gui]}"
        if [[ -n "$gui_packages" ]]; then
            echo -e "${DIM}$os gui packages:${NC} $gui_packages"
        fi
        
        if [[ "$os" == "arch" ]]; then
            local aur_gui_packages="${CLEAN_PACKAGES[arch_aur_gui]}"
            if [[ -n "$aur_gui_packages" ]]; then
                echo -e "${DIM}aur gui packages:${NC} $aur_gui_packages"
            fi
        fi
    fi
}

# Add GUI packages to a package variable if GUI is enabled
add_gui_packages() {
    local packages_var="$1" os="$2"
    [[ "$include_gui" != "true" ]] && return
    
    local shared_gui="${CLEAN_PACKAGES[shared_gui]}"
    local os_gui="${CLEAN_PACKAGES[${os}_gui]}"
    
    if [[ -n "$shared_gui" ]]; then
        eval "$packages_var+=\" $shared_gui\""
    fi
    if [[ -n "$os_gui" ]]; then
        eval "$packages_var+=\" $os_gui\""
    fi
}

# Install packages for each OS
install_packages() {
    local os="$1" include_gui="$2"
    local packages="${CLEAN_PACKAGES[shared]} ${CLEAN_PACKAGES[$os]}"
    
    case "$os" in
        arch)
            # Add GUI packages to main package list for Arch
            add_gui_packages "packages" "$os"
            
            run_cmd "pacman" "sudo pacman -Syu --noconfirm" &&
            run_cmd "pacman" "sudo pacman -S --noconfirm $packages"
            
            # Install AUR packages
            local aur_packages="${CLEAN_PACKAGES[arch_aur]}"
            if [[ "$include_gui" == "true" ]]; then
                local aur_gui="${CLEAN_PACKAGES[arch_aur_gui]}"
                if [[ -n "$aur_gui" ]]; then
                    aur_packages+=" $aur_gui"
                fi
            fi
            
            if [[ -n "$aur_packages" ]]; then
                install_yay || { error "yay installation failed"; return 1; }
                run_cmd "yay" "yay -S --noconfirm $aur_packages"
            fi
            ;;
        ubuntu)
            # Add GUI packages to main package list for Ubuntu
            add_gui_packages "packages" "$os"
            
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
            run_cmd "brew" "brew install $packages"
            
            # Install GUI applications via cask
            if [[ "$include_gui" == "true" ]]; then
                local shared_gui="${CLEAN_PACKAGES[shared_gui]}"
                local macos_gui="${CLEAN_PACKAGES[macos_gui]}"
                local gui_packages="$shared_gui $macos_gui"
                run_cmd "brew" "brew install --cask --force $gui_packages"
            fi
            ;;
    esac
}

# Main function
main() {
    local include_gui=false
    
    info "Starting basic development tools installation"
    check_root
    
    local os
    os=$(detect_os)
    info "Detected OS: $os"
    
    # Pre-clean all packages once to avoid redundant calls
    for key in "${!PACKAGES[@]}"; do
        CLEAN_PACKAGES[$key]=$(clean_packages "${PACKAGES[$key]}")
    done
    
    # Ask about GUI applications with timeout
    if ask_gui; then
        include_gui=true
        info "GUI applications will be installed"
    fi
    
    show_packages "$os" "$include_gui"
    install_packages "$os" "$include_gui" || { error "Package installation failed"; exit 1; }
    success "Package installation completed"
    
    # Change shell to zsh
    change_shell
    success "Installation completed successfully!"
    warn "IMPORTANT: Your shell has been changed to zsh"
    info "If your shell was not zsh before, please restart your terminal or log out and back in"
}

# Script only executes if we reach this line (protection against partial downloads)
main "$@"
