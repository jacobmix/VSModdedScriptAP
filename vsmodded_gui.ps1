#Requires -Version 7.0
# Cross-platform VSModded installer with GUI for Windows and Linux

# ===================== USER CONFIG =====================
$Depots = @(
    @{ AppId = 1794680; DepotId = 1794681; Manifest = 8734072661229265420; Name = "Main Game 1.13" },
    @{ AppId = 2230760; DepotId = 2230761; Manifest = 8810650450200200831; Name = "Moonspell 1.13" },
    @{ AppId = 2313550; DepotId = 2313551; Manifest = 6130364014836738278; Name = "Foscari 1.13" },
    @{ AppId = 2690330; DepotId = 2690331; Manifest = 58333059023800463; Name = "Meeting 1.13" },
    @{ AppId = 2887680; DepotId = 2887681; Manifest = 3514133824999244705; Name = "Guns 1.13" },
    @{ AppId = 3210350; DepotId = 3210351; Manifest = 8060350983363650803; Name = "OtC 1.13" },
    @{ AppId = 3451100; DepotId = 3451101; Manifest = 1117835708715944408; Name = "Emerald 1.13" },
    @{ AppId = 1794680; DepotId = 1794681; Manifest = 5929929350734574725; Name = "Main Game 1.14" },
    @{ AppId = 2230760; DepotId = 2230761; Manifest = 6626234685557471330; Name = "Moonspell 1.14" },
    @{ AppId = 2313550; DepotId = 2313551; Manifest = 258978471953775490; Name = "Foscari 1.14" },
    @{ AppId = 2690330; DepotId = 2690331; Manifest = 1027692196364748982; Name = "Meeting 1.14" },
    @{ AppId = 2887680; DepotId = 2887681; Manifest = 3914729547287146862; Name = "Guns 1.14" },
    @{ AppId = 3210350; DepotId = 3210351; Manifest = 1856258357613603873; Name = "OtC 1.14" },
    @{ AppId = 3451100; DepotId = 3451101; Manifest = 7326781866595278644; Name = "Emerald 1.14" },
    @{ AppId = 3929770; DepotId = 3929771; Manifest = 239795049570881193; Name = "Ante 1.14" }
)
$Depots113 = $Depots | Where-Object { $_.Name -match "1\.13" }
$Depots114 = $Depots | Where-Object { $_.Name -match "1\.14" }
# ======================================================

$ErrorActionPreference = "Stop"
$OsTypeWindows = $PSVersionTable.Platform -ne 'Unix' -and $PSVersionTable.Platform -ne 'Linux'
$OsTypeLinux = -not $OsTypeWindows

# ===================== GUI DETECTION =====================
$UseGUI = $false

if ($OsTypeWindows) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $UseGUI = $true
    Write-Host "Platform: Windows (GUI Mode)"
} else {
    # Check for zenity on Linux
    if (Get-Command zenity -ErrorAction SilentlyContinue) {
        $UseGUI = $true
        Write-Host "Platform: Linux (GUI Mode - zenity)"
    } else {
        Write-Host "Platform: Linux (CLI Mode - install zenity for GUI)"
        Write-Host "Install with: sudo apt install zenity (Debian/Ubuntu)"
        Write-Host "             sudo dnf install zenity (Fedora)"
        Write-Host "             sudo pacman -S zenity (Arch)"
    }
}

# ===================== GUI HELPER FUNCTIONS =====================

function Show-Message {
    param (
        [string]$Message,
        [string]$Title = "VSModded Installer",
        [string]$Type = "Info" # Info, Warning, Error
    )
    
    if ($UseGUI) {
        if ($OsTypeWindows) {
            $icon = switch ($Type) {
                "Warning" { [System.Windows.Forms.MessageBoxIcon]::Warning }
                "Error" { [System.Windows.Forms.MessageBoxIcon]::Error }
                default { [System.Windows.Forms.MessageBoxIcon]::Information }
            }
            [System.Windows.Forms.MessageBox]::Show($Message, $Title, 'OK', $icon) | Out-Null
        } else {
            $iconType = switch ($Type) {
                "Warning" { "--warning" }
                "Error" { "--error" }
                default { "--info" }
            }
            zenity $iconType --title="$Title" --text="$Message" --width=400 2>$null
        }
    } else {
        Write-Host "[$Type] $Message"
    }
}

