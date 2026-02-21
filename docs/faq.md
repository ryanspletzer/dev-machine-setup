# Frequently Asked Questions (FAQ)

This document answers common questions about the dev-machine-setup project, its design decisions, and how to use it effectively.

## General Questions

### What is dev-machine-setup?

Dev-machine-setup is a collection of automated scripts and configurations
that help developers quickly set up consistent development environments
across macOS, Windows, Ubuntu, and Fedora platforms.
It uses platform-native package managers and automation tools
to install and configure development tools, applications, and system preferences.

### Why should I use this instead of manual installation?

**Benefits of automated setup:**

- **Speed**: Set up a complete development environment in minutes instead of hours
- **Consistency**: Same tools and configurations across different machines and team members
- **Reproducibility**: Version-controlled configurations that can be shared and replicated
- **Maintenance**: Easy to update and modify your setup as needs change
- **Documentation**: Configurations serve as documentation of your development environment

### Which platforms are supported?

Currently supported platforms:

- **macOS**: 10.15 (Catalina) and later, including Apple Silicon Macs
- **Windows**: Windows 10 and 11 with PowerShell 5.1 or later
- **Ubuntu**: 20.04 LTS and later, including WSL (Windows Subsystem for Linux)
- **Fedora**: 39 and later

### Do I need to be a developer to use this?

While designed for developers,
anyone who wants to automate software installation can benefit.
The project includes configurations for:

- Development tools and programming languages
- Productivity applications
- Creative software
- System utilities and enhancements

## Getting Started

### How do I get started?

1. **Clone or download** the repository
2. **Navigate to your platform directory** (macOS, windows, ubuntu, or fedora)
3. **Review the configuration** in `vars.yaml`
4. **Run the setup script** with your Git email: `./setup.sh -e "your@email.com"`

### What gets installed by default?

Each platform has a curated selection of popular development tools:

**Common across platforms:**

- Git and Git LFS
- Visual Studio Code with extensions
- Docker
- Python, Node.js, and other language runtimes
- Cloud CLI tools (AWS, Azure)
- PowerShell modules for automation

**Platform-specific highlights:**

- **macOS**: Homebrew packages, iTerm2, Rectangle Pro
- **Windows**: Chocolatey packages, Windows Terminal enhancements
- **Ubuntu**: APT and Snap packages, development libraries
- **Fedora**: DNF and Flatpak packages, development libraries

### How long does the setup take?

Setup time varies by platform and internet speed:

- **Prerequisites only**: 2-5 minutes
- **Full setup**: 15-45 minutes depending on package count and download speeds
- **Subsequent runs**: Much faster due to caching and idempotent operations

## Customization Questions

### How do I add or remove packages?

Edit the `vars.yaml` file in your platform directory:

```yaml
# Add packages to the appropriate list
homebrew_formulae:     # macOS CLI tools
  - git
  - docker
  - your-new-tool      # Add this line

# Remove packages by deleting or commenting out lines
# - unwanted-package   # Comment out with #
```

### Can I use different configurations for different purposes?

Yes! Create multiple configuration files:

```bash
# Create work-specific configuration
cp vars.yaml work_vars.yaml
# Edit work_vars.yaml for work tools

# Create personal configuration
cp vars.yaml personal_vars.yaml
# Edit personal_vars.yaml for personal tools

# Run with specific configuration
./setup.sh work_vars.yaml
```

### How do I add custom commands or scripts?

Use the `custom_commands_user` and `custom_commands_elevated` sections:

```yaml
custom_commands_user:
  # Commands that don't require administrator privileges
  - echo "Setting up development directories"
  - mkdir -p ~/Development/personal ~/Development/work

custom_commands_elevated:
  # Commands that require sudo/administrator privileges
  - systemctl enable docker  # Ubuntu example

# Or point to a custom script
custom_script: "./my_custom_setup.sh"
```

### Can I share my configuration with my team?

Absolutely! This is one of the key benefits:

