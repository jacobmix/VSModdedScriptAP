@echo off
REM VSModded Installer Launcher for Windows
REM This script checks for PowerShell and runs the cross-platform installer

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%vsmodded_gui.ps1"

echo === VSModded Installer Launcher ===
echo.

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo [ERROR] VSModdedInstall-CrossPlatform.ps1 not found!
    echo Please ensure the PowerShell script is in the same directory as this launcher.
    pause
    exit /b 1
)

REM Check for PowerShell Core (pwsh) first
where pwsh >nul 2>&1
if %errorlevel% equ 0 (
    set "PWSH_CMD=pwsh"
    echo [OK] PowerShell Core found
    goto :check_version
)

REM Fall back to Windows PowerShell
where powershell >nul 2>&1
if %errorlevel% equ 0 (
    set "PWSH_CMD=powershell"
    echo [OK] Windows PowerShell found
    goto :check_version
)

REM PowerShell not found
echo [ERROR] PowerShell not found!
echo.
echo PowerShell is required to run this installer.
echo.
echo For Windows 10/11, PowerShell should be pre-installed.
echo If you're on an older system, please install PowerShell Core from:
echo   https://github.com/PowerShell/PowerShell/releases
echo.
pause
exit /b 1

:check_version
REM Check PowerShell version
for /f "tokens=*" %%i in ('%PWSH_CMD% -NoProfile -Command "$PSVersionTable.PSVersion.Major"') do set PS_VERSION=%%i

if !PS_VERSION! lss 7 (
    echo [WARNING] PowerShell version !PS_VERSION! detected.
    echo [WARNING] PowerShell 7.0 or higher is recommended.
    echo.
    echo You can download PowerShell 7 from:
    echo   https://github.com/PowerShell/PowerShell/releases
    echo.
    set /p "CONTINUE=Continue anyway? (y/N): "
    if /i not "!CONTINUE!"=="y" (
        echo Installation cancelled.
        pause
        exit /b 1
    )
) else (
    echo [OK] PowerShell version !PS_VERSION!
)

REM Check for .NET runtime (informational)
where dotnet >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] .NET SDK/Runtime found
) else (
    echo [INFO] .NET Runtime not detected
    echo [INFO] The installer will attempt to install required .NET versions.
)

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [WARNING] Not running as Administrator!
    echo [WARNING] Some operations may require elevated privileges.
    echo.
    echo Right-click this file and select "Run as administrator" for best results.
    echo.
    set /p "CONTINUE=Continue without admin rights? (y/N): "
    if /i not "!CONTINUE!"=="y" (
        echo Installation cancelled.
        pause
        exit /b 1
    )
)

echo.
echo === Starting PowerShell Installer ===
echo.

REM Run the PowerShell script
%PWSH_CMD% -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

set EXIT_CODE=%errorlevel%

echo.
if %EXIT_CODE% equ 0 (
    echo === Installation completed successfully ===
) else (
    echo === Installation failed with exit code %EXIT_CODE% ===
)

pause
exit /b %EXIT_CODE%