function Show-Question {
    param (
        [string]$Message,
        [string]$Title = "VSModded Installer"
    )
    
    if ($UseGUI) {
        if ($OsTypeWindows) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                $Message, 
                $Title, 
                'YesNo', 
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            return $result -eq 'Yes'
        } else {
            zenity --question --title="$Title" --text="$Message" --width=400 2>$null
            return $LASTEXITCODE -eq 0
        }
    } else {
        $response = Read-Host "$Message (y/N)"
        return $response -match '^[Yy]'
    }
}

function Get-UserInput {
    param (
        [string]$Prompt,
        [string]$Title = "VSModded Installer",
        [string]$Default = ""
    )
    
    if ($UseGUI) {
        if ($OsTypeWindows) {
            $form = New-Object System.Windows.Forms.Form
            $form.Text = $Title
            $form.Size = New-Object System.Drawing.Size(400, 150)
            $form.StartPosition = 'CenterScreen'
            $form.FormBorderStyle = 'FixedDialog'
            $form.MaximizeBox = $false
            
            $label = New-Object System.Windows.Forms.Label
            $label.Location = New-Object System.Drawing.Point(10, 20)
            $label.Size = New-Object System.Drawing.Size(360, 20)
            $label.Text = $Prompt
            $form.Controls.Add($label)
            
            $textBox = New-Object System.Windows.Forms.TextBox
            $textBox.Location = New-Object System.Drawing.Point(10, 50)
            $textBox.Size = New-Object System.Drawing.Size(360, 20)
            $textBox.Text = $Default
            $form.Controls.Add($textBox)
            
            $okButton = New-Object System.Windows.Forms.Button
            $okButton.Location = New-Object System.Drawing.Point(215, 80)
            $okButton.Size = New-Object System.Drawing.Size(75, 23)
            $okButton.Text = 'OK'
            $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.AcceptButton = $okButton
            $form.Controls.Add($okButton)
            
            $cancelButton = New-Object System.Windows.Forms.Button
            $cancelButton.Location = New-Object System.Drawing.Point(295, 80)
            $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
            $cancelButton.Text = 'Cancel'
            $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $form.Controls.Add($cancelButton)
            
            $result = $form.ShowDialog()
            
            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                return $textBox.Text
            }
            return $null
        } else {
            $result = zenity --entry --title="$Title" --text="$Prompt" --entry-text="$Default" --width=400 2>$null
            if ($LASTEXITCODE -eq 0) {
                return $result
            }
            return $null
        }
    } else {
        return Read-Host $Prompt
    }
}

function Show-ProgressDialog {
    param (
        [string]$Title,
        [string]$Message,
        [int]$Percent = 0
    )
    
    if ($UseGUI -and $OsTypeLinux) {
        # For Linux, we'll use zenity progress
        # This is tricky - we'll return a process that can be updated
        $script:zenityProcess = Start-Process -FilePath "zenity" -ArgumentList @(
            "--progress",
            "--title=$Title",
            "--text=$Message",
            "--percentage=$Percent",
            "--auto-close",
            "--width=400"
        ) -PassThru -NoNewWindow
    }
    # Windows progress is handled differently per operation
}

