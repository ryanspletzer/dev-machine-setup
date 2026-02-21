# Architecture Overview

This document provides a high-level view of how the dev-machine-setup project is structured
and how its components work together to provide automated development environment setup
across multiple platforms.

## Repository Structure

```text
dev-machine-setup/
├── README.md                    # Project overview and quick start
├── LICENSE                      # MIT license
├── examples/                    # Cross-platform example configurations
│   ├── macOS_vars.yaml         # Example macOS configuration
│   ├── windows_vars.yaml       # Example Windows configuration
│   ├── ubuntu_vars.yaml        # Example Ubuntu configuration
│   ├── fedora_vars.yaml        # Example Fedora configuration
│   └── *_custom_script.*       # Example custom scripts
├── docs/                       # Comprehensive documentation
│   ├── README.md               # Documentation index
│   ├── design-principles.md    # Core design principles
│   ├── architecture.md         # This document
│   └── ...                     # Additional documentation
├── macOS/                      # macOS-specific implementation
│   ├── setup.sh               # Entry point script
│   ├── setup.yaml             # Ansible playbook
│   ├── vars.yaml              # Configuration variables
│   └── examples/              # macOS-specific examples
├── windows/                    # Windows-specific implementation
│   ├── setup.ps1              # PowerShell setup script
│   ├── vars.yaml              # Configuration variables
│   └── examples/              # Windows-specific examples
├── ubuntu/                     # Ubuntu-specific implementation
│   ├── setup.sh               # Entry point script
│   ├── setup.yaml             # Ansible playbook
│   ├── vars.yaml              # Configuration variables
│   └── examples/              # Ubuntu-specific examples
└── fedora/                     # Fedora-specific implementation
    ├── setup.sh               # Entry point script
    ├── setup.yaml             # Ansible playbook
    ├── vars.yaml              # Configuration variables
    └── examples/              # Fedora-specific examples
```

## Component Architecture

### Platform Independence Layer

```mermaid
graph TB
    A[User] --> B[Platform]
    B --> C[macOS Setup]
    B --> D[Windows Setup]
    B --> E[Ubuntu Setup]
    B --> F2[Fedora Setup]

    C --> F[Homebrew + Ansible]
    D --> G[Chocolatey + PowerShell]
    E --> H[APT/Snap + Ansible]
    F2 --> H2[DNF/Flatpak + Ansible]

    F --> I[Configured Development Environment]
    G --> I
    H --> I
    H2 --> I
```

Each platform provides:

- **Entry Point**: Consistent script parameter interface across platforms
- **Package Management**: Platform-native package managers
- **Configuration**: Platform-specific variable files
- **Automation**: Platform-appropriate automation tools

### macOS Architecture

```mermaid
graph LR
    A[setup.sh] --> B[Install Prerequisites]
    B --> C[Homebrew]
    B --> D[Ansible]
    D --> E[setup.yaml Playbook]
    E --> F[vars.yaml Config]

    F --> G[Homebrew Packages]
    F --> H[PowerShell Modules]
    F --> I[Python Packages]
    F --> J[VS Code Extensions]
    F --> K[System Preferences]

    subgraph "Package Managers"
        G --> L[brew install]
        H --> M[Install-PSResource]
        I --> N[pipx install]
        J --> O[code --install-extension]
    end
```

**Key Components:**

- `setup.sh`: Bash script that handles prerequisites and launches Ansible
- `setup.yaml`: Ansible playbook with tagged tasks for different components
- `vars.yaml`: YAML configuration file with package lists and settings
- **Homebrew**: Primary package manager for CLI tools and applications
- **Ansible**: Automation engine providing idempotent configuration

### Windows Architecture

```mermaid
graph LR
    A[setup.ps1] --> B[Install Prerequisites]
    B --> C[Chocolatey]
    B --> D[PowerShell Modules]

    A --> E[vars.yaml Config]
    E --> F[Chocolatey Packages]
    E --> G[PowerShell Modules]
    E --> H[Python Packages]
    E --> I[VS Code Extensions]
    E --> J[System Settings]

    subgraph "Package Managers"
        F --> K[choco install]
        G --> L[Install-PSResource]
        H --> M[pipx install]
        I --> N[code --install-extension]
    end
```

**Key Components:**

