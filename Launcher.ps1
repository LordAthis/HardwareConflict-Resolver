# 1. Admin jogok es munkakonyvtar
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

# Launcher.ps1 - Halozat kenyszeritett visszakapcsolasa a letoltes elott
Write-Host "Halozati eszkozok ellenorzese..." -ForegroundColor Cyan
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Network*" -or $_.FriendlyName -like "*Wireless*" -or $_.FriendlyName -like "*Wi-Fi*" } | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue


# 2. Mappak es Automata Driver Letoltes
$DriverDir = Join-Path $PSScriptRoot "Drivers"
$LogDir = Join-Path $PSScriptRoot "LOG"
foreach ($dir in @($DriverDir, $LogDir)) { if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force } }

$Drivers = @{
    "Intel_HD4000.exe" = "https://intel.com"
    "AMD_Radeon.exe"   = "https://lenovo.com"
}

foreach ($file in $Drivers.Keys) {
    $path = Join-Path $DriverDir $file
    if (!(Test-Path $path)) {
        Write-Host "[!] $file hianyzik. Letoltes folyamatban..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $Drivers[$file] -OutFile $path
    }
}

# 3. Allapotfelmeres es Donteshozatal (IDE KERULT A KERDEZETT BLOKK)
$FixLog = Join-Path $LogDir "Fix_Activity.log"
$isSafeMode = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"

Write-Host "--- HardwareConflict-Resolver FOLYAMAT ---" -ForegroundColor Cyan

if ($isSafeMode) {
    # Csokkentett modban mindig a tiltast futtatjuk
    Write-Host "[!] Csokkentett mod: Eszkozok tiltasa..." -ForegroundColor Yellow
    & ".\Fix\LenovoG500-GraphicsConflict.ps1"
    "--- JAVITAS KESZ ---" | Out-File $FixLog -Append
} else {
    # Normal modban log alapjan dontunk
    if (Test-Path $FixLog) {
        $LogContent = Get-Content $FixLog
        if ($LogContent -contains "--- JAVITAS KESZ ---") {
            Write-Host "[+] Tiltasok mar megtortentek. Inditom a telepito modult..." -ForegroundColor Green
            & ".\Fix\LenovoG500Install-Drivers.ps1"
        } else {
            Write-Host "[!] Nincs lezart javitas a logban. Tiltas inditasa..."
            & ".\Fix\LenovoG500-GraphicsConflict.ps1"
            "--- JAVITAS KESZ ---" | Out-File $FixLog -Append
        }
    } else {
        Write-Host "[!] Elso futas: Tiltas inditasa..."
        & ".\Fix\LenovoG500-GraphicsConflict.ps1"
        "--- JAVITAS KESZ ---" | Out-File $FixLog -Append
    }
}

# 4. Vegere a Log megnyitasa
if (Test-Path $FixLog) { notepad.exe $FixLog }
