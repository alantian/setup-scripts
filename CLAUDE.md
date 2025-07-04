# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For user documentation, see [README.md](README.md).

**IMPORTANT**: Both this file and README.md should be updated whenever significant changes are made to the codebase. Update CLAUDE.md for implementation patterns and technical details, update README.md for user-facing features and usage changes. Remove outdated information and keep guidance relevant and actionable.

## Repository Structure

- `basic.sh` - Cross-platform basic development tools installer
- `basic_test.sh` - Automated testing script for all platforms
- `README.md` - User-facing documentation  
- `CLAUDE.md` - This technical guidance document

## Core Implementation Patterns

### Package Manager Output Handling
- **`run_pkg_cmd(prefix, command)`**: Centralized function for package manager execution
- **Real-time display**: Shows dimmed, prefixed output during execution  
- **Conditional clearing**: Clears output on success, leaves visible on failure
- **Consistent prefixing**: `[pacman]`, `[apt]`, `[brew]` prefixes for all output
- **Terminal control**: Uses ANSI escape sequences for cursor manipulation

### Package Organization
```bash
CORE_PACKAGES=(...)      # Cross-platform essentials
SHELL_PACKAGES=(...)     # Shell-related (zsh)
ARCH_SPECIFIC=(...)      # Platform-specific packages
UBUNTU_SPECIFIC=(...)
MACOS_SPECIFIC=(...)
```

#### Detailed Package Lists

**CORE_PACKAGES** (All Platforms):
- `git wget curl unzip bzip2 rsync tar` - Development and network tools
- `vim htop tree tmux` - System utilities and editors

**SHELL_PACKAGES** (All Platforms):
- `zsh` - Z shell (set as default shell)

**ARCH_SPECIFIC**:
- `base-devel` - Essential build tools and compilers
- `tar` - Archive tool (Arch-specific version)
- `zsh-completions` - Enhanced shell completions

**UBUNTU_SPECIFIC**:
- `build-essential` - Build tools and compilers
- `byobu` - Enhanced terminal multiplexer
- `software-properties-common apt-transport-https ca-certificates gnupg lsb-release` - Package management tools
- Note: `zsh-completions` not needed (included in main zsh package)

**MACOS_SPECIFIC**:
- `zsh zsh-completions` - Shell and completions (newer than system version)
- `rsync` - Better rsync than BSD version
- `coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-getopt` - GNU tools to replace BSD versions

### Error Handling and Safety
- **Wrapper function pattern**: `main()` at script end prevents partial execution
- **Root privilege check**: Script refuses to run as root, uses `sudo` selectively
- **Graceful failure**: Individual package failures don't stop entire process
- **Platform validation**: Automatic OS detection with unsupported system rejection
- **`set -e` with conditionals**: CRITICAL - avoid `[[ condition ]] && { ... }` patterns as they return 1 when condition is false, causing script exit with `set -e`. Use `if [[ condition ]]; then ... fi` instead for safety

### Shell Integration
- **Automatic shell change**: Updates `/etc/shells` and uses `chsh` to set zsh as default
- **PATH-aware selection**: Prefers newer tools (e.g., Homebrew zsh over system zsh)
- **Cross-platform compatibility**: Handles shell path differences across platforms

## Development Workflow

### Testing
Container testing commands are documented in [README.md](README.md#testing) and automated in `basic_test.sh`. Key points for development:

- **Container testing limitation**: Docker-based testing only works on Linux hosts (Linux containers require Linux kernel)
- **Use container testing**: Creates realistic non-root environment with sudo access  
- **Test script**: Use `./basic_test.sh` for automated testing of all platforms
- **Manual testing**: Commands in README.md for individual platform testing
- **Subshell pattern**: `(python3 -m http.server 8000 & docker run ...)` auto-cleans HTTP server

### Package Management
- **Consolidated installations**: Single package manager call per platform for performance
- **Platform-specific handling**: Different package names across distributions
- **Homebrew integration**: Auto-installation and PATH setup for macOS

### Code Maintenance
- **Update CLAUDE.md**: Refresh this file when making architectural changes
- **Update README.md**: Keep user documentation current with feature changes
- **Remove outdated patterns**: Clean up obsolete information regularly
- **Keep examples current**: Ensure code samples match actual implementation