function Show-ListSelection {
    param (
        [string]$Title,
        [string]$Message,
        [array]$Items,
        [bool]$MultiSelect = $false
    )
    
    if ($UseGUI) {
        if ($OsTypeWindows) {
            $form = New-Object System.Windows.Forms.Form
            $form.Text = $Title
            $form.Size = New-Object System.Drawing.Size(500, 400)
            $form.StartPosition = 'CenterScreen'
            
            $label = New-Object System.Windows.Forms.Label
            $label.Location = New-Object System.Drawing.Point(10, 10)
            $label.Size = New-Object System.Drawing.Size(460, 20)
            $label.Text = $Message
            $form.Controls.Add($label)
            
            $listBox = New-Object System.Windows.Forms.CheckedListBox
            $listBox.Location = New-Object System.Drawing.Point(10, 40)
            $listBox.Size = New-Object System.Drawing.Size(460, 280)
            $listBox.CheckOnClick = $true
            
            foreach ($item in $Items) {
                [void]$listBox.Items.Add($item)
            }
            
            $form.Controls.Add($listBox)
            
            $okButton = New-Object System.Windows.Forms.Button
            $okButton.Location = New-Object System.Drawing.Point(315, 330)
            $okButton.Size = New-Object System.Drawing.Size(75, 23)
            $okButton.Text = 'OK'
            $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.AcceptButton = $okButton
            $form.Controls.Add($okButton)
            
            $cancelButton = New-Object System.Windows.Forms.Button
            $cancelButton.Location = New-Object System.Drawing.Point(395, 330)
            $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
            $cancelButton.Text = 'Cancel'
            $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $form.Controls.Add($cancelButton)
            
            $result = $form.ShowDialog()
            
            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                $selected = @()
                foreach ($item in $listBox.CheckedItems) {
                    $selected += $Items.IndexOf($item)
                }
                return $selected
            }
            return $null
        } else {
            # Zenity list with checkboxes
            $zenityItems = @()
            for ($i = 0; $i -lt $Items.Count; $i++) {
                $zenityItems += "FALSE"
                $zenityItems += "$($i + 1)"
                $zenityItems += $Items[$i]
            }
            
            $result = zenity --list --checklist --title="$Title" --text="$Message" `
                --column="" --column="Index" --column="Component" `
                --hide-column=2 --width=500 --height=400 `
                @zenityItems 2>$null
            
            if ($LASTEXITCODE -eq 0 -and $result) {
                $selected = $result -split '\|' | ForEach-Object {
                    $Items.IndexOf($_)
                }
                return $selected
            }
            return $null
        }
    } else {
        # Fallback to CLI
        for ($i = 0; $i -lt $Items.Count; $i++) {
            Write-Host "$($i + 1). $($Items[$i])"
        }
        $input = Read-Host "Select (comma-separated)"
        return $input -split ',' | ForEach-Object { ([int]$_.Trim()) - 1 }
    }
}

# ===================== ORIGINAL FUNCTIONS =====================
function Parse-VDF {
    param ([string]$Text)

    $stack = @(@{})
    $key = $null

    foreach ($line in $Text -split "`n") {
        $line = $line.Trim()

        if ($line -eq '{') {
            $new = @{}
            $stack[-1][$key] = $new
            $stack += $new
            continue
        }

        if ($line -eq '}') {
            $stack = $stack[0..($stack.Count - 2)]
            continue
        }

        if ($line -match '^"(.+?)"\s+"(.*?)"$') {
            $stack[-1][$Matches[1]] = $Matches[2]
            continue
        }

        if ($line -match '^"(.+?)"$') {
            $key = $Matches[1]
            continue
        }
    }

    return $stack[0]
}

function Test-DotNetRuntime {
    param ([string]$VersionPrefix)

    try {
        $installed = & dotnet --list-runtimes 2>$null
        return $installed -match "^Microsoft\.NETCore\.App\s+$VersionPrefix"
    }
    catch {
        return $false
    }
}

function Get-SteamPath {
    if ($OsTypeWindows) {
        try {
            $SteamReg = Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction Stop
            return $SteamReg.SteamPath
        }
        catch {
            return $null
        }
    }
    else {
        $possiblePaths = @(
            "$HOME/.steam/steam",
            "$HOME/.local/share/Steam",
            "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                return $path
            }
        }
        return $null
    }
}

