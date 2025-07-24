# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For user documentation, see [README.md](README.md).

**IMPORTANT**: Both this file and README.md should be updated whenever significant changes are made to the codebase. Update CLAUDE.md for implementation patterns and technical details, update README.md for user-facing features and usage changes. Remove outdated information and keep guidance relevant and actionable.

## Design Goals

### Idempotence
All scripts are designed to be **idempotent** - they can be run multiple times safely and will always bring the system to the same up-to-date state. This means:

- **Package managers**: Should update existing packages to latest versions
- **Detection logic**: Check if tools/configs already exist before installing/modifying
- **State convergence**: Each run should move toward the desired end state
- **No harmful repetition**: Running scripts multiple times should not cause issues

### Non-Interactive Execution
Individual scripts (`global.sh`, `local.sh`) run completely without user interaction:

- **No prompts**: All installations proceed automatically with sensible defaults
- **Non-interactive flags**: Package managers use `--noconfirm`, `--yes`, `-y` flags
- **Automation-friendly**: Safe for CI/CD, containers, and remote execution
- **Exception**: Only `all.sh` is interactive (prompts user with 30-second timeout before calling global.sh, always runs local.sh)

## Features

- **Cross-platform**: Automatically detects your OS and shows package list before installation
- **Idempotent**: Can be run multiple times safely - brings system to up-to-date state
- **GUI application support**: Optional GUI package installation with 30-second timeout prompt
- **Interactive prompts**: User can choose CLI-only or CLI+GUI installation
- **Safe execution**: Includes protection against partial downloads
- **Clean output**: Shows command output only on failure, silent on success
- **Smart output management**: Shows last 10 lines of failed commands with truncation indicator if needed
- **Interrupt handling**: Ctrl+C shows current command output before graceful exit
- **Shell integration**: Automatically switches to zsh as default shell
- **AUR support**: Automatically installs yay AUR helper for Arch Linux when needed
- **Error handling**: Continues on individual package failures
- **Package filtering**: Multi-line package definitions with comment support

## Repository Structure

- `all.sh` - Complete setup script that runs both global and local installers interactively
- `global.sh` - Cross-platform global development tools installer (system package managers)
- `local.sh` - Local package installer for recent versions under home directory (5 packages)
- `basic_test.sh` - Automated testing script for Linux containers (Ubuntu, Arch)
- `README.md` - User-facing documentation  
- `CLAUDE.md` - This technical guidance document

### Local Package Details

The `local.sh` script installs packages to the home directory for tools that need recent versions or aren't available in system repositories:

- **fzf**: Fuzzy finder installed to `~/.fzf` with shell integration
- **vim-plugins**: Installs vim plugins using Vundle (requires vim)
- **oh-my-posh**: Modern prompt theme engine installed to `~/.local/bin`
- **proto**: Tool version manager for Python, Node.js, pnpm, and uv
- **zoxide**: Smart cd command replacement installed locally

All local packages are idempotent and check for existing installations before proceeding. The local.sh script supports both batch installation (no arguments) and individual package selection (`./local.sh package_name`). Use `./local.sh --help` to see available packages.

## Core Implementation Patterns

### Package Display
- **`show_packages(os)`**: Shows packages before installation
- **Platform-aware display**: Shows shared, OS-specific, and AUR packages separately
- **Clean formatting**: Uses dimmed text for package categories

### Command Output Handling
- **`run_cmd(prefix, command)`**: Centralized function for command execution
- **Silent success**: Hides output completely on successful execution
- **Failure display**: Shows output only on command failure
- **Smart truncation**: Displays last 10 lines with truncation indicator if needed
- **Consistent prefixing**: `[pacman]`, `[apt]`, `[brew]`, `[shell]`, etc. prefixes for all output
- **Temporary files**: Uses mktemp for output capture and cleanup
- **Interrupt handling**: Ctrl+C shows current command and its output before exiting

### Package Filtering
- **`clean_packages(packages)`**: Filters and cleans package lists before installation
- **Comment removal**: Strips lines starting with `#` for inline documentation
- **Whitespace cleanup**: Removes extra spaces, newlines, and formatting artifacts
- **Single-line output**: Converts multi-line definitions to space-separated lists
- **Safe processing**: Prevents package manager errors from malformed input

### Package Organization
```bash
declare -A PACKAGES=(
    [shared]="..."           # Cross-platform CLI essentials
    [shared_gui]="..."       # Cross-platform GUI applications
    [arch]="..."             # Arch Linux CLI packages
    [arch_gui]="..."         # Arch Linux GUI packages (official repos)
    [arch_aur]="..."         # Arch Linux AUR CLI packages
    [arch_aur_gui]="..."     # Arch Linux AUR GUI packages
    [ubuntu]="..."           # Ubuntu CLI packages
    [ubuntu_gui]="..."       # Ubuntu GUI packages (apt only)
    [macos]="..."            # macOS CLI packages
    [macos_gui]="..."        # macOS GUI packages (brew cask)
)
```

**Package Structure:**
- **CLI packages**: `shared + [os] + [os]_aur`
- **GUI packages**: `shared_gui + [os]_gui + [os]_aur_gui`
- **Multi-line format**: Used for readability with automatic cleaning/filtering
- **Comment support**: Inline comments are automatically stripped before package installation

