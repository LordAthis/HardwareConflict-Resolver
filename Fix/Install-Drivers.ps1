# --- KONFIGURACIO ---
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DriverDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Drivers"
$LogFile = ".\LOG\Install.log"

function Write-InstallLog($msg) {
    "$(Get-Date -Format 'HH:mm:ss') - $msg" | Out-File $LogFile -Append
    Write-Host $msg -ForegroundColor Cyan
}

# Csendes telepites fuggveny
function Start-SilentInstall {
    param($ExePath, $Args)
    if (Test-Path $ExePath) {
        Write-InstallLog "Telepites inditasa: $(Split-Path $ExePath -Leaf)..."
        $process = Start-Process -FilePath $ExePath -ArgumentList $Args -Wait -PassThru
        Write-InstallLog "Telepites befejezodott (ExitCode: $($process.ExitCode))."
    } else {
        Write-InstallLog "HIBA: A telepito nem talalhato: $ExePath"
    }
}

Write-InstallLog "--- AUTOMATA CSENDES TELEPITES INDITVA ---"

# 1. Intel HD 4000 Telepitese
# Parameterek: -s (silent), -norestart (ne induljon ujra magatol)
$IntelExe = Join-Path $DriverDir "Intel_HD4000.exe"
Start-SilentInstall -ExePath $IntelExe -Args "-s -norestart"

# 2. Intel VGA Aktivalasa (hogy a driver azonnal munkaba allhasson)
Get-PnpDevice -FriendlyName "*Intel(R) HD Graphics 4000*" | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

# 3. AMD Radeon Telepitese
# Parameterek: /s (silent), /v/qn (Windows Installer csendesitese)
$AMDExe = Join-Path $DriverDir "AMD_Radeon.exe"
Start-SilentInstall -ExePath $AMDExe -Args "/s /v/qn"

# 4. AMD VGA Aktivalasa
Get-PnpDevice -FriendlyName "*AMD*", "*Radeon*" | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

# 5. Osszes maradek letiltott hardver (Hang, Wifi, stb.) visszakapcsolasa
Write-InstallLog "Maradek hardverek (Hang, HID, stb.) aktivalasa..."
Get-PnpDevice | Where-Object { $_.Status -eq "Disabled" } | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

Write-InstallLog "--- AUTOMATA FOLYAMAT VEGE ---"
