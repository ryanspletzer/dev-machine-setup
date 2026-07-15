#Requires -Version 5.1

# setup-functions.ps1
# Pure text-parsing helpers dot-sourced by setup.ps1.
# These read vars.yaml before the powershell-yaml module is installed, so
# they must work with nothing but regular expressions.
# Kept in a separate file (no -RunAsAdministrator requirement) so the Pester
# suite in tests/windows can exercise them without running the setup script.

function Get-VarsYamlScalar {
    <#
    .SYNOPSIS
        Extracts the scalar value of a top-level key from a vars.yaml file.
    .DESCRIPTION
        Regex breakdown of the value-extraction pattern:

        | Piece        | What it matches                                     | Purpose                              |
        | ------------ | --------------------------------------------------- | ------------------------------------ |
        | ^\s*         | optional leading spaces at line start               | anchor at the beginning              |
        | [^:]+:       | everything up to (and including) the first colon    | skips the key name                   |
        | \s*          | optional spaces                                     | ignore padding                       |
        | (["']?)      | group 1 - an optional ' or "                        | remembers opening quote if present   |
        | ([^#'"]*?)   | group 2 - zero or more chars that are not #, ', "   | captures the value itself            |
        | \1           | the same quote captured in group 1                  | ensures we close the quote we opened |
        | \s*          | optional spaces                                     | ignore padding                       |
        | (?:#.*)?     | an optional comment starting with # to EOL          | discards right-hand comments         |
        | $            | end of line                                         | anchor                               |
    .OUTPUTS
        The key's value with quotes and trailing comment stripped; nothing
        when the file or the key is missing.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $Key
    )

    $pattern = '^\s*[^:]+:\s*(["'']?)([^#''"]*?)\1\s*(?:#.*)?$'
    Get-Content -Path $Path -ErrorAction SilentlyContinue |
        Where-Object -FilterScript { $_ -match "^\s*$([regex]::Escape($Key))\s*:" } |
        ForEach-Object -Process { $_ -replace $pattern, '$2' }
}

function Get-ChocoPackageName {
    <#
    .SYNOPSIS
        Lists the package names under the choco_packages key of a vars.yaml file.
    .DESCRIPTION
        Strips everything outside the choco_packages block, keeps the
        "- name: ..." lines, and strips YAML syntax plus quotes so only the
        raw package names remain. Subkeys such as parameters/prerelease are
        ignored because they do not match the "- name:" prefix.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    (
        (Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue) -replace '(?ms)^.*?^choco_packages:\s*|^\S.*', ''
    ) -split "`r?\n" |
        Where-Object -FilterScript {
            # keep  - name: ...  lines
            $_ -match '^\s*-\s*name:'
        } |
        ForEach-Object -Process {
            # strip YAML syntax + quotes, leave only the raw name
            ($_ -replace '^\s*-\s*name:\s*["'']?(?<pkg>[^"'']+)["'']?\s*$', '$1')
        }
}
