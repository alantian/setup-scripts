# Setup Scripts

Cross-platform package setup scripts for *nix systems (Arch Linux, Ubuntu, macOS). Install essential development tools with a single command.

## Quick Start

### Complete Setup (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/alantian/setup-scripts/main/all.sh | bash
```
*Interactively runs both global and local installers*

### Individual Scripts

#### Global Package Installation
```bash
curl -fsSL https://raw.githubusercontent.com/alantian/setup-scripts/main/global.sh | bash
```

#### Local Package Installation
```bash
curl -fsSL https://raw.githubusercontent.com/alantian/setup-scripts/main/local.sh | bash
# or for specific packages:
./local.sh fzf
```

## What Gets Installed

Essential development tools including git, curl, build tools, modern CLI utilities (like eza, bat, fzf, zoxide), system utilities (vim, htop, tmux), and zsh shell setup. The global script installs packages via system package managers, while the local script installs recent versions to your home directory.

**Platform coverage**: Arch Linux has the most comprehensive package set, macOS has excellent coverage via Homebrew, and Ubuntu includes a curated subset from official repositories. For detailed package lists and platform differences, see [CLAUDE.md](CLAUDE.md#package-organization).

## Supported Systems

Arch Linux, Ubuntu 20.04+, and macOS (Intel/Apple Silicon).

## Features

Cross-platform, idempotent, non-interactive installation with automatic OS detection, clean output management, zsh shell setup, and AUR support for Arch Linux.

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
# Test complete setup locally
chmod +x all.sh
./all.sh

# Test individual scripts locally
chmod +x global.sh
./global.sh

chmod +x local.sh
./local.sh
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
    su - testuser -c 'curl -fsSL http://localhost:8000/global.sh | bash'
"; pkill -f "python3 -m http.server 8000" 2>/dev/null || true)

# Test on Arch Linux  
(pkill -f "python3 -m http.server 8000" 2>/dev/null || true; python3 -m http.server 8000 & docker run -it --rm --network host archlinux:latest bash -c "
    useradd -m testuser >/dev/null 2>&1 && 
    pacman -Sy --noconfirm curl sudo >/dev/null 2>&1 && 
    echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&
    su - testuser -c 'curl -fsSL http://localhost:8000/global.sh | bash'
"; pkill -f "python3 -m http.server 8000" 2>/dev/null || true)
```

## Important Notes

- **Shell changes**: After installation, restart your terminal or log out/in for zsh to become active
- **sudo required**: Script needs sudo privileges for package installation
- **Non-root execution**: Script refuses to run as root for security
- **macOS limitations**: Cannot test macOS in containers; use local testing

## Troubleshooting

### Package Installation Output
The script hides output on successful commands and only shows output on failure. Failed commands display up to the last 10 lines with a truncation indicator if more lines were available (e.g., "... (25 more lines above)").

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