# verify.ps1
# Post-integration verification for Windows setup

$Failures = 0

function Test-Check {
    param(
        [string]$Description,
        [scriptblock]$Test
    )
    try {
        $global:LASTEXITCODE = 0
        $null = & $Test
        if ($LASTEXITCODE -ne 0) { throw "non-zero exit code" }
        Write-Output "PASS: $Description"
    }
    catch {
        Write-Output "FAIL: $Description"
        $script:Failures++
    }
}

function Test-Equal {
    param(
        [string]$Description,
        [string]$Actual,
        [string]$Expected
    )
    if ($Actual -eq $Expected) {
        Write-Output "PASS: $Description"
    }
    else {
        Write-Output "FAIL: $Description (expected '$Expected', got '$Actual')"
        $script:Failures++
    }
}

# Chocolatey packages
Test-Check "jq installed (Chocolatey package)" { Get-Command jq -ErrorAction Stop }
Test-Check "git installed (Chocolatey package)" { Get-Command git -ErrorAction Stop }
Test-Check "bun installed (Chocolatey package)" { Get-Command bun -ErrorAction Stop }
Test-Check "pnpm installed (Chocolatey package)" { Get-Command pnpm -ErrorAction Stop }

# PowerShell module
Test-Check "Pester installed (PowerShell module)" {
    $result = pwsh -Command "Get-InstalledPSResource -Name Pester -ErrorAction Stop"
    if (-not $result) { throw "Pester not found" }
}

# Windows PowerShell module
Test-Check "posh-git installed (Windows PowerShell module)" {
    $r = powershell -Command "Get-Module -Name posh-git -ListAvailable"
    if (-not $r) { throw "posh-git not found" }
}

# uv (Chocolatey package)
Test-Check "uv installed (Chocolatey package)" { Get-Command uv -ErrorAction Stop }

# uv tool
Test-Check "ruff installed (uv tool)" {
    if (-not (Test-Path "$env:USERPROFILE\.local\bin\ruff.exe")) { throw "ruff.exe not found" }
}

# pipx
Test-Check "cowsay installed (pipx)" {
    $list = pipx list --short | Out-String
    if ($list -notmatch '(?m)^cowsay ') { throw "cowsay not in pipx list" }
}

# npm global package
Test-Check "semver installed (npm global)" {
    if (-not (Test-Path (Join-Path (npm prefix -g) 'semver.cmd'))) { throw "semver.cmd not found" }
}

# pnpm global package
Test-Check "json installed (pnpm global)" {
    if (-not (Test-Path "$env:LOCALAPPDATA\pnpm\bin\json*")) { throw "json shim not found" }
}

# bun global package
Test-Check "cowsay installed (bun global)" {
    if (-not (Test-Path "$env:USERPROFILE\.bun\bin\cowsay*")) { throw "cowsay shim not found" }
}

# .NET global tool
Test-Check "dotnetsay installed (.NET global tool)" {
    if (-not (Test-Path "$env:USERPROFILE\.dotnet\tools\dotnetsay.exe")) { throw "dotnetsay.exe not found" }
}

# Git config
Test-Equal "git user.email configured" `
    (git config --global user.email) "ci-test@example.com"
Test-Equal "git user.name configured" `
    (git config --global user.name) "CI Test User"

Write-Output ""
if ($Failures -gt 0) {
    Write-Output "$Failures check(s) failed"
    exit 1
}
else {
    Write-Output "All checks passed"
}
