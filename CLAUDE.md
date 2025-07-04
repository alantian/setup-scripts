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
- **Exception**: Only `all.sh` is interactive (prompts before calling other scripts)

## Features

- **Cross-platform**: Automatically detects your OS and shows package list before installation
- **Idempotent**: Can be run multiple times safely - brings system to up-to-date state
- **Non-interactive**: Individual scripts run without user input (only `all.sh` is interactive)
- **Safe execution**: Includes protection against partial downloads
- **Clean output**: Shows command output only on failure, silent on success
- **Smart output management**: Shows last 10 lines of failed commands with truncation indicator if needed
- **Shell integration**: Automatically switches to zsh as default shell
- **AUR support**: Automatically installs yay AUR helper for Arch Linux when needed
- **Error handling**: Continues on individual package failures

## Repository Structure

- `all.sh` - Complete setup script that runs both global and local installers interactively
- `global.sh` - Cross-platform global development tools installer
- `local.sh` - Local package installer for recent versions under home directory
- `basic_test.sh` - Automated testing script for all platforms
- `README.md` - User-facing documentation  
- `CLAUDE.md` - This technical guidance document

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
- **Consistent prefixing**: `[pacman]`, `[apt]`, `[brew]`, `[shell]` prefixes for all output
- **Temporary files**: Uses mktemp for output capture and cleanup

### Package Organization
```bash
declare -A PACKAGES=(
    [shared]="..."       # Cross-platform essentials
    [arch]="..."         # Arch Linux specific packages
    [arch_aur]="..."     # Arch Linux AUR packages
    [ubuntu]="..."       # Ubuntu specific packages
    [macos]="..."        # macOS specific packages
)
```

#### Detailed Package Lists

**PACKAGES[shared]** (All Platforms):
- `git wget curl unzip bzip2 rsync tar` - Development and network tools
- `vim htop tree tmux` - System utilities and editors
- `zsh` - Z shell (set as default shell)

**PACKAGES[arch]** (Arch Linux):
- `base-devel` - Essential build tools and compilers
- `zsh-completions` - Enhanced shell completions
- Modern CLI tools: `eza bat git-delta fd duf dust bottom btop sd difftastic plocate hexyl zoxide broot direnv fzf croc hyperfine xh entr tig lazygit thefuck ctop xplr glances gtop zenith ttf-meslo-nerd`

**PACKAGES[arch_aur]** (Arch Linux AUR):
- `nodejs-tldr lazydocker` - Additional tools only available in AUR
- Installed via yay AUR helper (auto-installed if missing)
- Note: Most packages moved from AUR to official repos in recent Arch updates

**PACKAGES[ubuntu]** (Ubuntu):
- `build-essential` - Build tools and compilers
- `byobu` - Enhanced terminal multiplexer
- `software-properties-common apt-transport-https ca-certificates gnupg lsb-release` - Package management tools
- Limited modern CLI tools: `batcat fd-find plocate zoxide direnv fzf btop entr tig glances`
- Note: `fd-find` binary is named `fdfind`, `bat` is named `batcat` due to package conflicts
- Note: Many modern CLI tools not available in Ubuntu repos (eza, git-delta, duf, dust, etc.)

**PACKAGES[macos]** (macOS):
- `zsh-completions` - Shell completions (newer than system version)
- `coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-getopt` - GNU tools to replace BSD versions
- Modern CLI tools: `exa bat git-delta fd duf dust bottom btop sd difftastic hexyl zoxide broot direnv fzf croc hyperfine xh entr tig lazygit thefuck ctop xplr glances gtop zenith tldr lazydocker`
- Fonts: `font-meslo-lg-nerd-font`
- Note: `plocate` not included (macOS has built-in `locate`)

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
- **Use container testing**: Creates realistic non-root environment with sudo access  
- **Test script**: Use `./basic_test.sh` for automated testing of all platforms
- **Manual testing**: Commands in README.md for individual platform testing
- **Script hierarchy**: `all.sh` → `global.sh` + `local.sh` (interactive coordinator)
- **Global vs Local**: `global.sh` installs via system package managers, `local.sh` installs to home directory
- **Subshell pattern**: `(python3 -m http.server 8000 & docker run ...)` auto-cleans HTTP server

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