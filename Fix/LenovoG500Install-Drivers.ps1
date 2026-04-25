# --- KONFIGURACIO ---
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DriverDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Drivers"
$LogFile = ".\LOG\Install.log"

function Write-InstallLog($msg) {
    "$(Get-Date -Format 'HH:mm:ss') - $msg" | Out-File $LogFile -Append
    Write-Host $msg -ForegroundColor Cyan
}

# --- HALOZATI ELLENORZES ---
Write-InstallLog "Halozati kapcsolat ellenorzese..."
$testHost = "8.8.8.8" # Google DNS
$connectionLimit = 5
$connected = $false

for ($i=1; $i -le $connectionLimit; $i++) {
    if (Test-Connection -ComputerName $testHost -Count 1 -Quiet) {
        $connected = $true
        Write-InstallLog "[OK] Internetkapcsolat rendben."
        break
    } else {
        Write-InstallLog "[!] Nincs internet. Probalkozas ($i/$connectionLimit)..."
        Start-Sleep -Seconds 3
    }
}

if (-not $connected) {
    Write-Warning "CRITICAL: Nincs internetkapcsolat! A driver letoltes sikertelen lesz."
    Write-InstallLog "HIBA: Nincs internet, a folyamat megszakadt."
    # Itt eldöntheted, hogy megálljon-e a script:
    # return 
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

# ... (Install-Drivers.ps1 vege felé)
Write-InstallLog "VGA frissites-vedelem aktivalasa..."
& "$PSScriptRoot\LenovoG500Block-VGA-Updates.ps1"

Write-InstallLog "--- AUTOMATA FOLYAMAT VEGE ---"



Write-InstallLog "--- AUTOMATA FOLYAMAT VEGE ---"
