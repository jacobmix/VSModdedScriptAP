#!/bin/bash

# VSModded Installer Launcher for Linux
# This script checks for PowerShell and runs the cross-platform installer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT="$SCRIPT_DIR/vsmodded_gui.ps1"

echo "=== VSModded Installer Launcher ==="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if PowerShell script exists
if [ ! -f "$PS_SCRIPT" ]; then
    echo -e "${RED}Error: VSModdedInstall-CrossPlatform.ps1 not found!${NC}"
    echo "Please ensure the PowerShell script is in the same directory as this launcher."
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for PowerShell
if command_exists pwsh; then
    PWSH_CMD="pwsh"
    echo -e "${GREEN}✓ PowerShell Core found${NC}"
elif command_exists powershell; then
    PWSH_CMD="powershell"
    echo -e "${GREEN}✓ PowerShell found${NC}"
else
    echo -e "${RED}✗ PowerShell not found!${NC}"
    echo ""
    echo "PowerShell Core is required to run this installer."
    echo ""
    echo "Installation options:"
    echo ""
    echo "Ubuntu/Debian:"
    echo "  sudo apt update"
    echo "  sudo apt install -y powershell"
    echo ""
    echo "Fedora:"
    echo "  sudo dnf install powershell"
    echo ""
    echo "Arch Linux:"
    echo "  yay -S powershell-bin"
    echo ""
    echo "Snap (universal):"
    echo "  sudo snap install powershell --classic"
    echo ""
    echo "For other distributions, visit:"
    echo "  https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux"
    echo ""
    exit 1
fi

# Check PowerShell version
PS_VERSION=$($PWSH_CMD -NoProfile -Command '$PSVersionTable.PSVersion.Major')

if [ "$PS_VERSION" -lt 7 ]; then
    echo -e "${YELLOW}Warning: PowerShell version $PS_VERSION detected.${NC}"
    echo -e "${YELLOW}PowerShell 7.0 or higher is recommended.${NC}"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
else
    echo -e "${GREEN}✓ PowerShell version $PS_VERSION${NC}"
fi

# Check for .NET runtime (informational)
if command_exists dotnet; then
    echo -e "${GREEN}✓ .NET SDK/Runtime found${NC}"
else
    echo -e "${YELLOW}! .NET Runtime not found${NC}"
    echo -e "${YELLOW}  You may need to install it for DepotDownloader to work.${NC}"
    echo ""
fi

# Check for Steam (informational)
STEAM_PATHS=(
    "$HOME/.steam/steam"
    "$HOME/.local/share/Steam"
    "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam"
)

STEAM_FOUND=false
for path in "${STEAM_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo -e "${GREEN}✓ Steam installation found at: $path${NC}"
        STEAM_FOUND=true
        break
    fi
done

if [ "$STEAM_FOUND" = false ]; then
    echo -e "${YELLOW}! Steam installation not detected${NC}"
    echo -e "${YELLOW}  Please ensure Steam is installed before continuing.${NC}"
    echo ""
fi

echo ""
echo "=== Starting PowerShell Installer ==="
echo ""

# Run the PowerShell script
$PWSH_CMD -NoProfile -ExecutionPolicy Bypass -File "$PS_SCRIPT"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}=== Installation completed successfully ===${NC}"
else
    echo -e "${RED}=== Installation failed with exit code $EXIT_CODE ===${NC}"
fi

exit $EXIT_CODE