1. **Commit your `vars.yaml`** to version control
2. **Share the configuration file** with team members
3. **Create team-specific branches** for different projects
4. **Document team-specific customizations**

## Technical Questions

### Why do different platforms use different automation tools?

We use the best tool for each platform:

- **macOS**: Ansible + Homebrew (excellent macOS integration)
- **Windows**: PowerShell (native Windows automation)
- **Ubuntu**: Ansible + APT/Snap (mature Linux automation)
- **Fedora**: Ansible + DNF/Flatpak (modern RPM-based automation)

This approach leverages each platform's strengths rather than forcing a one-size-fits-all solution.

### Is it safe to run these scripts?

Yes, with normal precautions:

**Security measures:**

- Only installs from official package repositories
- Uses cryptographically signed packages where available
- Minimal privilege escalation (only when necessary)
- Open source scripts that you can review
- Comprehensive logging of all operations

**Best practices:**

- Review the configuration files before running
- Test on virtual machines or non-critical systems first
- Keep backups of important data

### What happens if the setup fails partway through?

The setup is designed to be resilient:

**Recovery features:**

- **Idempotent operations**: Safe to run multiple times
- **Detailed logging**: All operations logged for troubleshooting
- **Continue on error**: Most failures don't stop the entire setup
- **State checking**: Skips already-completed installations

**Recovery process:**

1. Check the log file for specific errors
2. Fix any identified issues
3. Re-run the setup script (it will skip completed items)

### Can I use this in corporate/enterprise environments?

Yes, but consider your organization's policies:

**Enterprise considerations:**

- **Security policies**: Ensure compliance with software installation policies
- **Network restrictions**: Some packages may be blocked by corporate firewalls
- **Approval processes**: You may need IT approval for certain tools
- **Custom repositories**: May need to use internal package repositories

**Enterprise customization:**

- Create enterprise-specific configurations
- Add corporate security tools and certificates
- Include company-specific development tools
- Configure VPN and proxy settings

## Package Management Questions

### Why are some packages available on one platform but not others?

Package availability varies due to:

- **Platform-specific software** (e.g., Xcode only on macOS)
- **Different package names** (same software, different names)
- **Repository differences** (not all packages in all repositories)
- **Licensing restrictions** (some software has platform-specific licenses)

### How do I find the correct package name?

Search the package repositories:

```bash
# macOS (Homebrew)
brew search package-name

# Windows (Chocolatey)
choco search package-name

# Ubuntu (APT)
apt search package-name

# Ubuntu (Snap)
snap find package-name

# Fedora (DNF)
dnf search package-name

# Fedora (Flatpak)
flatpak search package-name
```

### What if a package I need isn't available?

Several options:

1. **Use custom commands** to install manually
2. **Create custom scripts** for complex installations
3. **Request package addition** to the repository (for popular software)
4. **Use alternative packages** that provide similar functionality

### How do I handle different versions of the same tool?

Most package managers support version pinning:

```yaml
# macOS: Install specific Node.js version
homebrew_formulae:
  - node@18  # LTS version

# Windows: Usually gets latest stable
choco_packages:
  - name: nodejs-lts  # Use LTS-specific package name

# Ubuntu: Pin to specific version via custom commands
custom_commands_user:
  - sudo apt install nodejs=18.* -y
```

## Troubleshooting Questions

### The setup is taking too long. Is this normal?

Long setup times can be normal, but check for:

**Normal delays:**

- First-time package downloads
- Compilation of packages from source
- Network speed limitations

**Possible issues:**

- Network connectivity problems
- Package repository timeouts
- Stuck processes (check with verbose mode `-v`)

**Solutions:**

- Use verbose mode to see current progress
- Check network connectivity
- Consider running prerequisites only first (`-p` flag)

### I'm getting permission errors. What should I do?

Permission errors usually indicate:

**Common causes:**

- Script not run with appropriate privileges
- Package manager permissions not set correctly
- File system restrictions

**Solutions:**