function Install-DotNetRuntime {
    param (
        [string]$Version,
        [string]$Url
    )

    if ($OsTypeWindows) {
        Show-Message "Installing .NET $Version runtime..." "Installation"
        $installer = Join-Path $dotnetInstallPath "dotnet$Version.exe"
        
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $Url -OutFile $installer -UseBasicParsing
        Start-Process -FilePath $installer -ArgumentList "/install", "/quiet", "/norestart" -Wait
        Show-Message ".NET $Version installation completed." "Installation"
    }
    else {
        Show-Message ".NET $Version runtime not found.`n`nPlease install it manually using your package manager or from: https://dotnet.microsoft.com/download/dotnet" "Warning" "Warning"
        
        if (-not (Show-Question "Continue anyway?")) {
            exit
        }
    }
}

function Ensure-MelonLoader {
    param (
        [string]$TargetDir,
        [switch]$Force
    )

    $melonDll = Join-Path $TargetDir "MelonLoader/MelonLoader.dll"

    if (-not $Force -and (Test-Path $melonDll)) {
        Show-Message "MelonLoader already present. Skipping download." "MelonLoader"
        return
    }

    Show-Message "Downloading MelonLoader alpha-development nightly..." "MelonLoader"

    $MelonLoaderUrl = "https://nightly.link/LavaGang/MelonLoader/workflows/build/alpha-development/MelonLoader.Windows.x64.CI.Release.zip"
    $MelonZip = Join-Path $ToolDir "MelonLoader.zip"

    Invoke-WebRequest $MelonLoaderUrl -OutFile $MelonZip
    Expand-Archive $MelonZip $TargetDir -Force
}

function Create-DesktopShortcut {
    param (
        [string]$ShortcutName,
        [string]$TargetPath,
        [string]$WorkingDirectory,
        [string]$IconPath = ""
    )

    if ($OsTypeWindows) {
        $Desktop = [Environment]::GetFolderPath("Desktop")
        $WshShell = New-Object -ComObject WScript.Shell
        
        $Shortcut = $WshShell.CreateShortcut((Join-Path $Desktop "$ShortcutName.lnk"))
        $Shortcut.TargetPath = $TargetPath
        $Shortcut.WorkingDirectory = $WorkingDirectory
        if ($IconPath) {
            $Shortcut.IconLocation = $IconPath
        }
        $Shortcut.Save()
    }
    else {
        $Desktop = "$HOME/Desktop"
        if (-not (Test-Path $Desktop)) {
            $Desktop = "$HOME/.local/share/applications"
        }
        
        $desktopFile = Join-Path $Desktop "$ShortcutName.desktop"
        
        $desktopContent = @"
[Desktop Entry]
Version=1.0
Type=Application
Name=$ShortcutName
Exec="$TargetPath"
Path=$WorkingDirectory
Icon=$IconPath
Terminal=false
Categories=Game;
"@
        
        Set-Content -Path $desktopFile -Value $desktopContent
        
        if (Test-Path $desktopFile) {
            chmod +x $desktopFile 2>$null
        }
    }
}

# ===================== MAIN INSTALLATION =====================

Show-Message "Welcome to VSModded Installer!`n`nThis will download and install modded versions of Vampire Survivors." "Welcome"

# ===================== PATHS =====================
if ($OsTypeWindows) {
    $WorkDir = Join-Path $env:TEMP "VSModSetup"
} else {
    $WorkDir = Join-Path $HOME ".cache/VSModSetup"
}

$ToolDir = Join-Path $WorkDir "Tools"
$DepotDir = Join-Path $WorkDir "Depot"
$dotnet6Url = if ($OsTypeWindows) {
    "https://builds.dotnet.microsoft.com/dotnet/Runtime/6.0.36/dotnet-runtime-6.0.36-win-x64.exe"
} else {
    $null
}
$dotnet10Url = if ($OsTypeWindows) {
    "https://builds.dotnet.microsoft.com/dotnet/Runtime/10.0.1/dotnet-runtime-10.0.1-win-x64.exe"
} else {
    $null
}
$dotnetInstallPath = if ($OsTypeWindows) {
    "$env:TEMP\DotNetInstallers"
} else {
    Join-Path $HOME ".cache/DotNetInstallers"
}

