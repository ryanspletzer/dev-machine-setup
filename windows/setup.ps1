#Requires -RunAsAdministrator
#Requires -Version 5.1

# Installs prerequisites and runs the configuration

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path $_ })]
    [Alias('f')]
    [string]
    $VarsFilePath = 'vars.yaml',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [Alias('e')]
    [string]
    $GitUserEmail,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [Alias('n')]
    [string]
    $GitUserName = (Get-LocalUser -Name $env:USERNAME).FullName
)

#region Additional Input Validation

if ([string]::IsNullOrWhiteSpace($(try { git config --global user.email } catch {})) -and
    [string]::IsNullOrWhiteSpace($PSBoundParameters['GitUserEmail']) -and
    [string]::IsNullOrWhiteSpace(
        (
            Get-Content -Path $VarsFilePath -ErrorAction SilentlyContinue |
                Where-Object -FilterScript { $_ -match 'git_user_email' } |
                ForEach-Object -Process { $_.Split(':')[1].Trim() }
        )
    )) {
    Write-Error -Message "Git user email is not set and no email was provided."
    exit 1
}

# Check if git_user_email was supplied in the vars.yaml file and retrieve it if available
if ([string]::IsNullOrWhiteSpace($GitUserEmail)) {
    $gitUserEmailFromVars = (
        Get-Content -Path $VarsFilePath -ErrorAction SilentlyContinue |
            Where-Object -FilterScript { $_ -match 'git_user_email' } |
            ForEach-Object -Process { $_.Split(':')[1].Trim() }
    )
    if (-not [string]::IsNullOrWhiteSpace($gitUserEmailFromVars)) {
        $GitUserEmail = $gitUserEmailFromVars
    }
}

# If there is no currently set git user.name, ensure that one was provided or that the local user FullName is set
if ([string]::IsNullOrWhiteSpace($(try { git config --global user.name } catch {})) -and
    [string]::IsNullOrWhiteSpace($PSBoundParameters['GitUserName']) -and
    [string]::IsNullOrWhiteSpace(
        (
            Get-Content -Path $VarsFilePath -ErrorAction SilentlyContinue |
                Where-Object -FilterScript { $_ -match 'git_user_name' } |
                ForEach-Object -Process { $_.Split(':')[1].Trim() }
        )
    ) -and
    [string]::IsNullOrWhiteSpace((Get-LocalUser -Name $env:USERNAME).FullName)) {
    # If no name is provided and no local user name is
    Write-Error -Message "Git user.name is not set and no name was provided nor available from local user FullName."
    exit 1
}

# Check if git_user_name was supplied in the vars.yaml file and retrieve it if available
if ([string]::IsNullOrWhiteSpace($GitUserName)) {
    $gitUserNameFromVars = (
        Get-Content -Path $VarsFilePath -ErrorAction SilentlyContinue |
            Where-Object -FilterScript { $_ -match 'git_user_name' } |
            ForEach-Object -Process { $_.Split(':')[1].Trim() }
    )
    if (-not [string]::IsNullOrWhiteSpace($gitUserNameFromVars)) {
        $GitUserName = $gitUserNameFromVars
    }
}

#endregion Additional Input Validation

#region Transcript Setup

