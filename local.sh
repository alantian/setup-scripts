#!/usr/bin/env bash

# Local package installer for recent versions under home directory
# Usage: ./local.sh [package_name] or ./local.sh (installs all)

set -euo pipefail

# Colors and logging
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' DIM='\033[2m' NC='\033[0m'
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Run command with clean output (success: silent, failure: show last 10 lines)
run_cmd() {
    local prefix="$1" cmd="$2" input="${3:-}" temp_file=$(mktemp) exit_code=0
    
    if [[ -n "$input" ]]; then
        printf "%s" "$input" | eval "$cmd" >"$temp_file" 2>&1 || exit_code=$?
    else
        eval "$cmd" >"$temp_file" 2>&1 || exit_code=$?
    fi
    
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

# Package installation definitions
# Each package has a custom installation script
declare -A PACKAGES

# fzf - fuzzy finder
PACKAGES[fzf]='
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    info "Installing fzf to ~/.fzf"

    run_cmd "fzf" "rm -rf ~/.fzf" &&
    run_cmd "fzf" "git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf" &&
    run_cmd "fzf" "~/.fzf/install --xdg --no-update-rc --no-bash --no-zsh --no-fish" "y\ny\ny\n"
'

# vim-plugins - install vim plugins using Vundle
PACKAGES[vim-plugins]='
    info "Setting up vim plugins with Vundle"
    if ! command -v vim &>/dev/null; then
        warn "vim not found, skipping plugin installation"
        return 1
    fi
    
    # Check if Vundle exists and is a proper git repo
    if [[ -d ~/.vim/bundle/Vundle.vim/.git ]] && 
       cd ~/.vim/bundle/Vundle.vim && 
       git remote get-url origin | grep -q "github.com/VundleVim/Vundle.vim"; then
        info "Vundle already installed"
    else
        info "Installing Vundle"
        run_cmd "vundle" "mkdir -p ~/.vim/bundle" &&
        run_cmd "vundle" "rm -rf ~/.vim/bundle/Vundle.vim" &&
        run_cmd "vundle" "git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim"
    fi
    
    info "Installing vim plugins"
    run_cmd "vim" "vim +PluginInstall +qall"
'

# oh-my-posh - prompt theme engine
PACKAGES[oh-my-posh]='
    info "Installing/updating oh-my-posh"
    if [[ -f "$HOME/.local/bin/oh-my-posh" ]]; then
        run_cmd "oh-my-posh" "$HOME/.local/bin/oh-my-posh upgrade"
    else
        run_cmd "oh-my-posh" "curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin -t ~/.poshthemes"
    fi
'

# proto - tool version manager
PACKAGES[proto]='
    info "Installing/updating proto"
    if [[ ! -f "$HOME/.proto/bin/proto" ]]; then
        run_cmd "proto" "bash <(curl -fsSL https://moonrepo.dev/install/proto.sh) --no-profile --yes"
    fi
    
    run_cmd "proto" "$HOME/.proto/bin/proto upgrade" &&
    run_cmd "proto" "$HOME/.proto/bin/proto install python uv node pnpm"
'

# zoxide - smart cd command
PACKAGES[zoxide]='
    info "Installing zoxide locally"
    if [[ ! -f "$HOME/.local/bin/zoxide" ]]; then
        run_cmd "zoxide" "curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh"
    else
        success "zoxide is already installed"
    fi
'

# Check if package is already installed
is_installed() {
    local package="$1"
    case "$package" in
        fzf)
            [[ -f ~/.fzf/bin/fzf ]] && command -v fzf &>/dev/null
            ;;
        vim-plugins)
            # Always reinstall vim plugins
            return 1
            ;;
        oh-my-posh)
            [[ -f "$HOME/.local/bin/oh-my-posh" ]]
            ;;
        proto)
            [[ -f "$HOME/.proto/bin/proto" ]]
            ;;
        zoxide)
            [[ -f "$HOME/.local/bin/zoxide" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# Install single package
install_package() {
    local package="$1"
    
    if [[ -z "${PACKAGES[$package]:-}" ]]; then
        error "Unknown package: $package"
        return 1
    fi
    
    if is_installed "$package"; then
        success "$package is already installed"
        return 0
    fi
    
    info "Installing $package"
    eval "${PACKAGES[$package]}" || {
        error "Failed to install $package"
        return 1
    }
    
    success "$package installed successfully"
    return 0
}

# Install all packages
install_all() {
    local failed=0
    
    for package in "${!PACKAGES[@]}"; do
        install_package "$package" || ((failed++))
    done
    
    if [[ $failed -eq 0 ]]; then
        success "All packages installed successfully"
    else
        error "$failed package(s) failed to install"
        return 1
    fi
}

# Check not running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run as root - packages install to home directory"
        exit 1
    fi
}

# Ensure required directories exist
ensure_directories() {
    local dirs=("$HOME/.local/bin")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            info "Creating directory: $dir"
            mkdir -p "$dir" || {
                error "Failed to create directory: $dir"
                return 1
            }
        fi
    done
}

# Main function
main() {
    local package="${1:-}"
    
    info "Starting local package installation"
    check_root
    ensure_directories
    
    if [[ -z "$package" ]]; then
        info "Installing all packages"
        install_all
    else
        install_package "$package"
    fi
}

# Show usage
if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
    echo "Usage: $0 [package_name]"
    echo "  package_name - Install specific package (optional)"
    echo "  (no args)    - Install all packages"
    echo ""
    echo "Available packages:"
    for package in "${!PACKAGES[@]}"; do
        echo "  - $package"
    done
    exit 0
fi

# Script only executes if we reach this line (protection against partial downloads)
main "$@"