New-Item -ItemType Directory -Force -Path $WorkDir, $ToolDir, $DepotDir, $dotnetInstallPath | Out-Null

# ===================== .NET RUNTIME CHECK =====================
if (-not (Test-DotNetRuntime -VersionPrefix "6.") -and $OsTypeWindows) {
    Install-DotNetRuntime -Version "6" -Url $dotnet6Url
}

if (-not (Test-DotNetRuntime -VersionPrefix "10.") -and $OsTypeWindows) {
    Install-DotNetRuntime -Version "10" -Url $dotnet10Url
}

# ===================== DETECT STEAM PATH =====================
$SteamPath = Get-SteamPath

if (-not $SteamPath -or -not (Test-Path $SteamPath)) {
    Show-Message "Steam installation not found. Please install Steam first." "Error" "Error"
    exit
}

$VdfPath = Join-Path $SteamPath "config/libraryfolders.vdf"
$TargetAppId = "1794680"
$content = Get-Content $VdfPath -Raw
$vdf = Parse-VDF $content
$SteamLib = ""

foreach ($lib in $vdf.libraryfolders.GetEnumerator()) {
    if ($lib.Value.apps.ContainsKey($TargetAppId)) {
        $path = $lib.Value.path -replace '\\\\', '\'
        $SteamLib = $path
        break
    }
}

if (-not $SteamLib) {
    $SteamLib = if ($OsTypeWindows) {
        Join-Path $SteamPath "steamapps"
    } else {
        Join-Path $SteamPath "steamapps"
    }
}

$SteamCommon = Join-Path $SteamLib "steamapps/common"
$VSModded = Join-Path $SteamCommon "VSModded"

# ===================== AUTO-DETECT STEAM USER =====================
$LoginUsersVdf = Join-Path $SteamPath "config/loginusers.vdf"
$SteamUser = $null

if (Test-Path $LoginUsersVdf) {
    $content = Get-Content $LoginUsersVdf -Raw
    $matches = [regex]::Matches($content, '"AccountName"\s+"([^"]+)"[\s\S]*?"MostRecent"\s+"1"')

    if ($matches.Count -gt 0) {
        $SteamUser = $matches[0].Groups[1].Value
    }
}

if (-not $SteamUser) {
    $SteamUser = Get-UserInput "Enter your Steam username" "Steam Login"
    if (-not $SteamUser) {
        Show-Message "Steam username is required." "Error" "Error"
        exit
    }
}

# ===================== DOWNLOAD DEPOTDOWNLOADER =====================
Show-Message "Downloading DepotDownloader..." "Download"

$DepotRelease = Invoke-RestMethod "https://api.github.com/repos/SteamRE/DepotDownloader/releases/latest"
$DepotAsset = $DepotRelease.assets | Where-Object { $_.name -match "zip" } | Select-Object -First 1

$DepotZip = Join-Path $ToolDir "DepotDownloader.zip"
Invoke-WebRequest $DepotAsset.browser_download_url -OutFile $DepotZip

$DepotExtract = Join-Path $ToolDir "DepotDownloader"
Expand-Archive $DepotZip $DepotExtract -Force

$DepotDownloaderExe = if ($OsTypeWindows) {
    Get-ChildItem $DepotExtract -Recurse -Filter "DepotDownloader.exe" | Select-Object -First 1
} else {
    Get-ChildItem $DepotExtract -Recurse -Filter "DepotDownloader" | Select-Object -First 1
}