#### Detailed Package Lists

**CLI Packages:**

**PACKAGES[shared]** (All Platforms):
- Development tools: `git wget curl unzip bzip2 rsync`
- System utilities: `vim htop tree tmux zsh`

**PACKAGES[arch]** (Arch Linux):
- Build tools: `base-devel zsh-completions`
- Modern CLI tools: `eza bat tar git-delta fd duf dust bottom btop sd difftastic plocate hexyl zoxide broot direnv fzf croc hyperfine xh entr tig lazygit thefuck ctop xplr glances gtop zenith`
- Fonts: `ttf-meslo-nerd`
- Language servers: `bash-language-server gopls lua-language-server marksman python-lsp-server rust-analyzer taplo texlab typescript-language-server vscode-css-languageserver vscode-html-languageserver vscode-json-languageserver yaml-language-server`

**PACKAGES[arch_aur]** (Arch Linux AUR):
- Additional CLI tools: `nodejs-tldr lazydocker`
- Installed via yay AUR helper (auto-installed if missing)

**PACKAGES[ubuntu]** (Ubuntu):
- Build tools: `build-essential byobu software-properties-common apt-transport-https ca-certificates tar gnupg lsb-release`
- Available modern CLI tools: `bat fd-find plocate zoxide direnv fzf btop entr tig glances`
- Note: `fd-find` binary is `fdfind`, `bat` is `batcat` due to package conflicts

**PACKAGES[macos]** (macOS):
- Shell/GNU tools: `zsh-completions coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-getopt`
- Modern CLI tools: `eza bat git-delta fd duf dust bottom btop sd difftastic hexyl zoxide broot direnv fzf croc hyperfine xh entr tig lazygit thefuck ctop xplr glances gtop zenith tldr lazydocker`

**GUI Packages:**

**PACKAGES[shared_gui]** (All Platforms):
- Cross-platform applications: `firefox vlc gimp`

**PACKAGES[arch_gui]** (Arch Linux Official):
- Development/creative tools: `visual-studio-code-bin inkscape obs-studio`

**PACKAGES[arch_aur_gui]** (Arch Linux AUR):
- Communication tools: `discord slack-desktop`

**PACKAGES[ubuntu_gui]** (Ubuntu):
- Creative tools: `inkscape`
- Note: Limited to apt-available packages only

**PACKAGES[macos_gui]** (macOS):
- Development/communication: `visual-studio-code discord slack inkscape obs`
- Installed via `brew install --cask`

### Error Handling and Safety
- **Wrapper function pattern**: `main()` at script end prevents partial execution
- **Root privilege check**: Script refuses to run as root, uses `sudo` selectively
- **Graceful failure**: Individual package failures don't stop entire process
- **Platform validation**: Automatic OS detection with unsupported system rejection
- **`set -euo pipefail`**: Strict error handling with undefined variable detection and pipeline failures
- **Conditional handling**: Uses explicit `if` statements instead of `&&` chains to avoid `set -e` issues
- **Function return codes**: Explicit return statements for clear success/failure indication

### Shell Integration
- **Automatic shell change**: Updates `/etc/shells` and uses `chsh` to set zsh as default
- **PATH-aware selection**: Prefers newer tools (e.g., Homebrew zsh over system zsh)
- **Cross-platform compatibility**: Handles shell path differences across platforms

### AUR Integration (Arch Linux)
- **`install_yay()`**: Installs yay AUR helper if not present
- **Automatic detection**: Checks for yay before attempting AUR package installation
- **Temporary build**: Uses mktemp for clean yay installation from source
- **Conditional AUR installation**: Only installs AUR packages if arch_aur list is non-empty

## Development Workflow

### Testing
Container testing commands are documented in [README.md](README.md#testing) and automated in `basic_test.sh`. Key points for development:

- **Container testing limitation**: Docker-based testing only works on Linux hosts (Linux containers require Linux kernel)
- **Test script options**: 
  - `./basic_test.sh` or `./basic_test.sh local` - Tests locally served script via HTTP server
  - `./basic_test.sh github` - Tests script deployed on GitHub
- **Automated setup**: Creates non-root testuser with sudo access in containers
- **Platform coverage**: Tests Ubuntu and Arch Linux distributions
- **HTTP server management**: Auto-starts/stops Python HTTP server on port 8000 with cleanup
- **Error handling**: Shows full Docker command and output on test failures
- **Script hierarchy**: `all.sh` → `global.sh` + `local.sh` (interactive coordinator)
- **Global vs Local**: `global.sh` installs via system package managers, `local.sh` installs to home directory

### Package Management
- **Consolidated installations**: Single package manager call per platform for performance
- **Platform-specific handling**: Different package names across distributions
- **Homebrew integration**: Auto-installation and PATH setup for macOS
- **Package combination**: Merges shared packages with platform-specific packages at runtime
- **AUR support**: Automatically installs yay AUR helper for Arch Linux if needed

### Code Maintenance
- **Update CLAUDE.md**: Refresh this file when making architectural changes
- **Update README.md**: Keep user documentation current with feature changes
- **Remove outdated patterns**: Clean up obsolete information regularly
- **Keep examples current**: Ensure code samples match actual implementation