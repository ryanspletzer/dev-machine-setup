#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

# setup-functions.Tests.ps1
# Unit tests for the vars.yaml text-parsing helpers used by windows/setup.ps1.
# Must run on both Windows PowerShell 5.1 and PowerShell 7 (CI runs both).

BeforeAll {
    $repoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot)
    . (Join-Path -Path $repoRoot -ChildPath 'windows/setup-functions.ps1')

    function New-VarsFile {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseShouldProcessForStateChangingFunctions', '',
            Justification = 'Test helper that only writes into the Pester TestDrive.')]
        param (
            [string]
            $Content
        )
        $path = Join-Path -Path $TestDrive -ChildPath ([Guid]::NewGuid().ToString() + '.yaml')
        Set-Content -Path $path -Value $Content -Encoding UTF8
        $path
    }
}

Describe 'Get-VarsYamlScalar' {
    It 'returns an unquoted value' {
        $path = New-VarsFile -Content "git_user_email: foo@example.com`ngit_user_name: Foo Bar"
        Get-VarsYamlScalar -Path $path -Key 'git_user_email' | Should -Be 'foo@example.com'
    }

    It 'strips double quotes' {
        $path = New-VarsFile -Content 'git_user_email: "foo@example.com"'
        Get-VarsYamlScalar -Path $path -Key 'git_user_email' | Should -Be 'foo@example.com'
    }

    It 'strips single quotes' {
        $path = New-VarsFile -Content "git_user_email: 'foo@example.com'"
        Get-VarsYamlScalar -Path $path -Key 'git_user_email' | Should -Be 'foo@example.com'
    }

    It 'strips a trailing comment' {
        $path = New-VarsFile -Content 'git_user_email: foo@example.com # work address'
        Get-VarsYamlScalar -Path $path -Key 'git_user_email' | Should -Be 'foo@example.com'
    }

    It 'preserves spaces inside a quoted value' {
        $path = New-VarsFile -Content 'git_user_name: "CI Test User"'
        Get-VarsYamlScalar -Path $path -Key 'git_user_name' | Should -Be 'CI Test User'
    }

    It 'returns an empty string for an empty quoted value' {
        $path = New-VarsFile -Content 'custom_script: ""'
        $value = Get-VarsYamlScalar -Path $path -Key 'custom_script'
        [string]::IsNullOrWhiteSpace($value) | Should -BeTrue
    }

    It 'returns nothing when the key is missing' {
        $path = New-VarsFile -Content 'git_user_name: Foo Bar'
        Get-VarsYamlScalar -Path $path -Key 'git_user_email' | Should -BeNullOrEmpty
    }

    It 'returns nothing (without throwing) when the file is missing' {
        $missing = Join-Path -Path $TestDrive -ChildPath 'does-not-exist.yaml'
        { Get-VarsYamlScalar -Path $missing -Key 'git_user_email' } | Should -Not -Throw
        Get-VarsYamlScalar -Path $missing -Key 'git_user_email' | Should -BeNullOrEmpty
    }

    It 'does not confuse keys sharing a prefix' {
        $path = New-VarsFile -Content "git_user_name: Foo Bar`ngit_user_name_suffix: nope"
        Get-VarsYamlScalar -Path $path -Key 'git_user_name' | Should -Be 'Foo Bar'
    }

    It 'treats the key as a literal, not a regex' {
        $path = New-VarsFile -Content "git_user_email: right`ngitXuserXemail: wrong"
        Get-VarsYamlScalar -Path $path -Key 'git.user.email' | Should -BeNullOrEmpty
    }
}

Describe 'Get-ChocoPackageName' {
    It 'lists names and ignores parameters/prerelease subkeys' {
        $path = New-VarsFile -Content @'
choco_packages:
  - name: git
    parameters: /WindowsTerminal /NoShellIntegration
  - name: jq
  - name: vscode-insiders
    prerelease: true
'@
        Get-ChocoPackageName -Path $path | Should -Be @('git', 'jq', 'vscode-insiders')
    }

    It 'stops at the next top-level key' {
        $path = New-VarsFile -Content @'
choco_packages:
  - name: git
powershell_modules:
  - name: Pester
'@
        Get-ChocoPackageName -Path $path | Should -Be @('git')
    }

    It 'ignores lists that come before choco_packages' {
        $path = New-VarsFile -Content @'
pipx_packages:
  - name: cowsay
choco_packages:
  - name: git
'@
        Get-ChocoPackageName -Path $path | Should -Be @('git')
    }

    It 'strips quotes from names' {
        $path = New-VarsFile -Content @'
choco_packages:
  - name: "git"
  - name: 'jq'
'@
        Get-ChocoPackageName -Path $path | Should -Be @('git', 'jq')
    }

    It 'returns nothing when choco_packages is absent' {
        $path = New-VarsFile -Content 'apt_packages: []'
        Get-ChocoPackageName -Path $path | Should -BeNullOrEmpty
    }

    It 'returns nothing when choco_packages is an empty inline list' {
        $path = New-VarsFile -Content 'choco_packages: []'
        Get-ChocoPackageName -Path $path | Should -BeNullOrEmpty
    }

    It 'handles CRLF line endings' {
        $path = New-VarsFile -Content "choco_packages:`r`n  - name: git`r`n  - name: jq`r`n"
        Get-ChocoPackageName -Path $path | Should -Be @('git', 'jq')
    }

    It 'finds git in the CI fixture vars.yaml' {
        $fixture = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot)) -ChildPath 'tests/windows/vars.yaml'
        Get-ChocoPackageName -Path $fixture | Should -Contain 'git'
    }

    It 'finds git in the real windows vars.yaml (drives the git-config validation gate)' {
        $real = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot)) -ChildPath 'windows/vars.yaml'
        Get-ChocoPackageName -Path $real | Should -Contain 'git'
    }
}
