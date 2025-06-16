#Requires -RunAsAdministrator
#Requires -Version 5.1

# Installs prerequisites and runs the configuration

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateScript({
        if ([string]::IsNullOrWhiteSpace($_) -and
            [string]::IsNullOrWhiteSpace(git config --global user.email 2>$null)) {
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

Start-Transcript
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
    Write-Verbose -Message '[Set] PowerShell (pwsh) is now installed.'
    Write-Information -MessageData 'Installed PowerShell (pwsh).'
} else {
    Write-Information -MessageData 'PowerShell (pwsh) is already installed.'
}

#endregion Install PowerShell (pwsh)

#region Check if Running in Windows PowerShell, Relaunch in PowerShell (pwsh)

$step++
$stepText = 'Check if Running in Windows PowerShell, Relaunch in PowerShell (pwsh)'
Write-Progress -Activity $activity -Status (& $statusBlock) -PercentComplete ($step / $totalSteps * 100)
Write-Information -MessageData 'Checking if running in Windows PowerShell...'

# Get
Write-Verbose -Message '[Get] Current PowerShell version...'
$currentPSVersion = $PSVersionTable.PSVersion

# Test
Write-Verbose -Message '[Test] Current PowerShell version...'
if ($currentPSVersion.Major -lt 6) {
    Write-Verbose -Message '[Set] Relaunching in PowerShell (pwsh)...'
    $scriptPath = $MyInvocation.MyCommand.Path
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -e `"$GitUserEmail`" -n `"$GitUserName`" -f `"$VarsFile`""
    Start-Process -FilePath 'pwsh.exe' -ArgumentList $args -Wait
    exit 0
} else {
    Write-Information -MessageData 'Running in PowerShell (pwsh).'
}

#endregion Check if Running in Windows PowerShell, Relaunch in PowerShell (pwsh)

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
