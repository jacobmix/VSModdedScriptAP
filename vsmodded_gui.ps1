#Requires -Version 7.0
# Cross-platform Vampire Survivors AP installer with GUI for Windows and Linux

# ===================== USER CONFIG =====================
$Depots = @(
    @{ AppId = 1794680; DepotId = 1794681; Manifest = 5929929350734574725; Name = "Main Game 1.14" },
    @{ AppId = 2230760; DepotId = 2230761; Manifest = 6626234685557471330; Name = "Moonspell 1.14" },
    @{ AppId = 2313550; DepotId = 2313551; Manifest = 258978471953775490; Name = "Foscari 1.14" },
    @{ AppId = 2690330; DepotId = 2690331; Manifest = 1027692196364748982; Name = "Meeting 1.14" },
    @{ AppId = 2887680; DepotId = 2887681; Manifest = 3914729547287146862; Name = "Guns 1.14" },
    @{ AppId = 3210350; DepotId = 3210351; Manifest = 1856258357613603873; Name = "OtC 1.14" },
    @{ AppId = 3451100; DepotId = 3451101; Manifest = 7326781866595278644; Name = "Emerald 1.14" },
    @{ AppId = 3929770; DepotId = 3929771; Manifest = 239795049570881193; Name = "Ante 1.14" }
)
$ActiveDepots = $Depots | Where-Object { $_.Name -match "1\.14" }
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
        [string]$Title = "Vampire Survivors AP Installer",
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
        [string]$Title = "Vampire Survivors AP Installer"
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
        [string]$Title = "Vampire Survivors AP Installer",
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
				[void]$listBox.Items.Add($item, $true)
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
                $zenityItems += "TRUE"
                $zenityItems += "$($i + 1)"
                $zenityItems += $Items[$i]
            }
            
            $result = zenity --list --checklist --title="$Title" --text="$Message" `
                --column="" --column="Index" --column="Component" `
                --hide-column=2 --width=500 --height=400 `
                @zenityItems 2>$null
            
            if ($LASTEXITCODE -eq 0 -and $result) {
				$result -split '\|' | ForEach-Object {
					[int]$_ - 1
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

Show-Message "Welcome to Vampire Survivors AP Installer!`n`nThis will download and install Archipelago version of Vampire Survivors." "Welcome"

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

#$VSAPPath = "C:\ProgramData\Archipelago\Vampire Survivors AP"
$ArchipelagoRoot = "C:\ProgramData\Archipelago"

if (Test-Path $ArchipelagoRoot) {
    $VSAPPath = Join-Path $ArchipelagoRoot "Vampire Survivors AP"
} else {
    $SteamCommon = Join-Path $SteamLib "steamapps/common"
    $VSAPPath = Join-Path $SteamCommon "Vampire Survivors AP"
}

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

# ===================== CREATE Vampire Survivors AP =====================
if (-not (Test-Path $VSAPPath)) {
    New-Item -ItemType Directory -Force -Path $VSAPPath | Out-Null
}

# ===================== INSTALL MODE =====================
# Main game is always required
$MainDepot = $ActiveDepots | Where-Object { $_.AppId -eq 1794680 }

# Optional DLCs
$DlcDepots = $ActiveDepots | Where-Object { $_.AppId -ne 1794680 }

$DepotsToDownload = @($MainDepot)

if ($DlcDepots.Count -gt 0) {
    $selectedIndexes = Show-ListSelection `
        -Title "DLC Selection" `
        -Message "Select DLCs to download (optional):" `
        -Items ($DlcDepots | ForEach-Object { $_.Name })

    if ($selectedIndexes) {
        foreach ($index in $selectedIndexes) {
            if ($index -ge 0 -and $index -lt $DlcDepots.Count) {
                $DepotsToDownload += $DlcDepots[$index]
            }
        }
    }
}

# ===================== MELONLOADER CHECK =====================
$wantMelon = $true

if (Test-Path (Join-Path $VSAPPath "MelonLoader")) {
    $wantMelon = Show-Question "MelonLoader already exists.`n`nRedownload MelonLoader?" "MelonLoader"
}

# ===================== DOWNLOAD SELECTED DEPOTS =====================
Show-Message "Starting depot downloads.`n`nYou may be prompted for Steam Guard authentication." "Download"

foreach ($depot in $DepotsToDownload) {
    $CurrentDepotDir = Join-Path $DepotDir $depot.DepotId
    New-Item -ItemType Directory -Force -Path $CurrentDepotDir | Out-Null

    # Show-Message "Downloading $($depot.Name)..." "Download"
	Write-Host "Downloading: $($depot.Name)..."

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
        Copy-Item -Destination $VSAPPath -Recurse -Force
}

# ===================== DOWNLOAD MELONLOADER =====================
if ($wantMelon) {
    Ensure-MelonLoader -TargetDir $VSAPPath -Force:$wantMelon
}

