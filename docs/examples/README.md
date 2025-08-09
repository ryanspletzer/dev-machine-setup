# Examples and Use Cases

This directory contains real-world examples and use cases for customizing the dev-machine-setup project to meet specific development needs.

## Available Examples

### Workflow-Based Configurations
- [**Web Development Setup**](web-development.md) - Frontend and backend web development
- [**Mobile Development Setup**](mobile-development.md) - iOS, Android, and cross-platform mobile development
- [**DevOps Engineering Setup**](devops-engineering.md) - Infrastructure, containers, and automation tools
- [**Data Science Setup**](data-science.md) - Python, R, Jupyter, and ML/AI tools
- [**Game Development Setup**](game-development.md) - Unity, Unreal, and indie game development tools

### Environment-Based Configurations
- [**Corporate/Enterprise Setup**](corporate-setup.md) - Enterprise tools and security requirements
- [**Freelancer/Consultant Setup**](freelancer-setup.md) - Multi-client development environment
- [**Student/Learning Setup**](student-setup.md) - Educational tools and learning resources
- [**Open Source Contributor Setup**](open-source-setup.md) - Contributing to open source projects

### Platform-Specific Examples
- [**Apple Silicon Mac Setup**](apple-silicon-mac.md) - Optimized for M1/M2/M3 Macs
- [**WSL Development Setup**](wsl-development.md) - Windows Subsystem for Linux development
- [**Minimal Setup**](minimal-setup.md) - Lightweight configuration with essential tools only
- [**Maximum Setup**](maximum-setup.md) - Comprehensive setup with extensive tooling

## How to Use These Examples

### 1. Copy and Customize

Each example provides a complete `vars.yaml` configuration that you can use as a starting point:

```bash
# Copy an example configuration
cp docs/examples/web-development.md web-dev-vars.yaml

# Customize for your needs
vim web-dev-vars.yaml

# Run setup with your custom configuration
./setup.sh web-dev-vars.yaml
```

### 2. Merge Multiple Examples

Combine different examples to create a hybrid setup:

```bash
# Start with web development base
cp docs/examples/web-development.md my-vars.yaml

# Add DevOps tools from another example
# (manually merge the package lists)

# Run your combined setup
./setup.sh my-vars.yaml
```

### 3. Extract Specific Sections

Take only the parts you need from different examples:

```yaml
# Take database tools from data science example
homebrew_formulae:
  - postgresql
  - redis
  - mongodb

# Take frontend tools from web development example
homebrew_casks:
  - figma
  - sketch
```

## Example Categories Explained

### By Development Focus

**Web Development**
- Frontend frameworks (React, Vue, Angular)
- Backend tools (Node.js, databases)
- Design tools (Figma, browsers for testing)
- Performance and debugging tools

**Mobile Development**
- Platform-specific SDKs (Xcode, Android Studio)
- Cross-platform frameworks (Flutter, React Native)
- Simulators and device testing tools
- App store deployment tools

**DevOps Engineering**
- Container orchestration (Docker, Kubernetes)
- Infrastructure as Code (Terraform, Ansible)
- Cloud platform tools (AWS, Azure, GCP)
- Monitoring and logging tools

**Data Science**
- Statistical computing languages (Python, R)
- Jupyter notebooks and IDEs
- Machine learning libraries
- Database and big data tools

### By Environment Type

**Corporate/Enterprise**
- Security and compliance tools
- Enterprise communication platforms
- VPN and remote access tools
- Company-specific development tools

**Freelancer/Consultant**
- Multiple client management tools
- Time tracking and invoicing
- Diverse technology stacks
- Presentation and proposal tools

**Student/Learning**
- Educational IDEs and tools
- Free alternatives to paid software
- Tutorial and documentation tools
- Code learning platforms

### By Setup Philosophy

**Minimal Setup**
- Only essential tools
- Lightweight applications
- Focus on core functionality
- Optimized for performance

**Maximum Setup**
- Comprehensive tool collection
- Multiple alternatives for each function
- Latest and experimental tools
- Rich feature sets

