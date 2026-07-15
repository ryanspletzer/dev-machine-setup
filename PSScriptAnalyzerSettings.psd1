@{
    # Fail on everything the analyzer reports, including Information-level rules.
    Severity = @('Error', 'Warning', 'Information')

    Rules    = @{
        # windows/setup.ps1 must run on Windows PowerShell 5.1 (what ships
        # with Windows 11), so reject syntax that only parses on newer
        # versions (ternary, ??, &&/|| chains, ...).
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
        }
    }
}