# Start Transcript at current path of script
# Use default transcript file format with setup appended
$randomString = -join ((65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$script:TranscriptFile = Join-Path -Path (
    Split-Path -Path $MyInvocation.MyCommand.Path
) -ChildPath "setup_PowerShell_transcript.$env:COMPUTERNAME.${randomString}.${timestamp}.txt"
Start-Transcript -Path $script:TranscriptFile
$script:VerbosePreference = 'Continue'
$script:InformationPreference = 'Continue'

#endregion Transcript Setup

#region Progress Variables

$activity = 'Setting Up Dev Machine'
$step = 0 # Set this at the beginning of each step
$stepText = 'Chocolatey Install' # Set this at the beginning of each step

# Get content of current script file to count of the total steps by looking at Step++ lines
$scriptPath = $MyInvocation.MyCommand.Path
$totalSteps = (
    Get-Content -Path $MyInvocation.MyCommand.Path |
    Where-Object -FilterScript { $_ -eq '$step++' }
).Count

# Single quotes need to be on the outside
$statusText = '"Step $($step.ToString().PadLeft($totalSteps.Count.ToString().Length)) of $totalSteps | $stepText"'

# This script block allows the string above to use the current values of embedded values each time it's run
$statusBlock = [ScriptBlock]::Create($statusText)

#endregion Progress Variables

#region Chocolatey Install

$step++
$stepText = 'Chocolatey Install'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for Chocolatey install...'

# Get
Write-Verbose -Message '[Get] Chocolatey...'
$choco = Get-Command -Name choco -ErrorAction SilentlyContinue

# Test
Write-Verbose -Message '[Test] Chocolatey...'
if ($null -eq $choco) {
    # Set
    Write-Verbose -Message '[Set] Chocolatey is not installed, installing...'
    Invoke-Expression -Command (
        (New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')
    )
    Import-Module -Name $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
    Write-Verbose -Message '[Set] Chocolatey is now installed.'
    Write-Information -MessageData 'Installed Chocolatey.'
} else {
    Write-Information -MessageData 'Chocolatey is already installed.'
}

#endregion Chocolatey Install

#region Install PowerShell (pwsh)

$step++
$stepText = 'Install PowerShell (pwsh)'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for PowerShell (pwsh) install...'

# Get
Write-Verbose -Message '[Get] PowerShell (pwsh)...'
$pwsh = Get-Command -Name pwsh -ErrorAction SilentlyContinue

# Test
Write-Verbose -Message '[Test] PowerShell (pwsh)...'
if ($null -eq $pwsh) {
    # Set
    Write-Verbose -Message '[Set] PowerShell (pwsh) is not installed, installing...'
    choco install pwsh --yes --no-progress
    # Refresh Path
    Update-SessionEnvironment
    Write-Verbose -Message '[Set] Refreshed PATH environment variable.'
    Write-Verbose -Message '[Set] PowerShell (pwsh) is now installed.'
    Write-Information -MessageData 'Installed PowerShell (pwsh).'
} else {
    Write-Information -MessageData 'PowerShell (pwsh) is already installed.'
}

#endregion Install PowerShell (pwsh)

#region Set PSGallery to Trusted in PSResourceGet in PowerShell (pwsh)

$step++
$stepText = 'Set PSGallery to Trusted in PSResourceGet in PowerShell (pwsh)'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking if PSGallery is set to trusted...'

# Get
Write-Verbose -Message '[Get] PSGallery resource repository is trusted...'
$psResourceRepository = pwsh -Command {
    Get-PSResourceRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
}

# Test
Write-Verbose -Message '[Test] PSGallery resource repository is trusted...'
if (-not $psResourceRepository.Trusted) {
    # Set
    Write-Verbose -Message '[Set] PSGallery resource repository is not trusted, setting to trusted...'
    pwsh -Command {
        Set-PSResourceRepository -Name 'PSGallery' -Trusted
    }
    Write-Verbose -Message '[Set] PSGallery resource repository is now trusted.'
    Write-Information -MessageData 'Set PSGallery to trusted in PSResourceGet.'
} else {
    Write-Information -MessageData 'PSGallery resource repository is already trusted.'
}

#endregion Set PSGallery to Trusted in PSResourceGet in PowerShell (pwsh)

#region Install powershell-yaml in PowerShell (pwsh)

$step++
$stepText = 'Install powershell-yaml in PowerShell (pwsh)'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for powershell-yaml module install...'

# Get
Write-Verbose -Message '[Get] powershell-yaml module...'
$yamlPSResource = pwsh -Command {
    Get-PSResource -Name 'powershell-yaml' -ErrorAction SilentlyContinue
}

# Test
Write-Verbose -Message '[Test] powershell-yaml module...'
if ($null -eq $yamlPSResource) {
    # Set
    Write-Verbose -Message '[Set] powershell-yaml module is not installed, installing...'
    pwsh -Command {
        Install-PSResource -Name 'powershell-yaml'
    }
    Write-Verbose -Message '[Set] powershell-yaml module is now installed.'
    Write-Information -MessageData 'Installed powershell-yaml module.'
} else {
    Write-Information -MessageData 'powershell-yaml module is already installed.'
}

#endregion Install powershell-yaml in PowerShell (pwsh)

#region Import Vars file using powershell-yaml in PowerShell (pwsh)

$step++
$stepText = 'Import Vars file using powershell-yaml in PowerShell (pwsh)'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for vars.yaml file...'

# Get
Write-Verbose -Message '[Get] vars.yaml file...'
if (-not (Test-Path -Path $VarsFilePath)) {
    Write-Error -Message "Vars file not found at path: $VarsFilePath"
    Stop-Transcript
    exit 1
}

# Test
Write-Verbose -Message '[Test] vars.yaml file...'
try {
    # Set
    Write-Verbose -Message '[Set] Importing vars.yaml file...'
    $vars = pwsh -Command {
        param ($Path)
        [pscustomobject](ConvertFrom-Yaml -Yaml (Get-Content -Path $Path -Raw) -ErrorAction Stop)
    } -Args $VarsFilePath
    Write-Verbose -Message '[Set] vars.yaml file imported successfully.'
    Write-Information -MessageData 'Imported vars.yaml file successfully.'
} catch {
    Write-Error -Message "Failed to import vars.yaml file: $_"
    Stop-Transcript
    exit 1
}

#endregion Import Vars file using powershell-yaml in PowerShell (pwsh)

#region Enable Windows Optional Features from Vars file

$step++
$stepText = 'Enable Windows Optional Features from Vars file import'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for Windows Optional Features...'

# Get
Write-Verbose -Message '[Get] Windows Optional Features from Vars file import...'
$optionalFeatures = $vars.windows_optional_features

# Test
Write-Verbose -Message '[Test] Windows Optional Features from Vars file import...'
if ($optionalFeatures -and $optionalFeatures.Count -gt 0) {
    foreach ($featureName in $optionalFeatures) {
        Write-Progress -Activity $Activity -Status (
            & $StatusBlock
        ) -CurrentOperation $featureName -PercentComplete ($step / $totalSteps * 100)

        # Get
        Write-Verbose -Message "[Get] Windows Optional Feature: $featureName"
        $feature = Get-WindowsOptionalFeature -FeatureName $featureName -Online -ErrorAction SilentlyContinue
        if ($null -eq $feature) {
            Write-Error -Message "Windows Optional Feature '$featureName' not found."
            continue
        }

        # Test
        Write-Verbose -Message "[Test] Windows Optional Feature: $featureName"
        if ($feature.State -eq 'Enabled') {
            Write-Information -MessageData "Windows Optional Feature '$featureName' is already enabled."
            # Skip to next feature
            continue
        }

        Write-Verbose -Message "[Set] Enabling feature: $featureName"
        try {
            # Set
            Enable-WindowsOptionalFeature -FeatureName $featureName -Online -NoRestart -ErrorAction Stop
            Write-Information -MessageData "Enabled Windows Optional Feature: $featureName."
        } catch {
            Write-Error -Message "Failed to enable Windows Optional Feature: $featureName. Error: $_"
        }
    }
    Write-Verbose -Message '[Set] All specified Windows Optional Features have been processed.'
} else {
    Write-Information -MessageData 'No Windows Optional Features specified in vars.yaml file.'
}

#endregion Enable Windows Optional Features from Vars file

#region Install Chocolatey Packages from Vars file

$step++
$stepText = 'Install Chocolatey Packages from Vars file'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for Chocolatey packages to install...'

# Get
Write-Verbose -Message '[Get] Chocolatey packages from Vars file import...'
$chocoPackages = $vars.choco_packages

# Test
Write-Verbose -Message '[Test] Chocolatey packages from Vars file import...'
if ($chocoPackages -and $chocoPackages.Count -gt 0) {
    foreach ($package in $chocoPackages) {
        Write-Progress -Activity $Activity -Status (
            & $StatusBlock
        ) -CurrentOperation $package.name -PercentComplete ($step / $totalSteps * 100)

        # Get / Test / Set
        Write-Verbose -Message "[Get] / [Test] / [Set] Installing $($package.name) through Chocolatey..."
        $chocoInstallCommandArgs = @()
        $chocoInstallCommandArgs = "install", $package.name
        if ($package.prerelease) {
            $chocoInstallCommandArgs += "--prerelease"
        }

        if (-not [string]::IsNullOrWhiteSpace($package.parameters)) {
            $chocoInstallCommandArgs += "--parameters", "'`"$($package.parameters)`"'"
        }

        $chocoInstallCommandArgs += "--yes", "--no-progress"
        & choco @chocoInstallCommandArgs

        Write-Verbose -Message "[Get] / [Test] / [Set] Installed $($package.name) through Chocolatey."
        Write-Information -MessageData "Idempotently installed $($package.name)."
    }

    # Refresh the PATH environment variable to ensure any new Chocolatey packages are available
    Update-SessionEnvironment
} else {
    Write-Information -MessageData 'No Chocolatey packages specified in vars.yaml file.'
}

#endregion Install Chocolatey Packages from Vars file

#region Install PowerShell (pwsh) Modules from Vars file via PSResourceGet

$step++
$stepText = 'Install PowerShell (pwsh) Modules from Vars file via PSResourceGet'
Write-Information -MessageData 'Checking for PowerShell (pwsh) modules to install via PSResourceGet...'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)

# Get
Write-Verbose -Message '[Get] PowerShell (pwsh) modules from Vars file import...'
$powershellModules = $vars.powershell_modules

# Test
Write-Verbose -Message '[Test] PowerShell (pwsh) modules from Vars file import...'
if ($powershellModules -and $powershellModules.Count -gt 0) {
    foreach ($module in $powershellModules) {
        Write-Progress -Activity $Activity -Status (
            & $StatusBlock
        ) -CurrentOperation $module -PercentComplete ($step / $totalSteps * 100)
        Write-Information -MessageData "Checking for PowerShell (pwsh) module $module..."

        # Get
        Write-Verbose -Message "[Get] PowerShell (pwsh) module: $module"
        $psModule = pwsh -Command {
            param ($module)
            Get-InstalledPSResource -Name $module -ErrorAction SilentlyContinue
        } -Args $module

        # Test
        Write-Verbose -Message "[Test] PowerShell (pwsh) module: $module"
        if ($null -eq $psModule) {
            # Set
            Write-Verbose -Message "[Set] PowerShell (pwsh) module $module is not installed, installing..."
            try {
                pwsh -Command {
                    param ($module)
                    Install-PSResource -Name $module -Scope CurrentUser -ErrorAction Stop
                } -Args $module
                Write-Verbose -Message "[Set] PowerShell (pwsh) module $module is now installed."
                Write-Information -MessageData "Installed PowerShell (pwsh) module: $module."
            } catch {
                Write-Error -Message "Failed to install PowerShell (pwsh) module: $module. Error: $_"
            }
        } else {
            Write-Information -MessageData "PowerShell (pwsh) module $module is already installed."
        }
    }
} else {
    Write-Information -MessageData 'No PowerShell (pwsh) modules specified in vars.yaml file.'
}

#endregion Install PowerShell (pwsh) Modules from Vars file via PSResourceGet

#region Ensure Windows PowerShell NuGet Package Provider is Installed

$step++
$stepText = 'Ensure Windows PowerShell NuGet Package Provider is Installed'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for Windows PowerShell NuGet Package Provider...'

# Get
Write-Verbose -Message '[Get] Windows PowerShell NuGet Package Provider...'
$nuGetPackageProvider = powershell -Command {
    Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue
}

# Test
Write-Verbose -Message '[Test] Windows PowerShell NuGet Package Provider...'
if (($null -eq $nuGetPackageProvider) -or ($nuGetPackageProvider.Version -lt 2.8.5.201)) {
    # Set
    Write-Verbose -Message '[Set] Windows PowerShell NuGet Package Provider is not installed, installing...'
    powershell -Command {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    }
    Write-Verbose -Message ('[Set] Windows PowerShell NuGet Package Provider is now installed.')
    Write-Information -MessageData 'Installed Windows PowerShell NuGet package provider.'
} else {
    Write-Information -MessageData 'Windows PowerShell NuGet package provider is already installed.'
}

#endregion Ensure Windows PowerShell NuGet Package Provider is Installed

#region Ensure Windows PowerShell PSGallery Package Source is Trusted

$step++
$stepText = 'Ensure Windows PowerShell PSGallery Package Source is Trusted'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking Ensure Windows PowerShell PSGallery Package Source is Trusted...'

# Get
Write-Verbose -Message '[Get] Windows PowerShell PSGallery Package Source...'
$packageSource = powershell -Command {
    Get-PackageSource -Name PSGallery
}

# Test
Write-Verbose -Message '[Test] Windows PowerShell PSGallery Package Source...'
if (-not $packageSource.IsTrusted) {
    # Set
    Write-Verbose -Message '[Set] Windows PowerShell PSGallery Package Source is not Trusted, setting...'
    powershell -Command {
        Set-PackageSource -Name PSGallery -Trusted
    }
    Write-Verbose -Message '[Set] Windows PowerShell PSGallery Package Source is now Trusted.'
    Write-Information -MessageData 'Set Windows PowerShell PSGallery Package Source to Trusted.'
} else {
    Write-Information -MessageData 'Windows PowerShell PSGallery Package Source is already set to Trusted.'
}

#endregion Ensure Windows PowerShell PSGallery Package Source is Trusted

#region Install Windows PowerShell Modules from Vars file

$step++
$stepText = 'Install Windows PowerShell Modules from Vars file'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for Windows PowerShell modules to install...'

# Get
Write-Verbose -Message '[Get] Windows PowerShell modules from Vars file import...'
$windowsPowerShellModules = $vars.windows_powershell_modules

# Test
Write-Verbose -Message '[Test] Windows PowerShell modules from Vars file import...'
if ($windowsPowerShellModules -and $windowsPowerShellModules.Count -gt 0) {
    foreach ($module in $windowsPowerShellModules) {
        Write-Progress -Activity $Activity -Status (
            & $StatusBlock
        ) -CurrentOperation $module -PercentComplete ($step / $totalSteps * 100)
        Write-Information -MessageData "Checking for Windows PowerShell module $module..."

        # Get
        Write-Verbose -Message "[Get] Windows PowerShell module: $module"
        $psModule = powershell -Command {
            param ($module)
            Get-Module -Name $module -ListAvailable -ErrorAction SilentlyContinue
        } -Args $module

        # Test
        Write-Verbose -Message "[Test] Windows PowerShell module: $module"
        if ($null -eq $psModule) {
            # Set
            Write-Verbose -Message "[Set] Windows PowerShell module $module is not installed, installing..."
            try {
                powershell -Command {
                    param ($module)
                    Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
                } -Args $module
                Write-Verbose -Message "[Set] Windows PowerShell module $module is now installed."
                Write-Information -MessageData "Installed Windows PowerShell module: $module."
            } catch {
                Write-Error -Message "Failed to install Windows PowerShell module: $module. Error: $_"
            }
        } else {
            Write-Information -MessageData "Windows PowerShell module $module is already installed."
        }
    }
} else {
    Write-Information -MessageData 'No Windows PowerShell modules specified in vars.yaml file.'
}

#endregion Install Windows PowerShell Modules from Vars file

#region Ensure pipx is Installed if Python is Installed

$step++
$stepText = 'Ensure pipx is Installed if Python is Installed'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for pipx installation...'

# Get
Write-Verbose -Message '[Get] pipx...'
$pipx = Get-Command -Name pipx -ErrorAction SilentlyContinue

# Test
Write-Verbose -Message '[Test] pipx...'
if ($null -eq $pipx) {
    # Set
    Write-Verbose -Message '[Set] pipx is not installed, checking for Python installation...'
    $python = Get-Command -Name python -ErrorAction SilentlyContinue

    if ($null -eq $python) {
        Write-Error -Message 'Python is not installed, pipx cannot be installed.'
    } else {
        Write-Verbose -Message '[Set] Python is installed, installing pipx...'
        # Install pipx using Python's pip
        python -m pip install --user pipx
        python -m pipx ensurepath

        # Refresh Path to ensure pipx is in the PATH in the current session
        Update-SessionEnvironment
        Write-Verbose -Message '[Set] pipx is now installed.'
        Write-Information -MessageData 'Installed pipx.'
    }
} else {
    Write-Information -MessageData 'pipx is already installed.'
}

#endregion Ensure pipx is Installed if Python is Installed

#region Ensure pipx Packages from Vars file are Installed

$step++
$stepText = 'Ensure pipx Packages from Vars file are Installed'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for pipx packages to install...'

# Get
Write-Verbose -Message '[Get] pipx packages from Vars file import...'
$pipxPackages = $vars.pipx_packages

# Test
Write-Verbose -Message '[Test] pipx packages from Vars file import...'
if ($pipxPackages -and $pipxPackages.Count -gt 0) {
    # Get the list of currently installed pipx packages
    Write-Verbose -Message '[Get] Currently installed pipx packages...'
    $pipxPackagesInstalled = pipx list --json | ConvertFrom-Json
    foreach ($package in $pipxPackages) {
        Write-Progress -Activity $activity -Status (
            & $StatusBlock
        ) -CurrentOperation $package -PercentComplete ($step / $totalSteps * 100)
        Write-Information -MessageData "Checking for pipx package $package..."

        # Get
        Write-Verbose -Message "[Get] pipx package: $package"
        $pipxPackageInstalled = $pipxPackagesInstalled | Where-Object { $_.name -eq $package }

        # Test
        Write-Verbose -Message "[Test] pipx package: $package"
        if ($null -eq $pipxPackageInstalled) {
            # Set
            Write-Verbose -Message "[Set] pipx package $package is not installed, installing..."
            try {
                pipx install $package
                Write-Verbose -Message "[Set] pipx package $package is now installed."
                Write-Information -MessageData "Installed pipx package: $package."
            } catch {
                Write-Error -Message "Failed to install pipx package: $package. Error: $_"
            }
        } else {
            Write-Information -MessageData "pipx package $package is already installed."
        }
    }
} else {
    Write-Information -MessageData 'No pipx packages specified in vars.yaml file.'
}

#endregion Ensure pipx Packages from Vars file are Installed

#region Install Visual Studio Code Extensions from Vars file if Visual Studio Code is Installed

$step++
$stepText = 'Install Visual Studio Code Extensions from Vars file'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for Visual Studio Code extensions to install...'

# Get
Write-Verbose -Message '[Get] Visual Studio Code extensions from Vars file import...'
$vscodeExtensions = $vars.vscode_extensions

# Test
Write-Verbose -Message '[Test] Visual Studio Code extensions from Vars file import...'
if ($vscodeExtensions -and $vscodeExtensions.Count -gt 0) {
    # Get
    Write-Verbose -Message '[Get] Checking for Visual Studio Code installation...'
    $code = Get-Command -Name code -ErrorAction SilentlyContinue

    # Test
    Write-Verbose -Message '[Test] Visual Studio Code installation...'
    if ($null -eq $code) {
        Write-Error -Message 'Visual Studio Code is not installed, cannot install extensions.'
    } else {
        $vscodeExtensionsInstalled = code --list-extensions
        foreach ($extension in $vscodeExtensions) {
            Write-Progress -Activity $Activity -Status (
                & $StatusBlock
            ) -CurrentOperation $extension -PercentComplete ($step / $totalSteps * 100)
            Write-Information -MessageData "Checking for Visual Studio Code extension $extension..."

            # Get
            Write-Verbose -Message "[Get] Visual Studio Code extension: $extension"
            $vscodeExtensionInstalled = $vscodeExtensionsInstalled |
                Where-Object -FilterScript { $_ -eq $extension }

            # Test
            Write-Verbose -Message "[Test] Visual Studio Code extension: $extension"
            if (-not $vscodeExtensionInstalled) {
                # Set
                Write-Verbose -Message (
                    "[Set] Visual Studio Code extension $extension is not installed, installing..."
                )
                try {
                    code --install-extension $extension
                    Write-Verbose -Message "[Set] Visual Studio Code extension $extension is now installed."
                    Write-Information -MessageData "Installed Visual Studio Code extension: $extension."
                } catch {
                    Write-Error -Message "Failed to install Visual Studio Code extension: $extension. Error: $_"
                }
            } else {
                Write-Information -MessageData "Visual Studio Code extension $extension is already installed."
            }
        }
    }
} else {
    Write-Information -MessageData 'No Visual Studio Code extensions specified in vars.yaml file.'
}

#endregion Install Visual Studio Code Extensions from Vars file if Visual Studio Code is Installed

#region Git user.name and user.email Config

$step++
$stepText = 'Git user.name and user.email Config'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Configuring Git user.name and user.email...'

# Get
Write-Verbose -Message '[Get] Git user.name and user.email...'
$currentGitUserName = git config --global user.name
$currentGitUserEmail = git config --global user.email

# Test
Write-Verbose -Message '[Test] Git user.name...'
if ($currentGitUserName -ne $GitUserName) {
    # Set
    Write-Verbose -Message "[Set] Setting Git user.name to '$GitUserName'..."
    git config --global user.name $GitUserName
    Write-Information -MessageData "Set Git user.name to '$GitUserName'."
} else {
    Write-Information -MessageData "Git user.name is already set to '$currentGitUserName'."
}

# Test
Write-Verbose -Message '[Test] Git user.email...'
if ($currentGitUserEmail -ne $GitUserEmail) {
    # Set
    Write-Verbose -Message "[Set] Setting Git user.email to '$GitUserEmail'..."
    git config --global user.email $GitUserEmail
    Write-Information -MessageData "Set Git user.email to '$GitUserEmail'."
} else {
    Write-Information -MessageData "Git user.email is already set to '$currentGitUserEmail'."
}

#endregion Git user.name and user.email Config

#region Transcript Teardown

Stop-Transcript

Write-Host "`nSetup completed successfully!"
Write-Host "Full log available at: $transcriptFile"

#endregion Transcript Teardown
