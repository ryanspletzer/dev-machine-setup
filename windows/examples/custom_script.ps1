# Set pwsh as the default shell in Windows Terminal

Write-Output -InputObject "Setting pwsh as the default shell in Windows Terminal"

# 1. Locate the active settings.json (Store, Preview, or unpackaged)
$settingsPath = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $settingsPath) { Write-Error "Windows Terminal settings.json not found" }

if ($settingsPath) {
    # 2. Back up the file (one-liner so you can easily roll back)
    Copy-Item -Path $settingsPath -Destination "$settingsPath.bak" -Force

    # 3. Load the JSON, find—or build—a profile that runs pwsh.exe
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    $pwshProfile = $settings.profiles.list |
        Where-Object { $_.name -eq 'PowerShell' }

    # 4. Make that profile the global default
    $settings.defaultProfile = $pwshProfile.guid

    # 5. Save it back (–Depth 32 keeps nested arrays/objects intact)
    $settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath -Encoding utf8
    Write-Output -InputObject "pwsh is now the default Windows Terminal shell."
}

