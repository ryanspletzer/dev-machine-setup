# Troubleshooting Guide

This guide helps you diagnose and resolve common issues when setting up development environments with the dev-machine-setup project.

## General Troubleshooting Steps

### 1. Check the Log Files

All setup operations are logged to timestamped files in the current directory:

```bash
# macOS and Ubuntu
ls -la setup_*.txt

# Windows
ls setup_PowerShell_transcript.*.txt
```

Look for error messages, failed commands, or timeout issues in these logs.

### 2. Use Verbose Mode

Run the setup with increased verbosity to get more detailed output:

```bash
# Single verbose flag
./setup.sh -v -e "your@email.com"

# Maximum verbosity (very detailed)
./setup.sh -vvv -e "your@email.com"
```

### 3. Test Prerequisites Only

Install only the prerequisites to isolate issues:

```bash
./setup.sh -p
```

This installs package managers and automation tools without running the full setup.

### 4. Check System Requirements

Ensure your system meets the minimum requirements:

- **macOS**: 10.15+ (Catalina or later)
- **Windows**: Windows 10/11 with PowerShell 5.1+
- **Ubuntu**: 20.04 LTS or later
- **All platforms**: Internet connection and administrator privileges

## Platform-Specific Issues

### macOS Troubleshooting

#### Homebrew Installation Issues

**Problem**: Homebrew installation fails with permission errors
```bash
Error: Cannot write to /usr/local/Cellar
```

**Solution**:
```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) /usr/local/Cellar /usr/local/bin /usr/local/share
```

**Problem**: Command Line Tools not installed
```bash
xcode-select: error: tool 'git' requires Xcode
```

**Solution**:
```bash
# Install Xcode Command Line Tools
xcode-select --install
```

#### Apple Silicon Compatibility

**Problem**: Packages fail on Apple Silicon Macs
```bash
Error: Cannot install under Rosetta 2 in ARM default prefix
```

**Solution**:
```yaml
# In vars.yaml, enable Rosetta 2
install_rosetta: true
```

**Problem**: Some packages require Rosetta 2
```bash
Error: Package requires Intel architecture
```

**Solution**: Install affected packages manually with Rosetta:
```bash
arch -x86_64 brew install package-name
```

#### Keychain Access Issues

**Problem**: Sudo password prompts interfere with automation

**Solution**: The setup script handles this automatically, but if you encounter issues:
```bash
# Clear any cached sudo credentials
sudo -k
# Run setup again
./setup.sh -e "your@email.com"
```

### Windows Troubleshooting

#### PowerShell Execution Policy

**Problem**: Scripts cannot run due to execution policy
```powershell
execution of scripts is disabled on this system
```

**Solution**:
```powershell
# Allow scripts for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Chocolatey Installation Issues

**Problem**: Chocolatey fails to install
```powershell
Exception calling "DownloadString" with "1" argument(s)
```

**Solution**:
```powershell
# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install Chocolatey manually
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

#### Windows Defender Issues

**Problem**: Windows Defender blocks package installations

**Solution**:
1. Add exclusion for Chocolatey directory: `C:\ProgramData\chocolatey`
2. Temporarily disable real-time protection during setup
3. Whitelist the setup script in Windows Defender

#### WSL Integration

**Problem**: VS Code cannot connect to WSL

**Solution**:
```bash
# In WSL terminal
code --install-extension ms-vscode-remote.remote-wsl
```

### Ubuntu Troubleshooting

#### APT Package Issues

**Problem**: Package lists are outdated
```bash
E: Unable to locate package
```

**Solution**:
```bash
sudo apt update && sudo apt upgrade -y
```

**Problem**: Broken package dependencies
```bash
E: Unmet dependencies
```

**Solution**:
```bash
# Fix broken packages
sudo apt --fix-broken install

# Clean package cache
sudo apt autoremove && sudo apt autoclean
```

#### Snap Package Issues

**Problem**: Snap packages fail to install
```bash
error: cannot communicate with server
```

**Solution**:
```bash
# Restart snapd service
sudo systemctl restart snapd

# Check snap status
sudo systemctl status snapd
```

#### Permission Issues

**Problem**: Docker requires sudo