- `setup.ps1`: PowerShell script that handles the entire setup process
- `vars.yaml`: YAML configuration file (parsed by PowerShell-Yaml module)
- **Chocolatey**: Primary package manager for applications and tools
- **PowerShell**: Native automation and package management capabilities

### Ubuntu Architecture

```mermaid
graph LR
    A[setup.sh] --> B[Install Prerequisites]
    B --> C[APT Packages]
    B --> D[Ansible]
    D --> E[setup.yaml Playbook]
    E --> F[vars.yaml Config]

    F --> G[APT Packages]
    F --> H[Snap Packages]
    F --> I[PowerShell Modules]
    F --> J[Python Packages]
    F --> K[VS Code Extensions]

    subgraph "Package Managers"
        G --> L[apt install]
        H --> M[snap install]
        I --> N[Install-PSResource]
        J --> O[pipx install]
        K --> P[code --install-extension]
    end
```

**Key Components:**

- `setup.sh`: Bash script that handles prerequisites and launches Ansible
- `setup.yaml`: Ansible playbook with tagged tasks for different components
- `vars.yaml`: YAML configuration file with package lists and settings
- **APT**: System package manager for CLI tools and libraries
- **Snap**: Application package manager for GUI applications
- **Ansible**: Automation engine providing idempotent configuration

### Fedora Architecture

```mermaid
graph LR
    A[setup.sh] --> B[Install Prerequisites]
    B --> C[DNF Packages]
    B --> D[Ansible]
    D --> E[setup.yaml Playbook]
    E --> F[vars.yaml Config]

    F --> G[DNF Packages]
    F --> H[Flatpak Packages]
    F --> I[PowerShell Modules]
    F --> J[Python Packages]
    F --> K[VS Code Extensions]

    subgraph "Package Managers"
        G --> L[dnf install]
        H --> M[flatpak install]
        I --> N[Install-PSResource]
        J --> O[pipx install]
        K --> P[code --install-extension]
    end
```

**Key Components:**

- `setup.sh`: Bash script that handles prerequisites and launches Ansible
- `setup.yaml`: Ansible playbook with tagged tasks for different components
- `vars.yaml`: YAML configuration file with package lists and settings
- **DNF**: System package manager for CLI tools and libraries
- **Flatpak**: Application package manager for GUI applications
- **Ansible**: Automation engine providing idempotent configuration

## Data Flow

### Configuration Processing

```mermaid
sequenceDiagram
    participant User
    participant EntryScript as Entry Script
    participant Config as vars.yaml
    participant PackageManager as Package Managers
    participant System as System Configuration

    User->>EntryScript: Run setup with options
    EntryScript->>Config: Load configuration
    Config-->>EntryScript: Return package lists & settings

    loop For each package type
        EntryScript->>PackageManager: Install packages
        PackageManager-->>EntryScript: Installation status
    end

    EntryScript->>System: Apply system preferences
    System-->>EntryScript: Configuration complete
    EntryScript-->>User: Setup complete
```

### Package Installation Flow

1. **Load Configuration**: Read `vars.yaml` and merge with command-line parameters
2. **Install Prerequisites**: Ensure package managers and automation tools are available
3. **Process Package Lists**: Install packages by category (CLI tools, applications, extensions, etc.)
4. **Configure System**: Apply system preferences and configurations
5. **Run Custom Commands**: Execute user-defined commands and scripts
6. **Cleanup**: Remove temporary files and credentials

## Package Management Strategy

### Package Categories

Each platform organizes packages into logical categories:

| Category | macOS | Windows | Ubuntu | Fedora |
| -------- | ----- | ------- | ------ | ------ |
| CLI Tools | `homebrew_formulae` | `choco_packages` | `apt_packages` | `dnf_packages` |
| Applications | `homebrew_casks` | `choco_packages` | `snap_packages` | `flatpak_packages` |
| VS Code Extensions | `vscode_extensions` | `vscode_extensions` | `vscode_extensions` | `vscode_extensions` |
| PowerShell Modules | `powershell_modules` | `powershell_modules` | `powershell_modules` | `powershell_modules` |
| Python Packages | `pipx_packages` | `pipx_packages` | `pipx_packages` | `pipx_packages` |
| Node.js Packages | `npm_global_packages` | `npm_global_packages` | `npm_global_packages` | `npm_global_packages` |
| .NET Tools | `dotnet_tools` | `dotnet_tools` | `dotnet_tools` | `dotnet_tools` |

