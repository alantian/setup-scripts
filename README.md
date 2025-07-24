# Setup Scripts

Cross-platform package setup scripts for *nix systems (Arch Linux, Ubuntu, macOS). Install packages with a single command.

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

**CLI Tools**: Git, curl, build tools, modern alternatives (eza, bat, fzf, zoxide), system utilities (vim, htop, tmux), zsh shell, and language servers.

**GUI Applications** (optional): Firefox, VS Code, Discord, media tools - installed with user confirmation.

**Methods**: System packages via native package managers + recent versions installed locally to home directory.

## Supported Systems

Arch Linux, Ubuntu 20.04+, and macOS (Intel/Apple Silicon).

## Features

- **Cross-platform**: Arch Linux, Ubuntu, macOS with automatic OS detection
- **Idempotent**: Safe to run multiple times - always reaches desired state  
- **Clean output**: Silent on success, shows errors only when needed
- **Optional GUI**: 30-second timeout prompt for GUI applications
- **Shell setup**: Automatic zsh configuration and shell switching

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