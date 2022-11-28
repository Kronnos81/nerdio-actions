#description: Installs the latest Microsoft Edge and Microsoft Edge WebView2
#execution mode: Combined
#tags: Evergreen, Edge
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\Edge"
[System.String] $EdgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"

#region Script logic
# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

#region Edge
try {
    # Download
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" } | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
}
catch {
    throw $_.Exception.Message
}

try {
    $File = Get-ChildItem -Path $EdgeExe
    if (!(Test-Path -Path $EdgeExe) -or ([System.Version]$File.VersionInfo.ProductVersion -lt [System.Version]$App.Version)) {

        # Install
        $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
        $params = @{
            FilePath     = "$env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/package $($OutFile.FullName) /quiet /norestart DONOTCREATEDESKTOPSHORTCUT=true /log `"$env:ProgramData\NerdioManager\Logs\MicrosoftEdge.log`""
            NoNewWindow  = $true
            Wait         = $true
            PassThru     = $false
        }
        $result = Start-Process @params
    }
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}

try {
    # Post install configuration
    $prefs = @{
        "homepage"               = "https://www.office.com"
        "homepage_is_newtabpage" = $false
        "browser"                = @{
            "show_home_button" = $true
        }
        "distribution"           = @{
            "skip_first_run_ui"              = $true
            "show_welcome_page"              = $false
            "import_search_engine"           = $false
            "import_history"                 = $false
            "do_not_create_any_shortcuts"    = $false
            "do_not_create_taskbar_shortcut" = $false
            "do_not_create_desktop_shortcut" = $true
            "do_not_launch_chrome"           = $true
            "make_chrome_default"            = $true
            "make_chrome_default_for_user"   = $true
            "system_level"                   = $true
        }
    }
    $prefs | ConvertTo-Json | Set-Content -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\master_preferences" -Force -Encoding "utf8"
    Remove-Item -Path "$env:Public\Desktop\Microsoft Edge*.lnk" -Force -ErrorAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}
#endregion

#region Edge WebView2
try {
    # Download
    Import-Module -Name "Evergreen" -Force
    $App = Get-EvergreenApp -Name "MicrosoftEdgeWebView2Runtime" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" } | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"
}
catch {
    throw $_.Exception.Message
}

try {
    # Install
    $params = @{
        FilePath     = $OutFile.FullName
        ArgumentList = "/silent /install"
        NoNewWindow  = $true
        Wait         = $true
        PassThru     = $false
    }
    $result = Start-Process @params
}
catch {
    throw "Exit code: $($result.ExitCode); Error: $($_.Exception.Message)"
}
#endregion
