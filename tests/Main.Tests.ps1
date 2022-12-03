<#
    .SYNOPSIS
        Main Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param ()

BeforeDiscovery {

    # Get the list of software to test
    if ([System.String]::IsNullOrWhiteSpace($env:GITHUB_WORKSPACE)) {
        $Path = $PWD.Path
    }
    else {
        $Path = $env:GITHUB_WORKSPACE
    }

    # TestCases are splatted to the script so we need hashtables
    $Scripts = Get-ChildItem -Path $Path -Recurse -Include "*.ps1", "*.psm1"
    $TestCases = $scripts | ForEach-Object { @{file = $_ } }
}

Describe "General project validation" {
    It "Script <file.Name> should be valid PowerShell" -TestCases $TestCases {
        param ($File)
        $contents = Get-Content -Path $File.FullName -ErrorAction "Stop"
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
        $errors.Count | Should -Be 0
    }
}
