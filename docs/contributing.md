# Contributing Guide

Thank you for your interest in contributing to the dev-machine-setup project! This guide will help you understand how to contribute effectively to this cross-platform development environment automation project.

## Project Overview

The dev-machine-setup project provides automated scripts and configurations to set up consistent development environments across macOS, Windows, and Ubuntu platforms. The project emphasizes simplicity, reliability, and customizability through declarative configuration files.

## Ways to Contribute

### 1. Bug Reports

Help us improve by reporting issues you encounter:

**Before submitting a bug report:**
- Check existing issues to avoid duplicates
- Test with the latest version
- Gather relevant system information and logs

**Creating a good bug report:**
- Use the issue template provided
- Include system information (OS version, architecture)
- Provide steps to reproduce the issue
- Include relevant log excerpts
- Describe expected vs. actual behavior

### 2. Feature Requests

Suggest improvements or new features:

**Good feature requests include:**
- Clear description of the problem being solved
- Proposed solution or approach
- Use cases and benefits
- Consideration of impact on existing functionality

### 3. Documentation Improvements

Help make the documentation better:

- Fix typos and grammatical errors
- Improve clarity and completeness
- Add missing examples
- Update outdated information
- Translate documentation (if applicable)

### 4. Code Contributions

Contribute directly to the codebase:

- Bug fixes
- New package additions
- Platform support improvements
- Performance optimizations
- Security enhancements

## Development Setup

### Prerequisites

**For macOS development:**
- macOS 10.15+ (Catalina or later)
- Xcode Command Line Tools
- Homebrew (for testing)

**For Windows development:**
- Windows 10/11
- PowerShell 5.1 or later
- Chocolatey (for testing)

**For Ubuntu development:**
- Ubuntu 20.04 LTS or later
- APT package manager
- Snap package manager

### Setting Up Your Development Environment

1. **Fork the repository** on GitHub
2. **Clone your fork locally:**
   ```bash
   git clone https://github.com/yourusername/dev-machine-setup.git
   cd dev-machine-setup
   ```
3. **Create a development branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Test the existing setup** on your platform:
   ```bash
   # Navigate to your platform directory
   cd macOS  # or windows, or ubuntu

   # Run prerequisites only for testing
   ./setup.sh -p  # macOS/Ubuntu
   # or
   .\setup.ps1 -PrerequisitesOnly  # Windows
   ```

## Project Structure

Understanding the project organization:

```
dev-machine-setup/
├── README.md              # Project overview
├── LICENSE                # MIT license
├── docs/                  # Comprehensive documentation
├── examples/              # Example configurations
├── macOS/                 # macOS implementation
│   ├── setup.sh          # Entry point script
│   ├── setup.yaml        # Ansible playbook
│   └── vars.yaml         # Configuration
├── windows/               # Windows implementation
│   ├── setup.ps1         # PowerShell script
│   └── vars.yaml         # Configuration
└── ubuntu/                # Ubuntu implementation
    ├── setup.sh          # Entry point script
    ├── setup.yaml        # Ansible playbook
    └── vars.yaml         # Configuration
```

## Contribution Guidelines

### Code Style and Standards

#### Shell Scripts (macOS/Ubuntu)

```bash
#!/bin/bash
# Use bash shebang for consistency
# Exit on error
set -e

# Use meaningful variable names
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="setup_$(date +"%Y%m%d_%H%M%S").txt"

# Function naming: use snake_case
install_prerequisites() {
    echo "Installing prerequisites..."
}

# Use proper quoting
echo "Installing to: ${INSTALL_DIR}"
```

#### PowerShell Scripts (Windows)

```powershell
#Requires -Version 5.1
[CmdletBinding()]
param()

# Use approved verbs for functions
function Install-Prerequisites {
    [CmdletBinding()]
    param()

    Write-Information "Installing prerequisites..."
}

# Use PascalCase for variables
$InstallPath = "C:\Tools"

# Use splatting for complex commands
$ChocoParams = @{
    PackageName = 'git'
    Force = $true
}
Install-ChocoPackage @ChocoParams
```

#### YAML Configuration Files

```yaml
# Use consistent indentation (2 spaces)
# Group related packages with comments
homebrew_formulae:
  # Version control tools
  - git
  - git-lfs

  # Container tools
  - docker
  - kubectl

# Use descriptive comments
vscode_extensions:
  - github.copilot          # AI-powered code completion
  - ms-python.python        # Python language support
```

### Testing Your Changes

#### Testing Package Additions

1. **Test package availability:**
   ```bash
   # macOS
   brew search new-package

   # Windows
   choco search new-package

   # Ubuntu
   apt search new-package
   ```

2. **Test installation in isolation:**
   ```bash
   # Create minimal test configuration
   cp vars.yaml test_vars.yaml
   # Edit test_vars.yaml to include only your new package

   # Test the installation
   ./setup.sh test_vars.yaml
   ```

#### Testing Script Changes

1. **Syntax validation:**
   ```bash
   # Bash scripts
   bash -n setup.sh

   # PowerShell scripts
   powershell -File setup.ps1 -Syntax
   ```

2. **Test with prerequisites only:**
   ```bash
   ./setup.sh -p
   ```

3. **Test with verbose output:**
   ```bash
   ./setup.sh -vv -e "test@example.com"
   ```

#### Cross-Platform Testing

When possible, test changes across multiple platforms:

- Use virtual machines for different OS versions
- Test on both Intel and Apple Silicon Macs
- Verify Windows 10 and 11 compatibility
- Test different Ubuntu LTS versions

### Documentation Updates

When contributing code changes:

1. **Update relevant README files** in platform directories
2. **Add or update documentation** in the `docs/` directory
3. **Include examples** for new features
4. **Update configuration references** for new variables

