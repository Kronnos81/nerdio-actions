#description: Installs the latest Zoom Meetings VDI client
#execution mode: Combined
#tags: Evergreen, Zoom
#Requires -Modules Evergreen
[System.String] $Path = "$Env:SystemDrive\Apps\Zoom\Meetings"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null
New-Item -Path "$Env:ProgramData\Evergreen\Logs" -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    # Download Zoom
    Import-Module -Name "Evergreen" -Force
    $App = Invoke-EvergreenApp -Name "Zoom" | Where-Object { $_.Platform -eq "VDI" } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_
}

try {
    $LogFile = "$Env:ProgramData\Evergreen\Logs\ZoomMeetings$($App.Version).log" -replace " ", ""
    $params = @{
        FilePath     = "$Env:SystemRoot\System32\msiexec.exe"
        ArgumentList = "/package `"$($OutFile.FullName)`" ALLUSERS=1 zSilentStart=false zNoDesktopShortCut=true /quiet /log $LogFile"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $true
        ErrorAction  = "Continue"
    }
    $result = Start-Process @params
    $result.ExitCode
}
catch {
    throw $_
}
#endregion