**Solution**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or restart the shell
newgrp docker
```

**Problem**: VS Code cannot write to directories

**Solution**:
```bash
# Fix VS Code directory permissions
sudo chown -R $USER:$USER ~/.vscode
```

## Common Package Issues

### Package Not Found

**Problem**: Specific packages cannot be found in repositories

**Solutions**:

1. **Check package name spelling**:
   ```bash
   # macOS
   brew search package-name

   # Windows
   choco search package-name

   # Ubuntu
   apt search package-name
   ```

2. **Add required repositories**:
   ```yaml
   # macOS: Add tap in vars.yaml
   homebrew_taps:
     - required/tap

   # Ubuntu: Add PPA via custom commands
   custom_commands_elevated:
     - add-apt-repository ppa:required/ppa
   ```

3. **Use alternative package names**:
   ```yaml
   # Try different variations
   homebrew_formulae:
     - package-name
     # - alternative-name  # Try if first fails
   ```

### Version Conflicts

**Problem**: Package conflicts with existing installations

**Solutions**:

1. **Uninstall conflicting packages**:
   ```bash
   # macOS
   brew uninstall conflicting-package

   # Windows
   choco uninstall conflicting-package

   # Ubuntu
   sudo apt remove conflicting-package
   ```

2. **Use specific versions**:
   ```yaml
   # macOS: Pin to specific version
   homebrew_formulae:
     - node@18  # Specific LTS version
   ```

### Network and Download Issues

**Problem**: Downloads fail or timeout

**Solutions**:

1. **Check internet connection**:
   ```bash
   # Test connectivity
   ping google.com
   curl -I https://github.com
   ```

2. **Retry with different mirrors**:
   ```bash
   # macOS: Use different Homebrew mirror
   export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"

   # Ubuntu: Use different mirror
   sudo sed -i 's|archive.ubuntu.com|mirror.example.com|g' /etc/apt/sources.list
   ```

3. **Increase timeout values**:
   ```bash
   # Set longer timeout for downloads
   export HOMEBREW_CURL_TIMEOUT=300
   ```

## VS Code Extension Issues

### Extension Installation Failures

**Problem**: Extensions fail to install
```bash
Error: Extension 'publisher.extension' not found
```

**Solutions**:

1. **Verify extension ID**:
   - Check VS Code marketplace for correct extension ID
   - Ensure proper format: `publisher.extension-name`

2. **Install manually**:
   ```bash
   code --install-extension publisher.extension-name
   ```

3. **Clear extension cache**:
   ```bash
   # Remove VS Code extensions directory
   rm -rf ~/.vscode/extensions
   ```

### Extension Conflicts

**Problem**: Extensions conflict with each other

**Solution**:
1. Disable conflicting extensions temporarily
2. Check extension documentation for known conflicts
3. Use workspace-specific extension settings

## Git Configuration Issues

### Git Credential Issues

**Problem**: Git authentication fails

**Solutions**:

1. **Configure Git credentials**:
   ```bash
   # Set up credential helper (macOS)
   git config --global credential.helper osxkeychain

   # Set up credential helper (Windows)
   git config --global credential.helper manager

   # Set up credential helper (Ubuntu)
   git config --global credential.helper store
   ```

2. **Generate SSH keys**:
   ```bash
   ssh-keygen -t ed25519 -C "your@email.com"
   ssh-add ~/.ssh/id_ed25519
   ```

### Git Configuration Not Applied

**Problem**: Git user settings not configured properly

**Solution**:
```bash
# Verify current configuration
git config --global user.email
git config --global user.name

# Set manually if not configured
git config --global user.email "your@email.com"
git config --global user.name "Your Name"
```

## Performance Issues

### Slow Installation

**Problem**: Setup takes extremely long time

**Solutions**:

1. **Use parallel installation**:
   ```bash
   # macOS: Enable parallel downloads
   echo 'export HOMEBREW_PARALLEL=4' >> ~/.zshrc
   ```

2. **Clean package caches**:
   ```bash
   # macOS
   brew cleanup

   # Windows
   choco cleancache

   # Ubuntu
   sudo apt clean && sudo apt autoremove
   ```

3. **Check available disk space**:
   ```bash
   df -h  # Unix
   Get-WmiObject -Class Win32_LogicalDisk  # Windows
   ```

### High Memory Usage

**Problem**: System becomes unresponsive during installation

**Solutions**:

1. **Close unnecessary applications**
2. **Install packages in smaller batches**
3. **Increase virtual memory/swap space**

## Custom Script Issues

### Script Execution Failures

**Problem**: Custom scripts fail to execute
```bash
Permission denied: ./custom_script.sh
```

**Solution**:
```bash
# Make script executable
chmod +x custom_script.sh
```

**Problem**: Script has wrong interpreter
```bash
bad interpreter: No such file or directory
```

**Solution**:
```bash
# Fix shebang line at top of script
#!/bin/bash  # For bash scripts
#!/bin/sh    # For POSIX shell scripts
```

### Environment Variable Issues

**Problem**: Environment variables not available in custom scripts

**Solution**:
```bash
# Source environment files in script
#!/bin/bash
source ~/.bashrc
source ~/.profile

# Your custom commands here
```

## Getting Additional Help

### Debug Information Collection

When reporting issues, collect this information:

1. **System Information**:
   ```bash
   # macOS
   sw_vers && uname -m

   # Windows
   Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion

   # Ubuntu
   lsb_release -a && uname -m
   ```

2. **Package Manager Versions**:
   ```bash
   # macOS
   brew --version

   # Windows
   choco --version

   # Ubuntu
   apt --version && snap --version
   ```

3. **Log Files**: Include relevant portions of setup log files

4. **Configuration**: Share your `vars.yaml` configuration (remove sensitive information)

### Community Resources

- **GitHub Issues**: Report bugs and feature requests
- **Stack Overflow**: Tag questions with `dev-machine-setup`
- **Documentation**: Check the complete documentation in the `docs/` directory

### Emergency Recovery

If the setup has partially completed and left your system in an inconsistent state:

1. **Review installed packages**:
   ```bash
   # macOS
   brew list

   # Windows
   choco list --local-only

   # Ubuntu
   apt list --installed
   ```

2. **Uninstall problematic packages**:
   ```bash
   # Use package manager uninstall commands
   brew uninstall package-name
   choco uninstall package-name
   sudo apt remove package-name
   ```

3. **Reset package managers**:
   ```bash
   # macOS: Reinstall Homebrew
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

4. **Start fresh**: Re-run the setup with prerequisites only (`-p` flag) to rebuild the foundation

This troubleshooting guide covers the most common issues encountered during setup. For additional help, check the platform-specific README files or open an issue in the project repository.
