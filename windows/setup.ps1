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
    $GitUserName = $(try { (Get-LocalUser -Name $env:USERNAME -ErrorAction Stop).FullName } catch { '' })
)

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

#region Helper Functions

# Pure text-parsing helpers (vars.yaml pre-parsing) live in a separate file
# so the Pester suite in tests/windows can test them without running setup.
. (Join-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path) -ChildPath 'setup-functions.ps1')

#endregion Helper Functions

#region Additional Input Validation

$gitPackageInYaml = Get-ChocoPackageName -Path $VarsFilePath |
    Where-Object -FilterScript { $_ -eq 'git' }

# If git.config --global user.email is not set, ensure that one was provided or that the vars.yaml file has a
# git_user_email entry
if ([string]::IsNullOrWhiteSpace($(if (Get-Command -Name git -ErrorAction SilentlyContinue) { git config --global user.email })) -and
    [string]::IsNullOrWhiteSpace($GitUserEmail) -and
    [string]::IsNullOrWhiteSpace(
        (Get-VarsYamlScalar -Path $VarsFilePath -Key 'git_user_email')
    ) -and
    $gitPackageInYaml) {

    Write-Error -Message "Git user email is not set and no email was provided."
    Stop-Transcript
    exit 1
}

# If GitUserEmail is empty, check if it was supplied in the vars.yaml file
if ([string]::IsNullOrWhiteSpace($GitUserEmail)) {
    $gitUserEmailFromVars = (Get-VarsYamlScalar -Path $VarsFilePath -Key 'git_user_email')
    if (-not [string]::IsNullOrWhiteSpace($gitUserEmailFromVars)) {
        Write-Verbose -Message "Using git_user_email from vars.yaml: $gitUserEmailFromVars"
        $GitUserEmail = $gitUserEmailFromVars
    }
}

# If git.config --global user.name is not set, ensure that one was provided or that the default value is not empty
# or the vars.yaml file has a git_user_name entry
if ([string]::IsNullOrWhiteSpace($(if (Get-Command -Name git -ErrorAction SilentlyContinue) { git config --global user.name })) -and
    [string]::IsNullOrWhiteSpace($PSBoundParameters['GitUserName']) -and
    [string]::IsNullOrWhiteSpace($GitUserName) -and
    [string]::IsNullOrWhiteSpace(
        (Get-VarsYamlScalar -Path $VarsFilePath -Key 'git_user_name')
    ) -and
    $gitPackageInYaml) {

    Write-Error -Message "Git user.name is not set and no name was provided nor available from local user FullName."
    Stop-Transcript
    exit 1
}

# If GitUserName is empty, check if it was supplied in the vars.yaml file
if ([string]::IsNullOrWhiteSpace($GitUserName)) {
    $gitUserNameFromVars = (Get-VarsYamlScalar -Path $VarsFilePath -Key 'git_user_name')
    if (-not [string]::IsNullOrWhiteSpace($gitUserNameFromVars)) {
        Write-Verbose -Message "Using git_user_name from vars.yaml: $gitUserNameFromVars"
        $GitUserName = $gitUserNameFromVars
    }
}

#endregion Additional Input Validation

#region Progress Variables

$activity = 'Setting Up Dev Machine'
$step = 0 # Incremented at the beginning of each step, alongside $stepText

# Get content of current script file to count of the total steps by looking at Step++ lines
$totalSteps = (
    Get-Content -Path $MyInvocation.MyCommand.Path |
    Where-Object -FilterScript { $_ -eq '$step++' }
).Count

# Builds the progress status string from the current values of $step, $totalSteps, and $stepText each time it's called
function Get-StatusText {
    "Step $($step.ToString().PadLeft($totalSteps.ToString().Length)) of $totalSteps | $stepText"
}

#endregion Progress Variables

#region Chocolatey Install

$step++
$stepText = 'Chocolatey Install'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for Chocolatey install...'

# Get
Write-Verbose -Message '[Get] Chocolatey...'
$choco = Get-Command -Name choco -ErrorAction SilentlyContinue

