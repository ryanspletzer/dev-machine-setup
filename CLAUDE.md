# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code)
when working with code in this repository.

## Project Overview

Cross-platform dev machine setup automation for macOS, Windows, Ubuntu, and Fedora.
Each platform has its own directory with an entry-point script,
an automation engine, and a `vars.yaml` configuration file.

## Architecture

### Platform Automation Engines

| Platform | Entry Point | Automation | Package Manager |
| -------- | ----------- | ---------- | --------------- |
| macOS | `macOS/setup.sh` | Ansible (`setup.yaml`) | Homebrew |
| Windows | `windows/setup.ps1` | Native PowerShell | Chocolatey |
| Ubuntu | `ubuntu/setup.sh` | Ansible (`setup.yaml`) | APT + Snap |
| Fedora | `fedora/setup.sh` | Ansible (`setup.yaml`) | DNF + Flatpak |

All platforms share the same flow:
install prerequisites, load `vars.yaml`, install packages by category,
configure Git, run custom commands, run custom script, clean up.

### Configuration: `vars.yaml`

Each platform's `vars.yaml` is the single source of truth.
Package lists are flat YAML arrays grouped by category:

- **OS packages**: `homebrew_formulae` / `homebrew_casks` / `choco_packages` /
  `apt_packages` / `snap_packages` / `dnf_packages` / `flatpak_packages` /
  `appimage_packages`
- **Cross-platform**: `powershell_modules`, `pipx_packages`, `npm_global_packages`, `dotnet_tools`, `vscode_extensions`
- **Git config**: `git_user_email`, `git_user_name`
- **Custom commands**: `custom_commands_user` (non-elevated), `custom_commands_elevated` (sudo)
- **Custom script**: `custom_script` (path to a script run at the end)

### Key Differences Between Platforms

- **Windows `choco_packages`** uses objects with `name` (required)
  plus optional `parameters` and `prerelease` keys,
  unlike the flat string arrays on other platforms.
- **Windows `custom_commands`** is a single list (not split into user/elevated)
  since the script already runs as Administrator.
- **Ubuntu** has additional `external_apt_repositories` (deb822 format)
  and `apt_packages_prereqs` for bootstrap dependencies.
- **Ubuntu** uses `supported_architectures` on some packages
  to skip amd64-only software on ARM64.
- **Fedora** has `external_dnf_repositories` (yum_repository format)
  and `dnf_packages_prereqs` for bootstrap dependencies.
- **Fedora** uses `supported_architectures` with `x86_64`/`aarch64` values
  (not `amd64`/`arm64` like Ubuntu).
- **Fedora** uses `flatpak_packages` (Flathub app IDs)
  instead of Snap packages.
- **Ubuntu/Fedora** support `appimage_packages` for generic AppImage installation.
  Each entry has `name`, `url`, and optional fields (`comment`, `categories`,
  `mime_types`, `no_sandbox`, `checksum`, `supported_architectures`).
  Cursor is installed this way on Linux; macOS uses Homebrew cask `cursor`,
  Windows uses Chocolatey `cursoride`.
  All platforms reuse the `vscode_extensions` list for Cursor extension installation.

## Running the Setup Scripts

```bash
# macOS
chmod 700 ./macOS/setup.sh
./macOS/setup.sh -e your.email@example.com

# Ubuntu
chmod 700 ./ubuntu/setup.sh
./ubuntu/setup.sh -e your.email@example.com

# Fedora
chmod 700 ./fedora/setup.sh
./fedora/setup.sh -e your.email@example.com
```

```powershell
# Windows (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
.\windows\setup.ps1 -e your.email@example.com
```

Common flags: `-v` (verbose, repeatable), `-e` (git email),
`-n` (git name), `-p` (prerequisites only, macOS/Ubuntu/Fedora).

### Ansible Tags (macOS/Ubuntu/Fedora)

The Ansible playbooks use tags to run specific sections:

```bash
# Run only Homebrew tasks
ansible-playbook setup.yaml --tags homebrew

# Run only VS Code extension installation
ansible-playbook setup.yaml --tags vscode
```

## Editing Guidelines

### Adding Packages

Add to the appropriate list in the platform's `vars.yaml`.
Keep entries alphabetically sorted within their group.
Comment groups organize packages by purpose.

When adding to multiple platforms,
use the correct format for each
(flat strings for macOS/Ubuntu, `name:` objects for Windows choco).

### Commit Messages

Follow conventional commits:

```text
type(scope): brief description
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
Scope is typically the platform name: `macOS`, `windows`, `ubuntu`.

### Code Style

- **Shell scripts**: `#!/bin/sh`, `set -e`, snake_case functions
- **PowerShell**: `#Requires` directives, PascalCase,
  Get/Test/Set pattern with verbose logging
- **YAML**: 2-space indent, comments above entries,
  group related packages with comment headers
- **Ansible tasks**: use `ignore_errors: yes` for package installs,
  `changed_when` for idempotency, tag every task

### Design Principles

- **Flat configuration** -- no nested package structures
- **Declarative** -- `vars.yaml` describes desired end state
- **Idempotent** -- safe to run multiple times
- **Extend through data** -- add packages to `vars.yaml`,
  not code to scripts
