# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For user documentation, see [README.md](README.md).

**IMPORTANT**: Both this file and README.md should be updated whenever significant changes are made to the codebase. Update CLAUDE.md for implementation patterns and technical details, update README.md for user-facing features and usage changes. Remove outdated information and keep guidance relevant and actionable.

## Repository Status

**Current State**: Mature, production-ready cross-platform package installation system with comprehensive testing, sophisticated error handling, and advanced output management.

**Last Updated**: January 2025 - All documentation reflects current implementation with recent simplifications to user-facing documentation.

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

## Key Features

- **Cross-platform support**: Arch Linux, Ubuntu, macOS with automatic OS detection
- **Idempotent execution**: Safe to run multiple times, always converges to desired state
- **Advanced output management**: Silent success, intelligent error reporting with real-time progress indicators
- **Interactive GUI prompts**: 30-second timeout for optional GUI package installation
- **Robust error handling**: Graceful failure handling, interrupt protection, partial download safety
- **Shell integration**: Automatic zsh setup with PATH-aware selection
- **AUR support**: Automatic yay installation for Arch Linux AUR packages
- **Local package management**: Home directory installations for tools requiring recent versions
- **Comprehensive testing**: Automated Docker-based testing for Ubuntu and Arch Linux
- **Package organization**: Multi-line definitions with comment support and automatic cleaning
- **User-friendly documentation**: Simplified README with technical details separated into CLAUDE.md

## Repository Structure

- `all.sh` - Complete setup script that runs both global and local installers interactively
- `global.sh` - Cross-platform global development tools installer (system package managers)
- `local.sh` - Local package installer for recent versions under home directory (5 packages)
- `basic_test.sh` - Automated testing script for Linux containers (Ubuntu, Arch)
- `README.md` - User-facing documentation  
- `CLAUDE.md` - This technical guidance document

### Local Package Details

The `local.sh` script installs 5 packages to the home directory for tools requiring recent versions:

- **fzf**: Fuzzy finder with shell integration (`~/.fzf`)
- **vim-plugins**: Vundle-based plugin management (requires vim)
- **oh-my-posh**: Modern prompt theme engine (`~/.local/bin`)
- **proto**: Multi-language tool version manager (Python, Node.js, pnpm, uv)
- **zoxide**: Smart cd replacement with shell integration

All packages are idempotent with installation detection. Supports batch installation (`./local.sh`) or individual selection (`./local.sh package_name`).

## Core Implementation Patterns

### Package Display
- **`show_packages(os)`**: Shows packages before installation
- **Platform-aware display**: Shows shared, OS-specific, and AUR packages separately
- **Clean formatting**: Uses dimmed text for package categories

### Command Output Handling
- **`run_cmd(prefix, command)`**: Centralized function for command execution with progress indication
- **Silent success**: Hides output completely on successful execution
- **Real-time progress**: Spinner with elapsed time display during command execution
- **Failure display**: Shows output only on command failure
- **Smart truncation**: Displays last 10 lines with truncation indicator if needed
- **Consistent prefixing**: `[pacman]`, `[apt]`, `[brew]`, `[shell]`, etc. prefixes for all output
- **Temporary files**: Uses mktemp for output capture and cleanup
- **Interrupt handling**: Ctrl+C shows current command and its output before exiting
- **Performance timing**: Shows completion time for successful operations

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

**PACKAGES[arch]** (Most Comprehensive):
- Build tools: `base-devel zsh-completions`
- Modern CLI tools: Full suite of modern alternatives (eza, bat, fd, etc.)
- Language servers: 11 language servers for development
- Fonts: `ttf-meslo-nerd`

**PACKAGES[arch_aur]** (AUR packages):
- Additional tools: `nodejs-tldr lazydocker`
- Auto-installs yay AUR helper if missing

**PACKAGES[ubuntu]** (Conservative Subset):
- Build tools: `build-essential` and essential development packages
- Available modern tools: Limited to official repository packages
- Note: Some tools have different names (`fd-find`, `batcat`)

**PACKAGES[macos]** (Homebrew Excellence):
- GNU tools: Comprehensive GNU tool replacements
- Modern CLI tools: Near feature parity with Arch Linux
- Excellent Homebrew integration

**GUI Packages:**

**PACKAGES[shared_gui]**: `firefox vlc gimp` (cross-platform)

**Platform-specific GUI packages**:
- **Arch**: `inkscape obs-studio` (official) + `visual-studio-code-bin discord slack-desktop` (AUR)
- **Ubuntu**: `inkscape` (limited to apt packages)
- **macOS**: `visual-studio-code discord slack inkscape obs zed@preview font-meslo-lg-nerd-font` (Homebrew cask)

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

### Testing Infrastructure

Comprehensive automated testing via `basic_test.sh` with Docker containers:

- **Platform coverage**: Ubuntu and Arch Linux (Linux host required for containers)
- **Test modes**: Local HTTP server (`./basic_test.sh`) or GitHub deployment (`./basic_test.sh github`)
- **Automated setup**: Non-root test users with sudo access in clean containers
- **HTTP server management**: Auto-starts/stops Python server on port 8000 with cleanup
- **Error reporting**: Full Docker command output on failures
- **Safety**: Container isolation prevents host system contamination

**Testing workflow**: `all.sh` → `global.sh` + `local.sh` with comprehensive error handling and output capture.

### Package Management
- **Consolidated installations**: Single package manager call per platform for performance
- **Platform-specific handling**: Different package names across distributions
- **Homebrew integration**: Auto-installation and PATH setup for macOS
- **Package combination**: Merges shared packages with platform-specific packages at runtime
- **AUR support**: Automatically installs yay AUR helper for Arch Linux if needed

### Code Maintenance

- **Documentation sync**: Update both CLAUDE.md (technical) and README.md (user-facing) for changes
- **README simplification**: Keep user documentation concise, move technical details to CLAUDE.md
- **Implementation accuracy**: Ensure all examples match current codebase
- **Remove outdated information**: Regular cleanup of obsolete patterns and references
- **Testing validation**: Run `./basic_test.sh` before major changes
- **Cross-platform verification**: Test on all supported platforms when possible
- **Documentation balance**: README focuses on user experience, CLAUDE.md covers implementation patterns