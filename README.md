# macOS Developer Machine Setup with Ansible

This repository contains an Ansible playbook for automating the setup of a macOS development environment. It streamlines the installation and configuration of developer tools, applications, and settings - perfect for setting up a fresh macOS machine from scratch.

## Features

The playbook automates the installation and configuration of:

- **Homebrew packages**
  - Taps, formulae, and casks (installed in this specific order to ensure dependencies are available)
- **PowerShell modules**
  - Includes automatic help update
- **pipx modules**
  - Python tools installation
- **Visual Studio Code extensions**
  - Developer productivity extensions
- **Git configuration**
  - User settings and Git LFS setup

## Prerequisites

You can install prerequisites manually (see below), or use the provided script:

### Quick Install (Recommended)

```zsh
./install_prerequisites.sh
```

This script will install Homebrew (if not already installed) and Ansible using Homebrew.

---

Manual steps for reference:

1. **macOS** - This playbook is designed for macOS
2. **Homebrew** - Install using:

   ```zsh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **Ansible** - Install using Homebrew:

   ```zsh
   brew install ansible
   ```

## Installation

### Option 1: If you already have Git installed

1. Clone this repository:

   ```zsh
   git clone https://github.com/yourusername/ansible-devmachinesetup.git
   cd ansible-devmachinesetup
   ```

2. Review and customize the `setup.yaml` file to match your needs:
   - Add/remove packages in the `vars` section
   - Configure Git settings

### Option 2: If you don't have Git installed (fresh macOS)

1. Download the repository as a ZIP file from GitHub:
   - Go to `https://github.com/yourusername/ansible-devmachinesetup`
   - Click the green "Code" button
   - Select "Download ZIP"

2. Extract the ZIP file and navigate to the directory:

   ```zsh
   cd ~/Downloads
   unzip ansible-devmachinesetup-main.zip
   cd ansible-devmachinesetup-main
   ```

3. Review and customize the `setup.yaml` file using a text editor

## Usage

### Run the Complete Setup

To run the entire playbook:

```bash
ansible-playbook setup.yaml
```

### Run Specific Components

You can use tags to run specific parts of the setup:

```bash
# Install only Homebrew packages
ansible-playbook setup.yaml --tags "homebrew"

# Setup PowerShell modules
ansible-playbook setup.yaml --tags "powershell"

# Install pipx modules
ansible-playbook setup.yaml --tags "pipx"

# Install VS Code extensions
ansible-playbook setup.yaml --tags "vscode"

# Configure Git
ansible-playbook setup.yaml --tags "git"
```

You can also combine tags:

```bash
ansible-playbook setup.yaml --tags "homebrew,vscode"
```

### Configuration

#### Git User Settings

The playbook sets Git user information:

- `user.name`: OPTIONAL - Defaults to your macOS full name (from `id -F`)
- `user.email`: REQUIRED - Empty by default and should be set before running

To provide your email when running the playbook:

```bash
ansible-playbook setup.yaml --extra-vars "git_user_email=your.email@example.com"
```

#### Customizing Installed Packages

Edit the `vars` section of `setup.yaml` to customize:

- `homebrew_taps`: Homebrew tap repositories
- `homebrew_formulae`: CLI tools and libraries
- `homebrew_casks`: macOS applications
- `powershell_modules`: PowerShell modules to install
- `pipx_modules`: Python applications to install via pipx
- `vscode_extensions`: VS Code extensions to install

## Running the Scripts

### Using `install_prerequisites.sh`

This script installs Homebrew (if not already installed) and Ansible. To use it:

1. Make the script executable:

   ```zsh
   # Make the script executable with restricted permissions (owner only)
   chmod 700 ./install_prerequisites.sh
   ```

2. Run the script:

   ```zsh
   ./install_prerequisites.sh
   ```

### Using `setup.sh`

The `setup.sh` script installs prerequisites and runs the Ansible playbook. It supports an optional parameter to specify a custom YAML file. If no parameter is provided, it defaults to `setup.yaml`.

1. Make the script executable:

   ```zsh
   # Make the script executable with restricted permissions (owner only)
   chmod 700 ./setup.sh
   ```

2. Run the default setup:

   ```zsh
   ./setup.sh
   ```

3. Run a custom setup with a specific YAML file:

   ```zsh
   ./setup.sh custom_setup.yaml
   ```

These scripts simplify the process of setting up your macOS development environment. Ensure you have the necessary permissions to execute them.

## Maintenance

### Updating the Playbook

1. Edit `setup.yaml` to add new software or configurations
2. Run the playbook again - Ansible will only make the necessary changes

### Running on a New Machine

For convenience, you can use the included shell script to install prerequisites:

```zsh
# For highest security, use chmod 700 to limit access to only the owner
chmod 700 install_prerequisites.sh
./install_prerequisites.sh
```

Or follow these manual steps:

1. Install Homebrew:

   ```zsh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install Ansible using Homebrew:

   ```zsh
   brew install ansible
   ```

3. Download or clone this repository (see Installation section above)

4. Run the playbook:

   ```zsh
   ansible-playbook setup.yaml
   ```

## Troubleshooting

### Common Issues

- **Permission errors**: Some commands may require sudo access
- **Network issues**: Ensure you have a stable internet connection
- **Homebrew errors**: Run `brew doctor` to diagnose Homebrew problems

If you encounter errors with specific tasks, you can run with verbose output:

```bash
ansible-playbook setup.yaml -vvv
```

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
