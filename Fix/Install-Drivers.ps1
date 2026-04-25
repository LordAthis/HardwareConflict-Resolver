# --- KONFIGURACIO ---
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LocalLog = Join-Path $PSScriptRoot "..\LOG\Install.log"
$GlobalLog = "C:\Temp\HardwareConflict\LOG\Install.log"

# Fuggveny a driver ellenorzesere (Registry alapjan)
function Test-DriverInstalled {
    param($SearchString)
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\*"
    $drivers = Get-ItemProperty $regPath -ErrorAction SilentlyContinue | Where-Object { $_.DriverDesc -like "*$SearchString*" }
    return ($null -ne $drivers)
}

function Write-ServiceLog {
    param($msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $msg" | Out-File -FilePath $LocalLog -Append
    "$timestamp - $msg" | Out-File -FilePath $GlobalLog -Append
    Write-Host $msg
}

# --- VEGREHAJTAS ---
Write-ServiceLog "--- Intelligens Telepites Ellenorzes Inditasa ---"

# 1. Beviteli eszkozok (Billentyuzet, Eger) - EZEKET AZONNAL VISSZA
Write-ServiceLog "Beviteli eszkozok kenyszeritene visszakapcsolasa (Whitelist)..."
Get-PnpDevice -FriendlyName "*Keyboard*", "*HID-compliant*", "*Mouse*", "*Touchpad*" | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

# 2. Intel HD 4000 Ellenorzese
$isIntelReady = Test-DriverInstalled "Intel(R) HD Graphics 4000"
if ($isIntelReady) {
    Write-ServiceLog "[OK] Intel Driver detektalva. VGA aktivalasa..."
    Get-PnpDevice -FriendlyName "*Intel(R) HD Graphics 4000*" | Enable-PnpDevice -Confirm:$false
} else {
    Write-ServiceLog "[!] Intel Driver HIANYZIK. VGA tiltva marad a fagyas elkerulese veget!"
}

# 3. AMD Radeon Ellenorzese (Csak ha az Intel mar kesz)
if ($isIntelReady) {
    $isAMDReady = Test-DriverInstalled "Radeon"
    if ($isAMDReady) {
        Write-ServiceLog "[OK] AMD Driver detektalva. Kartya aktivalasa..."
        Get-PnpDevice -FriendlyName "*AMD*" | Enable-PnpDevice -Confirm:$false
    } else {
        Write-ServiceLog "[!] AMD Driver HIANYZIK. AMD tiltva marad!"
    }
}

# 4. Egyeb eszkozok (Hang, Wifi, stb.) - Csak ha a VGA-k mar stabilak
if ($isIntelReady -and $isAMDReady) {
    Write-ServiceLog "Minden VGA stabil, maradek eszkozok aktivalasa..."
    Get-PnpDevice | Where-Object { $_.Status -eq "Disabled" } | Enable-PnpDevice -Confirm:$false
}

Write-ServiceLog "--- Telepitesi fazis vege ---"