# Test
Write-Verbose -Message '[Test] Chocolatey...'
if ($null -eq $choco) {
    # Set
    Write-Verbose -Message '[Set] Chocolatey is not installed, installing...'
    & ([ScriptBlock]::Create(
        (New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')
    ))
    Import-Module -Name $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
    Write-Verbose -Message '[Set] Chocolatey is now installed.'
    Write-Information -MessageData 'Installed Chocolatey.'
} else {
    Write-Information -MessageData 'Chocolatey is already installed.'
}

# Ensure Chocolatey profile module is loaded (needed for Update-SessionEnvironment)
if ($env:ChocolateyInstall -and (Test-Path "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1")) {
    Import-Module -Name "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -ErrorAction SilentlyContinue
}

#endregion Chocolatey Install

#region Install PowerShell (pwsh)

$step++
$stepText = 'Install PowerShell (pwsh)'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
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
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
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
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
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
        Install-PSResource -Name 'powershell-yaml' -Scope CurrentUser
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
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
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

#region Install Chocolatey Packages from Vars file

$step++
$stepText = 'Install Chocolatey Packages from Vars file'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
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
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)

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
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for Windows PowerShell NuGet Package Provider...'

# Get
Write-Verbose -Message '[Get] Windows PowerShell NuGet Package Provider...'
$nuGetPackageProvider = powershell -Command {
    Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue
}

# Get-PackageProvider -ListAvailable can return multiple versions; take the highest.
# The provider comes from a child powershell.exe, so Version is a deserialized
# property bag — cast via its string form, not the object itself.
$nuGetProviderVersion = $nuGetPackageProvider |
    ForEach-Object -Process { [version]"$($_.Version)" } |
    Sort-Object -Descending |
    Select-Object -First 1