### Commit Message Guidelines

Use clear, descriptive commit messages following this format:

```
type(scope): brief description

Detailed explanation if necessary

- List specific changes
- Reference issues: Fixes #123
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```bash
feat(macOS): add Terraform and Vault packages

- Add HashiCorp tap to homebrew_taps
- Include terraform and vault in homebrew_formulae
- Update README with new tools section

Fixes #45
```

```bash
fix(windows): resolve PowerShell execution policy issue

- Set execution policy to RemoteSigned for current user
- Add error handling for policy changes
- Update troubleshooting documentation

Fixes #78
```

## Adding New Packages

### Research Phase

Before adding packages, research:

1. **Package availability** across platforms
2. **Alternative package names** on different platforms
3. **Dependencies** and potential conflicts
4. **Community adoption** and maintenance status

### Package Addition Process

1. **Update configuration files:**
   ```yaml
   # Add to appropriate section in vars.yaml
   homebrew_formulae:     # macOS
     - new-package

   choco_packages:        # Windows
     - name: new-package

   apt_packages:          # Ubuntu
     - new-package
   ```

2. **Test the addition:**
   - Verify package installs correctly
   - Check for conflicts with existing packages
   - Ensure proper functionality after installation

3. **Update documentation:**
   - Add package to relevant README sections
   - Include brief description of what the package provides
   - Update any related documentation

4. **Consider cross-platform equivalents:**
   ```yaml
   # Document platform differences
   # macOS
   homebrew_formulae:
     - package-name

   # Windows
   choco_packages:
     - name: different-package-name  # Different name on Windows

   # Ubuntu
   apt_packages:
     - ubuntu-package-name           # Different name on Ubuntu
   ```

## Adding New Platform Support

### Platform Requirements

New platforms should meet these criteria:

1. **Popular development platform** with significant user base
2. **Mature package management** ecosystem
3. **Automation capabilities** (shell scripting, task automation)
4. **Community support** for maintenance

### Implementation Steps

1. **Create platform directory structure:**
   ```
   newplatform/
   ├── README.md
   ├── setup.sh (or appropriate entry script)
   ├── configuration files
   └── examples/
   ```

2. **Implement core functionality:**
   - Package manager integration
   - System configuration
   - User preference management
   - Custom command execution

3. **Maintain consistency:**
   - Similar command-line interface
   - Equivalent package categories
   - Consistent logging and error handling
   - Compatible customization options

4. **Documentation:**
   - Platform-specific README
   - Integration with main documentation
   - Troubleshooting guide
   - Examples and use cases

## Security Considerations

### Security Review Process

All contributions undergo security review:

1. **No hardcoded credentials** in configuration files
2. **Minimal privilege escalation** - only when necessary
3. **Trusted package sources** only
4. **Input validation** for user-provided data
5. **Secure credential handling** and cleanup

### Reporting Security Issues

**Do not open public issues for security vulnerabilities.**

Instead:
1. Email security concerns to the maintainers privately
2. Provide detailed description of the issue
3. Include steps to reproduce if applicable
4. Allow reasonable time for response and fix

## Review Process

### Pull Request Guidelines

1. **Create focused pull requests** - one feature/fix per PR
2. **Include comprehensive description** of changes
3. **Reference related issues** using keywords (Fixes #123)
4. **Include testing information** - what was tested and how
5. **Update documentation** as needed

### Review Criteria

Pull requests are reviewed for:

- **Code quality** and adherence to project standards
- **Functionality** - does it work as intended
- **Security** - no security vulnerabilities introduced
- **Documentation** - adequate documentation provided
- **Testing** - appropriate testing performed
- **Backward compatibility** - existing functionality preserved

### Review Process Steps

1. **Automated checks** run (if configured)
2. **Maintainer review** of code and documentation
3. **Testing** on relevant platforms
4. **Feedback** provided for necessary changes
5. **Approval** and merge when ready

## Community Guidelines

### Code of Conduct

This project follows a code of conduct based on respect and inclusivity:

- **Be respectful** of different viewpoints and experiences
- **Accept constructive criticism** gracefully
- **Focus on what's best** for the community
- **Show empathy** towards other community members

### Communication

- **Use clear, professional language** in all interactions
- **Be patient** with new contributors
- **Provide constructive feedback** rather than just criticism
- **Help others** learn and improve

### Recognition

Contributors are recognized through:

- **Contributor acknowledgments** in project documentation
- **GitHub contributor statistics**
- **Release notes** mentioning significant contributions

## Getting Help

### Resources for Contributors

- **Documentation**: Complete project documentation in `docs/`
- **Examples**: Real-world examples in `examples/` directories
- **Issue tracker**: GitHub issues for bugs and features
- **Discussions**: GitHub discussions for questions and ideas

### Asking for Help

When you need assistance:

1. **Check existing documentation** first
2. **Search existing issues** for similar problems
3. **Provide context** when asking questions
4. **Be specific** about what you're trying to accomplish

### Mentorship

New contributors can:

- **Start with small issues** labeled "good first issue"
- **Ask questions** in issue comments
- **Request feedback** on draft pull requests
- **Join discussions** to learn from others

## Release Process

### Versioning Strategy

The project follows semantic versioning (SemVer):

- **Major** (X.0.0): Breaking changes
- **Minor** (0.X.0): New features, backward compatible
- **Patch** (0.0.X): Bug fixes, backward compatible

### Release Preparation

Before releases:

1. **Update documentation** with new features
2. **Test across platforms** thoroughly
3. **Update changelog** with all changes
4. **Tag release** with appropriate version number

Thank you for contributing to dev-machine-setup! Your efforts help developers worldwide set up better development environments more easily.