### Package Manager Integration

```mermaid
graph TD
    A[Package Request] --> B{Platform?}
    B -->|macOS| C[Homebrew]
    B -->|Windows| D[Chocolatey]
    B -->|Ubuntu| E[APT/Snap]
    B -->|Fedora| E2[DNF/Flatpak]

    C --> F{Package Type?}
    D --> G{Package Type?}
    E --> H{Package Type?}
    E2 --> H2{Package Type?}

    F -->|CLI| I[brew install formula]
    F -->|GUI| J[brew install --cask app]

    G -->|Any| K[choco install package]

    H -->|System| L[apt install package]
    H -->|Application| M[snap install app]

    H2 -->|System| L2[dnf install package]
    H2 -->|Application| M2[flatpak install app]

    I --> N[Installed]
    J --> N
    K --> N
    L --> N
    M --> N
    L2 --> N
    M2 --> N
```

## Security Model

### Privilege Escalation

- **Minimal Elevation**: Only request administrator privileges when necessary
- **Scoped Permissions**: Elevated permissions are used only for specific tasks
- **Credential Cleanup**: Temporary credentials are securely removed after use

### Trust Boundaries

```mermaid
graph TB
    A[User Input] --> B[Configuration Validation]
    B --> C[Package Source Verification]
    C --> D[Official Repositories Only]
    D --> E[Package Installation]
    E --> F[System Configuration]

    subgraph "Trust Boundary"
        D
        E
        F
    end

    subgraph "Trusted Sources"
        G[Homebrew Repository]
        H[Chocolatey Community]
        I[Ubuntu Archives]
        I2[Fedora Repositories]
        J[PowerShell Gallery]
        K[VS Code Marketplace]
        K2[Flathub]
    end

    D --> G
    D --> H
    D --> I
    D --> I2
    D --> J
    D --> K
    D --> K2
```

## Extensibility Points

### Configuration Extension

Users can extend the setup through:

1. **Package Lists**: Add/remove packages by editing arrays in `vars.yaml`
2. **Custom Commands**: Define additional commands in `custom_commands_user` and `custom_commands_elevated`
3. **Custom Scripts**: Point to external scripts via the `custom_script` variable
4. **System Preferences**: Modify platform-specific preference commands

### Script Extension

```mermaid
graph LR
    A[Base Setup] --> B[Package Installation]
    B --> C[System Configuration]
    C --> D[Custom Commands]
    D --> E[Custom Script]
    E --> F[Cleanup]

    subgraph "Extension Points"
        D
        E
    end
```

## Error Handling and Recovery

### Retry Logic

- **Network failures**: Automatic retry for download failures
- **Permission issues**: Clear error messages with suggested solutions
- **Package conflicts**: Skip conflicting packages with warnings

### State Management

- **Idempotent operations**: Safe to run multiple times
- **State checking**: Verify current state before making changes
- **Rollback capability**: Some operations support automatic rollback

### Logging Strategy

```mermaid
graph TD
    A[Setup Start] --> B[Timestamped Log File]
    B --> C[Command Execution]
    C --> D[Output Capture]
    D --> E[Error Detection]
    E -->|Success| F[Continue]
    E -->|Error| G[Log Error Details]
    G --> H[Provide Suggestions]
    F --> I[Next Operation]
    H --> I
```

All operations are logged with:

- **Timestamps**: When each operation occurred
- **Command details**: Exact commands executed
- **Output capture**: Full stdout/stderr from operations
- **Error context**: Additional information for troubleshooting

## Performance Considerations

### Parallel Operations

Where possible, the setup performs operations in parallel:

- **Package downloads**: Multiple packages downloaded simultaneously
- **Independent installations**: Non-conflicting packages installed in parallel
- **Platform optimization**: Each platform uses its native parallel capabilities

### Caching Strategy

- **Package managers**: Leverage built-in caching (Homebrew, Chocolatey, APT, DNF)
- **Download caching**: Avoid re-downloading already cached packages
- **State caching**: Remember completed operations to avoid repetition

This architecture provides a robust, maintainable, and extensible foundation
for automated development environment setup across multiple platforms
while maintaining consistency and reliability.