if (-not $DepotDownloaderExe) {
    $DepotDownloaderDll = Get-ChildItem $DepotExtract -Recurse -Filter "DepotDownloader.dll" | Select-Object -First 1
    if ($DepotDownloaderDll) {
        $DepotDownloaderExe = $DepotDownloaderDll
    }
}

# ===================== CREATE VSMODDED =====================
if (-not (Test-Path $VSModded)) {
    New-Item -ItemType Directory -Force -Path $VSModded | Out-Null
}

# ===================== VERSION SELECTION =====================
if ($UseGUI -and $OsTypeWindows) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Choose Game Version"
    $form.Size = New-Object System.Drawing.Size(300, 180)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(260, 20)
    $label.Text = "Select game version:"
    $form.Controls.Add($label)
    
    $radioButton113 = New-Object System.Windows.Forms.RadioButton
    $radioButton113.Location = New-Object System.Drawing.Point(30, 50)
    $radioButton113.Size = New-Object System.Drawing.Size(240, 20)
    $radioButton113.Checked = $true
    $radioButton113.Text = "Version 1.13"
    $form.Controls.Add($radioButton113)
    
    $radioButton114 = New-Object System.Windows.Forms.RadioButton
    $radioButton114.Location = New-Object System.Drawing.Point(30, 80)
    $radioButton114.Size = New-Object System.Drawing.Size(240, 20)
    $radioButton114.Text = "Version 1.14"
    $form.Controls.Add($radioButton114)
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(115, 110)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)
    
    $result = $form.ShowDialog()
    
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        exit
    }
    
    $ActiveDepots = if ($radioButton113.Checked) { $Depots113 } else { $Depots114 }
} elseif ($UseGUI -and $OsTypeLinux) {
    $result = zenity --list --radiolist --title="Choose Game Version" --text="Select game version:" `
        --column="" --column="Version" --column="Description" `
        TRUE "1.13" "Version 1.13" `
        FALSE "1.14" "Version 1.14" `
        --hide-column=2 --width=400 --height=250 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        exit
    }
    
    $ActiveDepots = if ($result -match "1.13") { $Depots113 } else { $Depots114 }
} else {
    Write-Host "1. Version 1.13"
    Write-Host "2. Version 1.14"
    [int]$versionChoice = Read-Host "Select version"
    $ActiveDepots = if ($versionChoice -eq 1) { $Depots113 } else { $Depots114 }
}

# ===================== INSTALL MODE =====================
$installMode = if ($UseGUI) {
    Show-Question "Install all components?`n`nYes = Full install (Game + all DLCs)`nNo = Select individual components" "Install Mode"
} else {
    $choice = Read-Host "Full install (1) or select components (2)?"
    $choice -eq "1"
}

if ($installMode) {
    $DepotsToDownload = $ActiveDepots
} else {
    $componentNames = $ActiveDepots | ForEach-Object { $_.Name }
    $selected = Show-ListSelection "Select Components" "Choose components to install:" $componentNames $true
    
    if (-not $selected) {
        Show-Message "No components selected. Installation cancelled." "Cancelled" "Warning"
        exit
    }
    
    $DepotsToDownload = foreach ($i in $selected) {
        $ActiveDepots[$i]
    }
}

# ===================== MELONLOADER CHECK =====================
$wantMelon = $true

if (Test-Path (Join-Path $VSModded "MelonLoader")) {
    $wantMelon = Show-Question "MelonLoader already exists.`n`nRedownload MelonLoader?" "MelonLoader"
}

# ===================== DOWNLOAD SELECTED DEPOTS =====================
Show-Message "Starting depot downloads.`n`nYou may be prompted for Steam Guard authentication." "Download"

