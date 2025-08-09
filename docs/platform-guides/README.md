# Platform Guides

This directory contains detailed guides for each supported platform.

## Available Guides

- [**macOS Setup Guide**](macos.md) - Complete setup guide for macOS development environments
- [**Windows Setup Guide**](windows.md) - Complete setup guide for Windows development environments
- [**Ubuntu Setup Guide**](ubuntu.md) - Complete setup guide for Ubuntu development environments

## Platform Comparison

| Feature | macOS | Windows | Ubuntu |
|---------|-------|---------|--------|
| **Primary Package Manager** | Homebrew | Chocolatey | APT + Snap |
| **Automation Engine** | Ansible | PowerShell | Ansible |
| **Prerequisites** | Xcode Command Line Tools | PowerShell 5.1+ | Python 3 + pip |
| **Elevation Required** | Yes (Keychain) | Yes (Run as Administrator) | Yes (sudo) |
| **Container Support** | Docker Desktop | Docker Desktop | Docker + Podman |
| **GUI Applications** | Homebrew Casks | Chocolatey | Snap Packages |
| **Language Runtimes** | Multiple via Homebrew | Multiple via Chocolatey | Multiple via APT/Snap |

## Choosing a Platform

### macOS

**Best for:**

- iOS/macOS development
- Unix-based development workflows
- Apple ecosystem integration
- Design and creative work

**Key strengths:**

- Excellent hardware optimization
- Strong Unix foundation
- Premium development tools
- Consistent user experience

### Windows

**Best for:**

- .NET development
- Enterprise environments
- Gaming development
- Mixed platform teams

**Key strengths:**

- Native .NET ecosystem
- Excellent Visual Studio integration
- WSL for Linux compatibility
- Strong enterprise tooling

### Ubuntu

**Best for:**

- Server-side development
- Open source projects
- DevOps and cloud development
- Cost-conscious environments

**Key strengths:**

- Free and open source
- Excellent package management
- Strong community support
- Great for containerized development

## Common Setup Features

All platforms provide:

### Development Tools

- Git with LFS support
- Visual Studio Code with extensions
- Docker for containerization
- Multiple language runtimes (Python, Node.js, etc.)
- Cloud CLI tools (AWS, Azure)

### Package Management

- Declarative configuration via YAML files
- Idempotent installation (safe to run multiple times)
- Comprehensive logging and error handling
- Custom command and script support

### Customization

- Easy package list modification
- System preference configuration
- Custom script execution
- Environment-specific configurations

## Getting Started

1. Choose your platform from the links above
2. Review the prerequisites for your chosen platform
3. Clone or download this repository
4. Follow the platform-specific quick start guide
5. Customize the configuration files as needed

## Cross-Platform Considerations

### File Paths

- **macOS/Ubuntu**: Use forward slashes (`/`)
- **Windows**: Use backslashes (`\`) or forward slashes in PowerShell

### Line Endings

- **macOS/Ubuntu**: LF (`\n`)
- **Windows**: CRLF (`\r\n`)

### Shell Differences

- **macOS/Ubuntu**: Bash/Zsh with Unix commands
- **Windows**: PowerShell with .NET cmdlets

### Package Names

Package names may differ between platforms. Consult the platform-specific documentation for equivalent packages.

## Support Matrix

| Platform Version | Support Status | Notes |
|------------------|----------------|-------|
| macOS 12+ (Monterey) | ✅ Full Support | Recommended |
| macOS 11 (Big Sur) | ✅ Full Support | Tested |
| macOS 10.15 (Catalina) | ⚠️ Limited | Some packages may not work |
| Windows 11 | ✅ Full Support | Recommended |
| Windows 10 | ✅ Full Support | Requires PowerShell 5.1+ |
| Windows Server 2019+ | ✅ Full Support | Server environments |
| Ubuntu 24.04 LTS | ✅ Full Support | Recommended |
| Ubuntu 22.04 LTS | ✅ Full Support | Tested |
| Ubuntu 20.04 LTS | ⚠️ Limited | Some packages may be outdated |
| WSL Ubuntu | ✅ Full Support | Windows Subsystem for Linux |
