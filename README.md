# Setup Scripts

Cross-platform package setup scripts for *nix systems (Arch Linux, Ubuntu, macOS). Install essential development tools with a single command.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/alantian/setup-scripts/main/basic.sh | bash
```

## What Gets Installed

Essential development tools including:
- **Development basics**: git, curl, wget, build tools
- **System utilities**: vim, htop, tree, tmux  
- **Shell setup**: zsh (set as default shell)
- **Platform-specific tools**: Package managers and system-specific utilities

For detailed package lists, see [CLAUDE.md](CLAUDE.md#package-organization).

## Supported Systems

- **Arch Linux** - Latest rolling release
- **Ubuntu** - 20.04 LTS and newer
- **macOS** - Intel and Apple Silicon

## Features

- **Cross-platform**: Automatically detects your OS
- **Safe execution**: Includes protection against partial downloads
- **Clean output**: Shows progress during installation, hides noise on success
- **Smart output management**: Limits package manager output to last 10 lines with truncation indicator if needed
- **Shell integration**: Automatically switches to zsh as default shell
- **Error handling**: Continues on individual package failures

## Testing

### Automated Testing
```bash
# Test local script (requires Linux host)
./basic_test.sh

# Test GitHub deployment  
./basic_test.sh github
```

### Manual Testing
```bash
# Test locally on your system
chmod +x basic.sh
./basic.sh
```

### Container Testing (Linux hosts only)
Docker-based testing requires a Linux host system because Linux containers need the Linux kernel.

```bash
# Test on Ubuntu
(pkill -f "python3 -m http.server 8000" 2>/dev/null || true; python3 -m http.server 8000 & docker run -it --rm --network host ubuntu:latest bash -c "
    useradd -m testuser >/dev/null 2>&1 && 
    apt update >/dev/null 2>&1 && 
    apt install -y curl sudo >/dev/null 2>&1 && 
    echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&
    su - testuser -c 'curl -fsSL http://localhost:8000/basic.sh | bash'
"; pkill -f "python3 -m http.server 8000" 2>/dev/null || true)

# Test on Arch Linux  
(pkill -f "python3 -m http.server 8000" 2>/dev/null || true; python3 -m http.server 8000 & docker run -it --rm --network host archlinux:latest bash -c "
    useradd -m testuser >/dev/null 2>&1 && 
    pacman -Sy --noconfirm curl sudo >/dev/null 2>&1 && 
    echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&
    su - testuser -c 'curl -fsSL http://localhost:8000/basic.sh | bash'
"; pkill -f "python3 -m http.server 8000" 2>/dev/null || true)
```

## Important Notes

- **Shell changes**: After installation, restart your terminal or log out/in for zsh to become active
- **sudo required**: Script needs sudo privileges for package installation
- **Non-root execution**: Script refuses to run as root for security
- **macOS limitations**: Cannot test macOS in containers; use local testing

## Troubleshooting

### Package Installation Output
The script limits package manager output to the last 10 lines during execution. If output exceeds this, you'll see a truncation indicator (e.g., "... (25 more lines above)"). On success, all output is cleared; on failure, the limited output remains visible for debugging.

### Shell Not Changed
The script only shows restart instructions if your shell was actually changed from the current one to zsh.

### macOS Issues
- Ensure you have internet connection for Homebrew installation
- Some packages may require Xcode Command Line Tools: `xcode-select --install`

## Contributing

1. Test changes using the container testing commands above
2. Ensure the script works on all supported platforms
3. Update this README if adding new features or packages

## Security

This script is designed for curl-piped execution but includes several safety measures:
- Protection against partial script downloads
- Non-interactive package installation
- Minimal privilege requirements (no root execution)
- Clear error reporting and logging