#Requires -RunAsAdministrator
#Requires -Version 5.1

# Installs prerequisites and runs the configuration

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateScript({
        if ([string]::IsNullOrWhiteSpace($_) -and
            [string]::IsNullOrWhiteSpace((git config --global user.email 2>$null))) {
            Write-Error -Message "Git user email is not set and no email was provided."
            $false
        } else {
            $true
        }
    })]
    [Alias('e')]
    [string]
    $GitUserEmail,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [Alias('n')]
    [string]
    $GitUserName = (Get-LocalUser -Name $env:USERNAME).FullName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path $_ })]
    [Alias('f')]
    [string]
    $VarsFile = 'vars.yaml'
)

Start-Transcript -
$script:VerbosePreference = 'Continue'
$script:InformationPreference = 'Continue'

#region Progress Variables

$activity = 'Setting Up Dev Machine'
$step = 0 # Set this at the beginning of each step
$stepText = 'Chocolatey Install' # Set this at the beginning of each step

# Get content of current script file to count of the total steps by looking at Step++ lines
$scriptPath = $MyInvocation.MyCommand.Path
$totalSteps = (
    Get-Content -Path $MyInvocation.MyCommand.Path |
    Where-Object -FilterScript { $_ -eq '$Step++' }
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
    choco install pwsh -yes --no-progress
    # Refresh Path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
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

# Import vars.yaml
if (Test-Path -Path $varsFilePath) {
    Write-Host "Importing vars from $varsFilePath..."
    $varsContent = Get-Content -Path $varsFilePath -Raw
    # $vars = ConvertFrom-Yaml -Yaml $varsContent
} else {
    Write-Error "Variables file not found: $varsFilePath"
    exit 1
}

Stop-Transcript

Write-Host "`nSetup completed successfully!"
Write-Host "Full log available at: $transcriptFile"