## Custom Example Template

Use this template to create your own example configurations:

```yaml
# =================================================
# [Your Setup Name] Development Environment
# =================================================
# Description: Brief description of what this setup is for
# Use cases: Who should use this configuration
# Platform: macOS/Windows/Ubuntu specific notes if any

# Git Configuration
git_user_email: ''  # Set via command line
git_user_name: ''   # Will use system default if not specified

# Package Manager Configuration
[platform]_packages:
  # =================================
  # Category 1: Core Tools
  # =================================
  - tool1            # Brief description
  - tool2            # Brief description

  # =================================
  # Category 2: Development Tools
  # =================================
  - dev-tool1        # Brief description
  - dev-tool2        # Brief description

# VS Code Extensions
vscode_extensions:
  # Language Support
  - publisher.language-extension

  # Productivity
  - publisher.productivity-extension

# Custom Commands
custom_commands_user:
  # System preferences
  - command1
  - command2

# Optional: Custom Script
custom_script: './examples/custom_setup_script.sh'
```

## Contributing Examples

### Adding New Examples

1. **Identify a gap**: Look for common use cases not covered by existing examples
2. **Create comprehensive configuration**: Include all relevant tools and settings
3. **Test thoroughly**: Ensure the configuration works on target platforms
4. **Document well**: Explain the use case and tool choices
5. **Provide context**: Include setup instructions and customization tips

### Example Guidelines

**Good examples:**
- Solve specific, common problems
- Include explanatory comments
- Are well-tested and working
- Follow project configuration patterns
- Include customization suggestions

**Avoid:**
- Highly personal/niche configurations
- Untested or experimental setups
- Configurations with proprietary/paid-only tools
- Examples that duplicate existing ones without added value

### Example Structure

Each example should include:

```markdown
# [Setup Name]

## Overview
Brief description of the setup and target audience.

## Use Cases
- Specific scenario 1
- Specific scenario 2
- Specific scenario 3

## Tools Included
- **Category 1**: tool1, tool2, tool3
- **Category 2**: tool4, tool5, tool6

## Configuration

\```yaml
# Complete vars.yaml configuration here
\```

## Post-Setup Steps
Manual steps needed after running the automated setup.

## Customization Tips
How to adapt this setup for different needs.

## Platform Notes
Any platform-specific considerations or alternatives.
```

## Finding the Right Example

### Decision Tree

**What's your primary development focus?**
- Web applications → Web Development Setup
- Mobile apps → Mobile Development Setup
- Infrastructure/DevOps → DevOps Engineering Setup
- Data analysis/ML → Data Science Setup
- Games → Game Development Setup

**What's your environment type?**
- Corporate job → Corporate/Enterprise Setup
- Freelance work → Freelancer/Consultant Setup
- Learning/education → Student/Learning Setup
- Open source projects → Open Source Contributor Setup

**What's your preference for setup complexity?**
- Just the essentials → Minimal Setup
- Everything I might need → Maximum Setup
- Balanced approach → Workflow-specific examples

### Mixing and Matching

Most developers benefit from combining elements from multiple examples:

```yaml
# Base: Web Development (primary focus)
# + Elements from: DevOps (deployment knowledge)
# + Elements from: Corporate (security tools)
# + Elements from: Minimal (performance focus)
```

## Community Examples

We welcome community-contributed examples! If you have a configuration that works well for a specific use case, consider contributing it:

1. **Create the example** following our guidelines
2. **Test it thoroughly** on relevant platforms
3. **Submit a pull request** with the new example
4. **Engage with feedback** during the review process

Popular community examples will be featured and maintained as part of the project.

## Getting Help with Examples

If you need help choosing or customizing an example:

1. **Review existing examples** to understand the patterns
2. **Check the documentation** for configuration details
3. **Ask in GitHub discussions** for advice on your specific use case
4. **Open an issue** if you find problems with existing examples

These examples represent real-world usage patterns and can save you significant time in setting up your development environment. Choose the one closest to your needs and customize from there!
