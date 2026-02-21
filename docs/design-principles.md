# Design Principles

This document outlines the core design principles that guide the development
and architecture of the dev-machine-setup project.
These principles ensure consistency, maintainability,
and usability across all platforms.

## Core Principles

### 1. Simplicity First

> *"Simple is better than complex"*

- **Flat Configuration Structure**: All package lists are simple, flat arrays in YAML files
- **No Complex Dependencies**: Avoid nested configurations or complex dependency graphs
- **Readable Code**: Scripts and playbooks should be easily understood by anyone
- **Clear Naming**: Variables, files, and functions use descriptive, self-documenting names

**Example:**

```yaml
homebrew_formulae:
  - git
  - docker
  - node
  # Simple, flat list - no nesting or complex structures
```

### 2. File-Based Configuration

> *"Configuration as code, stored in files"*

- **Version Controllable**: All configuration is stored in files that can be tracked in Git
- **Human Readable**: Use YAML (Unix) and PowerShell data structures (Windows) for configuration
- **Single Source of Truth**: Each platform has one primary configuration file (`vars.yaml` or similar)
- **No Runtime Discovery**: Avoid dynamic package discovery or runtime configuration generation

**Why this matters:**

- Easy to review changes via Git diffs
- Can be shared and versioned across teams
- Predictable outcomes - what you see in the file is what gets installed
- Easy to backup and restore configurations

### 3. Package Manager Integration

> *"Leverage native and community package managers for reliable installations"*

Every package, tool, or application must be installed through a recognized package manager:

#### macOS

- **Homebrew** for CLI tools (`homebrew_formulae`)
- **Homebrew Casks** for GUI applications (`homebrew_casks`)
- **pipx** for Python tools (`pipx_packages`)
- **npm** for Node.js packages (`npm_global_packages`)
- **PowerShell Gallery** for PowerShell modules (`powershell_modules`)
- **.NET CLI** for .NET tools (`dotnet_tools`)

#### Windows

- **Chocolatey** for applications and tools (`choco_packages`)
- **PowerShell Gallery** for PowerShell modules (`powershell_modules`)
- **npm** for Node.js packages (`npm_global_packages`)
- **pipx** for Python tools (`pipx_packages`)

#### Ubuntu

- **APT** for system packages (`apt_packages`)
- **Snap** for applications (`snap_packages`)
- **pipx** for Python tools (`pipx_packages`)
- **PowerShell Gallery** for PowerShell modules (`powershell_modules`)

#### Fedora

- **DNF** for system packages (`dnf_packages`)
- **Flatpak** for applications (`flatpak_packages`)
- **pipx** for Python tools (`pipx_packages`)
- **PowerShell Gallery** for PowerShell modules (`powershell_modules`)

**Benefits:**

- Automatic dependency resolution
- Consistent update mechanisms
- Security through trusted repositories
- Easy uninstallation and cleanup

### 4. Platform-Specific Implementation, Unified Experience

> *"Use the best tool for each platform while maintaining consistency"*

Each platform uses its native tools and conventions:

- **macOS**: Bash + Ansible playbooks
- **Windows**: PowerShell scripts with native cmdlets
- **Ubuntu**: Bash + Ansible playbooks
- **Fedora**: Bash + Ansible playbooks

But all platforms provide:

- Similar command-line interface (`-e` for email, `-v` for verbose, etc.)
- Comparable package categories and functionality
- Consistent logging and error handling
- Similar customization capabilities

### 5. Declarative Over Imperative

> *"Describe what you want, not how to get it"*

- **Configuration files describe the desired end state**, not the steps to achieve it
- **Idempotent execution**: Running the setup multiple times produces the same result
- **Ansible** (macOS/Ubuntu) naturally provides this through its design
- **PowerShell scripts** use conditional logic to check existing state before making changes

**Example of declarative approach:**

```yaml
vscode_extensions:
  - github.copilot
  - ms-python.python
  - golang.go
```

The system figures out which extensions are already installed and only installs missing ones.

### 6. Customization Through Configuration

> *"Extend through data, not code"*

- **No forking required**: Customize by editing configuration files
- **Multiple customization points**:
  - Package lists (add/remove packages)
  - Custom commands (`custom_commands_user`, `custom_commands_elevated`)
  - Custom scripts (`custom_script` variable)
  - System preferences (macOS preferences, Windows registry settings)
- **Examples provided**: Each platform includes example configurations

### 7. Zero Manual Dependencies

> *"Everything needed should be installable automatically"*

The setup process should require minimal manual intervention:

- **Prerequisite installation**: Scripts automatically install package managers and automation tools
- **Authentication handled securely**: Prompts for credentials only when necessary
- **Network accessible**: All packages come from public repositories
- **Permission handling**: Scripts properly handle elevation when required

### 8. Logging and Transparency

> *"Always know what's happening"*

- **Comprehensive logging**: All operations logged to timestamped files
- **Verbose modes**: Multiple levels of verbosity (`-v`, `-vv`, `-vvv`)
- **Clear progress indicators**: Users can see what's being installed and configured
- **Error visibility**: Problems are clearly reported with actionable information

### 9. Security-Conscious Design

> *"Secure by default, transparent about privileges"*

- **Minimal privilege escalation**: Only elevate permissions when necessary
- **Credential cleanup**: Temporary credentials are properly cleaned up
- **Trusted sources**: Only use official package repositories
- **User awareness**: Clear indication when administrative privileges are required

### 10. Documentation-Driven Development

> *"Code without documentation doesn't exist"*

- **Self-documenting configuration**: Extensive comments in all configuration files
- **Comprehensive README files**: Each platform has detailed setup and customization documentation
- **Examples provided**: Real-world examples for common customization scenarios
- **Architecture documentation**: This principles document and related architecture docs

## Anti-Patterns We Avoid

### ❌ Complex Configuration Hierarchies

```yaml
# DON'T DO THIS
packages:
  development:
    languages:
      python:
        packages:
          - name: requests
            version: ">=2.0"
            post_install:
              - pip install additional-package
```

### ❌ Runtime Package Discovery

```bash
# DON'T DO THIS
for package in $(curl -s api.example.com/recommended-packages); do
  brew install $package
done
```

### ❌ Manual Installation Steps

```bash
# DON'T DO THIS
echo "Please manually download and install XYZ from https://example.com"
echo "Then press any key to continue..."
read
```

### ❌ Platform-Specific Packages in Shared Config

```yaml
# DON'T DO THIS - mixing platform-specific packages
packages:
  - git              # ✅ Available everywhere
  - chocolatey       # ❌ Windows-only
  - homebrew         # ❌ macOS-only
  - apt-get          # ❌ Ubuntu-only
```

## Evolution of These Principles

These principles emerged from real-world usage and common pain points:

1. **Started complex**: Initial versions had nested configurations and complex dependency management
2. **Learned simplicity**: Flat lists proved much easier to maintain and understand
3. **Embraced platform differences**: Rather than forcing uniformity, we embraced each platform's strengths
4. **Added customization**: Users needed ways to extend without forking the entire project
5. **Focused on reliability**: Idempotent execution and proper error handling became crucial

## Measuring Success

We know these principles are working when:

- ✅ New users can understand and customize the configuration in minutes
- ✅ The setup completes successfully on a fresh machine without manual intervention
- ✅ Changes to package lists are simple Git diffs
- ✅ Platform maintainers can focus on their platform without affecting others
- ✅ Users can easily share and version their configurations
- ✅ The setup remains fast and reliable as package lists grow

These principles guide every decision in the project,
from the choice of automation tools to the structure of configuration files.
They ensure that the project remains maintainable, usable,
and reliable as it evolves.