$ModsDir = Join-Path $VSAPPath "Mods"
$userLibsDest = Join-Path $VSAPPath "UserLibs"

New-Item -ItemType Directory -Path $ModsDir -Force | Out-Null
New-Item -ItemType Directory -Path $userLibsDest -Force | Out-Null

# ===================== DOWNLOAD ICON =====================
#$IconUrl = "https://github.com/takacomic/Vampire Survivors APScript/raw/main/Vampire Survivors AP.ico"
#$IconPath = Join-Path $VSAPPath "Vampire Survivors AP.ico"

#Invoke-WebRequest $IconUrl -OutFile $IconPath

# ===================== DOWNLOAD COFFINTECH MOD =====================
Show-Message "Downloading latest CoffinTech mod..." "Mods"

try {
    $Headers = @{
        "Accept" = "application/vnd.github+json"
        "User-Agent" = "VS-Mod-Installer"
    }

    $CoffinTechRelease = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/takacomic/CoffinTech/releases/latest" `
        -Headers $Headers `
        -ErrorAction Stop

    $CoffinTechAsset = $CoffinTechRelease.assets |
        Where-Object { $_.name -eq "CoffinTech.dll" } |
        Select-Object -First 1

    if ($CoffinTechAsset) {
        $CoffinTechPath = Join-Path $ModsDir "CoffinTech.dll"

        Invoke-WebRequest `
            -Uri $CoffinTechAsset.browser_download_url `
            -OutFile $CoffinTechPath `
            -ErrorAction Stop

        Show-Message "CoffinTech mod installed successfully!`nVersion: $($CoffinTechRelease.tag_name)" "Mods"
    }
    else {
        Show-Message "CoffinTech.dll not found in latest release. Skipping mod installation." "Warning" "Warning"
    }
}
catch {
    Show-Message "Failed to download CoffinTech mod: $($_.Exception.Message)`n`nYou can manually download it from:`nhttps://github.com/takacomic/CoffinTech/releases" "Warning" "Warning"
}

# ===================== DOWNLOAD ARCHIPELAGO MOD =====================
Show-Message "Downloading ArchipelagoSurvivors..." "Mods"

$APZip = Join-Path $ToolDir "ArchipelagoSurvivors.zip"

Invoke-WebRequest `
    "https://github.com/SWCreeperKing/ArchipelagoSurvivors/releases/latest/download/ArchipelagoSurvivors.zip" `
    -OutFile $APZip

$APExtract = Join-Path $ToolDir "ArchipelagoSurvivors"

if (Test-Path $APExtract) {
    Remove-Item $APExtract -Recurse -Force
}

Expand-Archive $APZip $APExtract -Force

$APRoot = Join-Path $APExtract "ArchipelagoSurvivors"

if (-not (Test-Path $APRoot)) {
    throw "Expected ArchipelagoSurvivors folder not found in archive."
}

Copy-Item `
    (Join-Path $APRoot "Mods\*") `
    $ModsDir `
    -Recurse -Force

Copy-Item `
    (Join-Path $APRoot "UserLibs\*") `
    $userLibsDest `
    -Recurse -Force

Show-Message "ArchipelagoSurvivors installed successfully!" "Mods"

# ===================== CREATE SHORTCUTS =====================
if ($OsTypeWindows -and (Show-Question "Create a desktop shortcut for Vampire Survivors AP?" "Shortcut")) {
	$exeName = if ($OsTypeWindows) { "VampireSurvivors.exe" } else { "VampireSurvivors.exe" }
	$exePath = Join-Path $VSAPPath $exeName

    Create-DesktopShortcut `
        -ShortcutName "Vampire Survivors AP" `
        -TargetPath $exePath `
        -WorkingDirectory $VSAPPath

    Write-Host "Desktop shortcut created."
}
else {
    Write-Host "Skipping shortcut creation."
}

# Create-DesktopShortcut -ShortcutName "Vampire Survivors AP" -TargetPath $exePath -WorkingDirectory $VSAPPath -IconPath $IconPath
# Create-DesktopShortcut -ShortcutName "Vampire Survivors AP (Folder)" -TargetPath $VSAPPath -WorkingDirectory $VSAPPath

# ===================== LINUX PROTON NOTES =====================
if ($OsTypeLinux) {
    Show-Message "To run Vampire Survivors AP with Proton:`n`n1. Add Vampire Survivors AP as a Non-Steam game in Steam`n2. Right-click > Properties > Compatibility`n3. Enable 'Force the use of a specific Steam Play compatibility tool'`n4. Select a Proton version (Proton Experimental recommended)`n`nGame location: $VSAPPath" "Linux Setup" "Info"
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

    # Remove downloaded depot contents
    if (Test-Path $DepotDir) {
        Remove-Item $DepotDir -Recurse -Force
    }
}
catch {
    # Silent cleanup failure
}

# ===================== DONE =====================
Show-Message "Vampire Survivors AP setup complete!`n`nInstallation directory:`n$VSAPPath" "Success" "Info"