```bash
# macOS: Fix Homebrew permissions
sudo chown -R $(whoami) /usr/local/Cellar

# Ubuntu: Add user to necessary groups
sudo usermod -aG docker $USER

# Windows: Run PowerShell as Administrator
```

### Some packages failed to install. Should I be concerned?

It depends on the failures:

**Usually not concerning:**

- Optional packages that aren't critical
- Packages with known compatibility issues
- Network-related temporary failures (will retry)

**More concerning:**

- Core development tools (Git, editors)
- Package manager failures
- System configuration failures

**What to do:**

1. Check the log files for specific error messages
2. Try re-running the setup (may resolve temporary issues)
3. Remove problematic packages from configuration if not essential
4. Seek help with detailed error messages

## Performance and Optimization

### How can I make the setup faster?

Several optimization strategies:

**Reduce package count:**

- Remove unused packages from configuration
- Use minimal configurations for faster setups

**Improve caching:**

- Keep package manager caches between runs
- Use local mirrors when available

**Parallel processing:**

- Most modern package managers install packages in parallel automatically
- Avoid running multiple setup instances simultaneously

### How much disk space does a full setup require?

Disk space requirements vary significantly:

**Typical ranges:**

- **Minimal setup**: 2-5 GB
- **Standard development setup**: 10-20 GB
- **Comprehensive setup**: 30-50 GB or more

**Major space consumers:**

- IDEs and development environments
- Language runtimes and SDKs
- Container images and virtualization
- Game development tools and assets

### Can I clean up after installation?

Yes, clean up package caches and temporary files:

```bash
# macOS
brew cleanup

# Windows
choco cleancache

# Ubuntu
sudo apt clean && sudo apt autoremove

# Fedora
sudo dnf clean all && sudo dnf autoremove
```

## Advanced Usage

### Can I use this with Infrastructure as Code tools?

Yes! The configurations integrate well with:

**Configuration Management:**

- **Ansible**: Use the YAML configurations as variables
- **Puppet/Chef**: Adapt package lists for other tools
- **Salt**: Convert configurations to Salt states

**Container Integration:**

- Create Dockerfiles based on package lists
- Use configurations in container build processes
- Generate dev containers for VS Code

### How do I contribute back to the project?

We welcome contributions:

1. **Bug reports**: Report issues you encounter
2. **Package additions**: Suggest useful packages to include
3. **Platform support**: Help with additional platform support
4. **Documentation**: Improve documentation and examples
5. **Code contributions**: Bug fixes and feature improvements

See the [Contributing Guide](contributing.md) for detailed information.

### Can I fork this for my organization?

Absolutely! The MIT license allows:

- **Private forks** for internal use
- **Customization** for organization-specific needs
- **Distribution** within your organization
- **Modification** to meet specific requirements

**Best practices for organizational forks:**

- Maintain compatibility with upstream updates
- Document organization-specific changes
- Consider contributing general improvements back
- Set up internal distribution and update mechanisms

## Getting Help

### Where can I get help if I'm stuck?

Several resources available:

1. **Documentation**: Complete documentation in the `docs/` directory
2. **GitHub Issues**: Report bugs or ask questions
3. **Examples**: Real-world examples in `docs/examples/`
4. **Community**: Engage with other users in discussions

### How do I report bugs or request features?

Use GitHub issues:

**For bugs:**

- Include system information and log files
- Provide steps to reproduce the issue
- Describe expected vs. actual behavior

**For feature requests:**

- Explain the use case and benefits
- Provide examples if possible
- Consider contributing the feature yourself

### What information should I include when asking for help?

Helpful information includes:

**System details:**

- Operating system and version
- Architecture (Intel/ARM/x86_64)
- Package manager versions

**Problem details:**

- Exact error messages
- Relevant log file excerpts
- Steps to reproduce
- What you were trying to accomplish

**Configuration:**

- Your `vars.yaml` configuration (remove sensitive info)
- Any custom scripts or modifications
- Command-line options used

This FAQ covers the most common questions about dev-machine-setup.
For additional help, check the other documentation files or open an issue on GitHub!