foreach ($depot in $DepotsToDownload) {
    $CurrentDepotDir = Join-Path $DepotDir $depot.DepotId
    New-Item -ItemType Directory -Force -Path $CurrentDepotDir | Out-Null

    Show-Message "Downloading $($depot.Name)..." "Download"

    $ddArgs = @(
        "-app", $depot.AppId,
        "-depot", $depot.DepotId,
        "-manifest", $depot.Manifest,
        "-username", $SteamUser,
        "-remember-password",
        "-dir", $CurrentDepotDir
    )

    if ($DepotDownloaderExe.Extension -eq ".dll") {
        & dotnet $DepotDownloaderExe.FullName @ddArgs
    } else {
        & $DepotDownloaderExe.FullName @ddArgs
    }

    Get-ChildItem $CurrentDepotDir -Force |
        Where-Object { $_.Name -ne ".DepotDownloader" } |
        Copy-Item -Destination $VSModded -Recurse -Force
}

# ===================== DOWNLOAD MELONLOADER =====================
if ($wantMelon) {
    Ensure-MelonLoader -TargetDir $VSModded -Force:$wantMelon
}

# ===================== DOWNLOAD ICON =====================
$IconUrl = "https://github.com/takacomic/VSModdedScript/raw/main/VSModded.ico"
$IconPath = Join-Path $VSModded "VSModded.ico"

Invoke-WebRequest $IconUrl -OutFile $IconPath

# ===================== DOWNLOAD COFFINTECH MOD =====================
Show-Message "Downloading latest CoffinTech mod..." "Mods"

$ModsDir = Join-Path $VSModded "Mods"
New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null

try {
    # Get latest release info from GitHub API
    $CoffinTechRelease = Invoke-RestMethod "https://api.github.com/repos/takacomic/CoffinTech/releases/latest"
    
    # Find the CoffinTech.dll asset
    $CoffinTechAsset = $CoffinTechRelease.assets | Where-Object { $_.name -eq "CoffinTech.dll" } | Select-Object -First 1
    
    if ($CoffinTechAsset) {
        $CoffinTechPath = Join-Path $ModsDir "CoffinTech.dll"
        Invoke-WebRequest $CoffinTechAsset.browser_download_url -OutFile $CoffinTechPath
        Show-Message "CoffinTech mod installed successfully!`nVersion: $($CoffinTechRelease.tag_name)" "Mods"
    } else {
        Show-Message "CoffinTech.dll not found in latest release. Skipping mod installation." "Warning" "Warning"
    }
} catch {
    Show-Message "Failed to download CoffinTech mod: $($_.Exception.Message)`n`nYou can manually download it from:`nhttps://github.com/takacomic/CoffinTech/releases" "Warning" "Warning"
}

# ===================== CREATE SHORTCUTS =====================
$exeName = if ($OsTypeWindows) { "VampireSurvivors.exe" } else { "VampireSurvivors.exe" }
$exePath = Join-Path $VSModded $exeName

Create-DesktopShortcut -ShortcutName "VSModded" -TargetPath $exePath -WorkingDirectory $VSModded -IconPath $IconPath
Create-DesktopShortcut -ShortcutName "VSModded (Folder)" -TargetPath $VSModded -WorkingDirectory $VSModded

# ===================== LINUX PROTON NOTES =====================
if ($OsTypeLinux) {
    Show-Message "To run VSModded with Proton:`n`n1. Add VSModded as a Non-Steam game in Steam`n2. Right-click > Properties > Compatibility`n3. Enable 'Force the use of a specific Steam Play compatibility tool'`n4. Select a Proton version (Proton Experimental recommended)`n`nGame location: $VSModded" "Linux Setup" "Info"
}

# ===================== CLEANUP =====================
try {
    if (Test-Path $DepotZip) {
        Remove-Item $DepotZip -Force
    }
    if (Test-Path $DepotExtract) {
        Remove-Item $DepotExtract -Recurse -Force
    }
    $MelonZip = Join-Path $ToolDir "MelonLoader.zip"
    if (Test-Path $MelonZip) {
        Remove-Item $MelonZip -Force
    }
}
catch {
    # Silent cleanup failure
}

# ===================== DONE =====================
Show-Message "VSModded setup complete!`n`nInstallation directory:`n$VSModded`n`nDesktop shortcuts have been created." "Success" "Info"