# Test
Write-Verbose -Message '[Test] Windows PowerShell NuGet Package Provider...'
if (($null -eq $nuGetProviderVersion) -or ($nuGetProviderVersion -lt [version]'2.8.5.201')) {
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
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
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
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
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
                    Install-Module -Name $module -Scope CurrentUser -AllowClobber -Force
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
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
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
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
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
    # pipx list --json returns one object whose venvs property is keyed by package name
    $pipxInstalledNames = @()
    if ($pipxPackagesInstalled -and $pipxPackagesInstalled.venvs) {
        $pipxInstalledNames = @($pipxPackagesInstalled.venvs.PSObject.Properties.Name)
    }

    foreach ($package in $pipxPackages) {
        Write-Progress -Activity $activity -Status (
            & $StatusBlock
        ) -CurrentOperation $package -PercentComplete ($step / $totalSteps * 100)
        Write-Information -MessageData "Checking for pipx package $package..."

        # Get
        Write-Verbose -Message "[Get] pipx package: $package"
        $pipxPackageInstalled = $pipxInstalledNames -contains $package

        # Test
        Write-Verbose -Message "[Test] pipx package: $package"
        if (-not $pipxPackageInstalled) {
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

#region Ensure uv Tools from Vars file are Installed

$step++
$stepText = 'Ensure uv Tools from Vars file are Installed'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for uv tools to install...'

# Get
Write-Verbose -Message '[Get] uv...'
$uvCmd = Get-Command -Name uv -ErrorAction SilentlyContinue

# Test
Write-Verbose -Message '[Test] uv...'
if ($null -eq $uvCmd) {
    Write-Information -MessageData 'uv is not installed, skipping uv tool installations.'
} else {
    # Get
    Write-Verbose -Message '[Get] uv tools from Vars file import...'
    $uvTools = $vars.uv_tools

    # Test
    Write-Verbose -Message '[Test] uv tools from Vars file import...'
    if ($uvTools -and $uvTools.Count -gt 0) {
        foreach ($tool in $uvTools) {
            Write-Progress -Activity $activity -Status (
                & $StatusBlock
            ) -CurrentOperation $tool -PercentComplete ($step / $totalSteps * 100)
            Write-Information -MessageData "Installing uv tool $tool..."

            # Set
            Write-Verbose -Message "[Set] uv tool: $tool"
            try {
                uv tool install $tool
                Write-Verbose -Message "[Set] uv tool $tool installation complete."
                Write-Information -MessageData "Installed uv tool: $tool."
            } catch {
                Write-Error -Message "Failed to install uv tool: $tool. Error: $_"
            }
        }
    } else {
        Write-Information -MessageData 'No uv tools specified in vars.yaml file.'
    }
}

#endregion Ensure uv Tools from Vars file are Installed

#region Ensure npm global Packages from Vars file are Installed

$step++
$stepText = 'Ensure npm global Packages from Vars file are Installed'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for npm global packages to install...'

# Get
Write-Verbose -Message '[Get] npm global packages from Vars file import...'
$npmGlobalPackages = $vars.npm_global_packages

# Test
Write-Verbose -Message '[Test] npm global packages from Vars file import...'
if ($npmGlobalPackages -and $npmGlobalPackages.Count -gt 0) {
    # Get the list of currently installed npm global packages
    Write-Verbose -Message '[Get] Currently installed npm global packages...'
    $npmGlobalPackagesInstalled = npm list -g --depth=0 --json | ConvertFrom-Json
    foreach ($package in $npmGlobalPackages) {
        Write-Progress -Activity $activity -Status (
            & $StatusBlock
        ) -CurrentOperation $package -PercentComplete ($step / $totalSteps * 100)
        Write-Information -MessageData "Checking for npm global package $package..."

        # Get
        Write-Verbose -Message "[Get] npm global package: $package"
        $npmPackageInstalled = $npmGlobalPackagesInstalled.dependencies.$package

        # Test
        Write-Verbose -Message "[Test] npm global package: $package"
        if (-not $npmPackageInstalled) {
            # Set
            Write-Verbose -Message "[Set] npm global package $package is not installed, installing..."
            try {
                npm install -g $package
                Write-Verbose -Message "[Set] npm global package $package is now installed."
                Write-Information -MessageData "Installed npm global package: $package."
            } catch {
                Write-Error -Message "Failed to install npm global package: $package. Error: $_"
            }
        } else {
            Write-Information -MessageData "npm global package $package is already installed."
        }
    }
} else {
    Write-Information -MessageData 'No npm global packages specified in vars.yaml file.'
}

#endregion Ensure npm global Packages from Vars file are Installed

#region Ensure pnpm global Packages from Vars file are Installed

$step++
$stepText = 'Ensure pnpm global Packages from Vars file are Installed'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for pnpm global packages to install...'

# Get
Write-Verbose -Message '[Get] pnpm...'
$pnpmCmd = Get-Command -Name pnpm -ErrorAction SilentlyContinue

# Test
Write-Verbose -Message '[Test] pnpm...'
if ($null -eq $pnpmCmd) {
    Write-Information -MessageData 'pnpm is not installed, skipping pnpm global package installations.'
} else {
    # pnpm requires a configured global bin directory (PNPM_HOME) for `pnpm add -g`.
    Write-Verbose -Message '[Set] Ensuring PNPM_HOME is configured...'
    # pnpm installs global binaries into its global bin dir ($PNPM_HOME\bin,
    # pnpm's default), which must exist and be on PATH or it errors with
    # ERR_PNPM_NO_GLOBAL_BIN_DIR. This mirrors the PNPM_HOME + $PNPM_HOME\bin
    # convention in the shell profiles, so no pnpm config file is written.
    if (-not $env:PNPM_HOME) {
        $env:PNPM_HOME = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'pnpm'
    }

    $pnpmBinDir = Join-Path -Path $env:PNPM_HOME -ChildPath 'bin'
    if (-not (Test-Path -Path $pnpmBinDir)) {
        New-Item -Path $pnpmBinDir -ItemType Directory -Force | Out-Null
    }

    if (($env:PATH -split ';') -notcontains $pnpmBinDir) {
        $env:PATH = "$pnpmBinDir;$env:PATH"
    }

    # Get
    Write-Verbose -Message '[Get] pnpm global packages from Vars file import...'
    $pnpmGlobalPackages = $vars.pnpm_global_packages

    # Test
    Write-Verbose -Message '[Test] pnpm global packages from Vars file import...'
    if ($pnpmGlobalPackages -and $pnpmGlobalPackages.Count -gt 0) {
        # Get the list of currently installed pnpm global packages.
        # pnpm list -g --json returns an array of global store objects; collect
        # the installed dependency names (keyed by bare name, without @version).
        Write-Verbose -Message '[Get] Currently installed pnpm global packages...'
        $pnpmInstalledNames = @(pnpm list -g --depth=0 --json | ConvertFrom-Json) |
            ForEach-Object -Process { $_.dependencies.PSObject.Properties.Name }
        foreach ($package in $pnpmGlobalPackages) {
            Write-Progress -Activity $activity -Status (
                & $StatusBlock
            ) -CurrentOperation $package -PercentComplete ($step / $totalSteps * 100)
            Write-Information -MessageData "Checking for pnpm global package $package..."

            # Get
            Write-Verbose -Message "[Get] pnpm global package: $package"
            # A version-pinned spec (name@version) won't exact-match a bare name,
            # so it is (re)installed to honor the pin; unpinned names are skipped.
            $pnpmPackageInstalled = $pnpmInstalledNames -contains $package

            # Test
            Write-Verbose -Message "[Test] pnpm global package: $package"
            if (-not $pnpmPackageInstalled) {
                # Set
                Write-Verbose -Message "[Set] pnpm global package $package is not installed, installing..."
                try {
                    pnpm add -g $package
                    Write-Verbose -Message "[Set] pnpm global package $package is now installed."
                    Write-Information -MessageData "Installed pnpm global package: $package."
                } catch {
                    Write-Error -Message "Failed to install pnpm global package: $package. Error: $_"
                }
            } else {
                Write-Information -MessageData "pnpm global package $package is already installed."
            }
        }
    } else {
        Write-Information -MessageData 'No pnpm global packages specified in vars.yaml file.'
    }
}

#endregion Ensure pnpm global Packages from Vars file are Installed

#region Ensure bun global Packages from Vars file are Installed

$step++
$stepText = 'Ensure bun global Packages from Vars file are Installed'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for bun global packages to install...'

# Get
Write-Verbose -Message '[Get] bun...'
$bunCmd = Get-Command -Name bun -ErrorAction SilentlyContinue

# Test
Write-Verbose -Message '[Test] bun...'
if ($null -eq $bunCmd) {
    Write-Information -MessageData 'bun is not installed, skipping bun global package installations.'
} else {
    # Get
    Write-Verbose -Message '[Get] bun global packages from Vars file import...'
    $bunGlobalPackages = $vars.bun_global_packages

    # Test
    Write-Verbose -Message '[Test] bun global packages from Vars file import...'
    if ($bunGlobalPackages -and $bunGlobalPackages.Count -gt 0) {
        # Get the list of currently installed bun global packages
        Write-Verbose -Message '[Get] Currently installed bun global packages...'
        $bunGlobalPackagesInstalled = bun pm ls -g 2>$null | Out-String
        foreach ($package in $bunGlobalPackages) {
            Write-Progress -Activity $activity -Status (
                & $StatusBlock
            ) -CurrentOperation $package -PercentComplete ($step / $totalSteps * 100)
            Write-Information -MessageData "Checking for bun global package $package..."

            # Get
            Write-Verbose -Message "[Get] bun global package: $package"
            # Match the full requested spec (incl. any pinned @version) against the
            # installed list so re-pinning to a different version triggers a reinstall.
            $bunPackageInstalled = $bunGlobalPackagesInstalled -match [regex]::Escape($package)

            # Test
            Write-Verbose -Message "[Test] bun global package: $package"
            if (-not $bunPackageInstalled) {
                # Set
                Write-Verbose -Message "[Set] bun global package $package is not installed, installing..."
                try {
                    bun add -g $package
                    Write-Verbose -Message "[Set] bun global package $package is now installed."
                    Write-Information -MessageData "Installed bun global package: $package."
                } catch {
                    Write-Error -Message "Failed to install bun global package: $package. Error: $_"
                }
            } else {
                Write-Information -MessageData "bun global package $package is already installed."
            }
        }
    } else {
        Write-Information -MessageData 'No bun global packages specified in vars.yaml file.'
    }
}

#endregion Ensure bun global Packages from Vars file are Installed

#region Ensure .NET Global Tools from Vars file are Installed

$step++
$stepText = 'Ensure .NET Global Tools from Vars file are Installed'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for .NET global tools to install...'

# Get
Write-Verbose -Message '[Get] .NET global tools from Vars file import...'
$dotnetTools = $vars.dotnet_tools

# Test if dotnet is installed
Write-Verbose -Message '[Test] dotnet is installed...'
$dotnetCommand = Get-Command -Name dotnet -ErrorAction SilentlyContinue
if (-not $dotnetCommand) {
    Write-Information -MessageData '.NET SDK is not installed, skipping .NET global tools installation.'
} elseif ($dotnetTools -and $dotnetTools.Count -gt 0) {
    # Get the list of currently installed .NET global tools
    Write-Verbose -Message '[Get] Currently installed .NET global tools...'
    try {
        $dotnetToolsInstalled = dotnet tool list -g --verbosity quiet | ForEach-Object -Process{
            if ($_ -match '^(\S+)\s+') {
                $matches[1]
            }
        }
    } catch {
        Write-Warning -Message "Failed to get installed .NET global tools list: $_"
        $dotnetToolsInstalled = @()
    }

    foreach ($tool in $dotnetTools) {
        Write-Progress -Activity $activity -Status (
            & $statusBlock
        ) -CurrentOperation $tool -PercentComplete ($step / $totalSteps * 100)
        Write-Information -MessageData "Checking for .NET global tool $tool..."

        # Get
        Write-Verbose -Message "[Get] .NET global tool: $tool"
        $toolInstalled = $tool -in $dotnetToolsInstalled

        # Test
        Write-Verbose -Message "[Test] .NET global tool: $tool"
        if (-not $toolInstalled) {
            # Set
            Write-Verbose -Message "[Set] .NET global tool $tool is not installed, installing..."
            try {
                dotnet tool install -g $tool
                Write-Verbose -Message "[Set] .NET global tool $tool is now installed."
                Write-Information -MessageData "Installed .NET global tool: $tool."
            } catch {
                Write-Error -Message "Failed to install .NET global tool: $tool. Error: $_"
            }
        } else {
            Write-Information -MessageData ".NET global tool $tool is already installed."
        }
    }
} else {
    Write-Information -MessageData 'No .NET global tools specified in vars.yaml file.'
}

#endregion Ensure .NET Global Tools from Vars file are Installed

#region Install Visual Studio Code Extensions from Vars file if Visual Studio Code is Installed

$step++
$stepText = 'Install Visual Studio Code Extensions from Vars file'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
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

#region Install Cursor Extensions from Vars file if Cursor is Installed

$step++
$stepText = 'Install Cursor Extensions from Vars file'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for Cursor extensions to install...'

# Get
Write-Verbose -Message '[Get] Cursor extensions from Vars file import...'
$cursorExtensions = $vars.vscode_extensions

# Test
Write-Verbose -Message '[Test] Cursor extensions from Vars file import...'
if ($cursorExtensions -and $cursorExtensions.Count -gt 0) {
    # Get
    Write-Verbose -Message '[Get] Checking for Cursor installation...'
    $cursorCmd = Get-Command -Name cursor -ErrorAction SilentlyContinue

    # Test
    Write-Verbose -Message '[Test] Cursor installation...'
    if ($null -eq $cursorCmd) {
        Write-Warning -Message 'Cursor is not installed, skipping extension installation.'
    } else {
        $cursorExtensionsInstalled = cursor --list-extensions
        foreach ($extension in $cursorExtensions) {
            Write-Progress -Activity $Activity -Status (
                & $StatusBlock
            ) -CurrentOperation $extension -PercentComplete ($step / $totalSteps * 100)
            Write-Information -MessageData "Checking for Cursor extension $extension..."

            # Get
            Write-Verbose -Message "[Get] Cursor extension: $extension"
            $cursorExtensionInstalled = $cursorExtensionsInstalled |
                Where-Object -FilterScript { $_ -eq $extension }

            # Test
            Write-Verbose -Message "[Test] Cursor extension: $extension"
            if (-not $cursorExtensionInstalled) {
                # Set
                Write-Verbose -Message (
                    "[Set] Cursor extension $extension is not installed, installing..."
                )
                try {
                    cursor --install-extension $extension
                    Write-Verbose -Message "[Set] Cursor extension $extension is now installed."
                    Write-Information -MessageData "Installed Cursor extension: $extension."
                } catch {
                    Write-Error -Message "Failed to install Cursor extension: $extension. Error: $_"
                }
            } else {
                Write-Information -MessageData "Cursor extension $extension is already installed."
            }
        }
    }
} else {
    Write-Information -MessageData 'No Cursor extensions specified in vars.yaml file.'
}

#endregion Install Cursor Extensions from Vars file if Cursor is Installed

#region Git user.email and user.name Config

$step++
$stepText = 'Git user.email and user.name Config'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Configuring Git user.email and user.name...'

# Get
Write-Verbose -Message '[Get] Git user.email and user.name...'
$currentGitUserEmail = if (Get-Command -Name git -ErrorAction SilentlyContinue) { git config --global user.email }
$currentGitUserName = if (Get-Command -Name git -ErrorAction SilentlyContinue) { git config --global user.name }

# Test
Write-Verbose -Message '[Test] Git user.email...'
if (-not [string]::IsNullOrWhiteSpace($GitUserEmail) -and
    $currentGitUserEmail -ne $GitUserEmail -and
    (Get-Command -Name git -ErrorAction SilentlyContinue)) {
    # Set
    Write-Verbose -Message "[Set] Setting Git user.email to '$GitUserEmail'..."
    try {
        git config --global user.email $GitUserEmail
    } catch {
        Write-Error -Message "Failed to set Git user.email: $_"
    }

    Write-Verbose -Message "[Set] Git user.email is now set to '$GitUserEmail'."
    Write-Information -MessageData "Set Git user.email to '$GitUserEmail'."
} elseif (-not (Get-Command -Name git -ErrorAction SilentlyContinue)) {
    Write-Warning -Message 'Git is not installed, cannot set user.email.'
} elseif ([string]::IsNullOrWhiteSpace($GitUserEmail)) {
    Write-Warning -Message 'Git user.email is not set and no email was provided.'
} else {
    Write-Information -MessageData "Git user.email is already set to '$currentGitUserEmail'."
}

# Test
Write-Verbose -Message '[Test] Git user.name...'
if (-not [string]::IsNullOrWhiteSpace($GitUserName) -and
    $currentGitUserName -ne $GitUserName -and
    (Get-Command -Name git -ErrorAction SilentlyContinue)) {
    # Set
    Write-Verbose -Message "[Set] Setting Git user.name to '$GitUserName'..."
    try {
        git config --global user.name $GitUserName
    } catch {
        Write-Error -Message "Failed to set Git user.name: $_"
    }

    Write-Verbose -Message "[Set] Git user.name is now set to '$GitUserName'."
    Write-Information -MessageData "Set Git user.name to '$GitUserName'."
} elseif (-not (Get-Command -Name git -ErrorAction SilentlyContinue)) {
    Write-Warning -Message 'Git is not installed, cannot set user.name.'
} elseif ([string]::IsNullOrWhiteSpace($GitUserName)) {
    Write-Error -Message 'Git user.name is not set and no name was provided.'
} else {
    Write-Information -MessageData "Git user.name is already set to '$currentGitUserName'."
}

#endregion Git user.email and user.name Config

#region Execute Custom Commands from Vars file

$step++
$stepText = 'Execute Custom Commands from Vars file'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for custom commands to execute from vars.yaml file...'

# Get
Write-Verbose -Message '[Get] Custom commands from Vars file import...'
$customCommands = $vars.custom_commands

# Test
Write-Verbose -Message '[Test] Custom commands from Vars file import...'
if ($customCommands -and $customCommands.Count -gt 0) {
    foreach ($command in $customCommands) {
        Write-Progress -Activity $Activity -Status (
            & $StatusBlock
        ) -CurrentOperation $command -PercentComplete ($step / $totalSteps * 100)
        Write-Information -MessageData "Executing custom command: $command..."

        # Get / Test / Set
        Write-Verbose -Message "[Get] / [Test] / [Set] Executing custom command: $command"
        try {
            Invoke-Command -ScriptBlock ([ScriptBlock]::Create($command))
            Write-Verbose -Message "[Get] / [Test] / [Set] Successfully executed custom command: $command"
            Write-Information -MessageData "Executed custom command: $command."
        } catch {
            Write-Error -Message "Failed to execute custom command: $command. Error: $_"
        }
    }
} else {
    Write-Information -MessageData 'No custom commands specified in vars.yaml file.'
}

#endregion Execute Custom Commands from Vars file

#region Execute Custom Script from Vars file

$step++
$stepText = 'Execute Custom Script from Vars file'
Write-Progress -Activity $activity -Status (Get-StatusText) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking for custom script to execute from vars.yaml file...'

# Get
Write-Verbose -Message '[Get] Custom script from Vars file import...'
$customScript = $vars.custom_script

# Test
Write-Verbose -Message '[Test] Custom script from Vars file import...'
if (-not [string]::IsNullOrWhiteSpace($customScript)) {
    # Set
    Write-Verbose -Message '[Set] Executing custom script from vars.yaml file...'
    try {
        . $customScript
    } catch {
        Write-Error -Message "Failed to execute custom script: $customScript. Error: $_"
    }

    Write-Verbose -Message '[Set] Successfully executed custom script from vars.yaml file.'
    Write-Information -MessageData "Executed custom script from vars.yaml file: $customScript."
} else {
    Write-Information -MessageData 'No custom script specified in vars.yaml file.'
}

#endregion Execute Custom Commands from Vars file

#region Transcript Teardown

Stop-Transcript

Write-Information -MessageData "`nSetup completed successfully!"
Write-Information -MessageData "Full log available at: $transcriptFile"

#endregion Transcript Teardown
