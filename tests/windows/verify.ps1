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

# PowerShell module
Test-Check "Pester installed (PowerShell module)" {
    $result = pwsh -Command "Get-InstalledPSResource -Name Pester -ErrorAction Stop"
    if (-not $result) { throw "Pester not found" }
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
