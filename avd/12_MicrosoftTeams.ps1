#description: Installs the latest Microsoft Teams for use on Windows 10/11 multi-session or Windows Server
#execution mode: Combined
#tags: Evergreen, Teams
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\Teams"

#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Run tasks/install apps
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "MicrosoftTeams" | Where-Object { $_.Architecture -eq "x64" -and $_.Ring -eq "General" -and $_.Type -eq "msi" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

    # Install
    reg add "HKLM\SOFTWARE\Microsoft\Teams" /v "IsWVDEnvironment" /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SOFTWARE\Citrix\PortICA" /v "IsWVDEnvironment" /t REG_DWORD /d 1 /f | Out-Null

    $params = @{
        FilePath     = "$env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package $($OutFile.FullName) OPTIONS=`"noAutoStart=true`" ALLUSER=1 ALLUSERS=1 /quiet /log `"$env:ProgramData\NerdioManager\Logs\MicrosoftTeams.log`""
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params

    # Teams JSON files
    $ConfigFiles = @((Join-Path -Path "${env:ProgramFiles(x86)}\Teams Installer" -ChildPath "setup.json"),
    (Join-Path -Path "${env:ProgramFiles(x86)}\Microsoft\Teams" -ChildPath "setup.json"))

    # Read the file and convert from JSON
    foreach ($Path in $ConfigFiles) {
        if (Test-Path -Path $Path) {
            try {
                $Json = Get-Content -Path $Path | ConvertFrom-Json
                $Json.noAutoStart = $true
                $Json | ConvertTo-Json | Set-Content -Path $Path -Force
            }
            catch {
                Write-Warning -Message "`tERR: Failed to set Teams autostart file: $Path."
            }
        }
    }

    # Delete the registry auto-start
    reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "Teams" /f | Out-Null
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}
#endregion
