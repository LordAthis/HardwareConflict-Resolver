$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

# Admin jog kerese (Ekezetmentesen)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Mod ellenorzese
$isSafeMode = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"

Write-Host "--- HardwareConflict-Resolver AUTOMATA ---" -ForegroundColor Cyan

# 1. Audit futtatasa mindig az elejen
& "$PSScriptRoot\Tests\Hardware-Audit.ps1"

if ($isSafeMode) {
    Write-Host "[!] Csokkentett mod eszlelve: JAVITAS es TILTSOK inditasa..." -ForegroundColor Yellow
    & "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"
    Write-Host "Tiltasok kesz. Inditsd ujra a gepet NORMAL modban!" -ForegroundColor Green
} else {
    Write-Host "[+] Normal mod eszlelve: TELEPITES es VISSZAKAPCSOLAS..." -ForegroundColor Green
    # Itt ellenorizzuk a korabbi Fix logot
    if (Test-Path "$PSScriptRoot\LOG\Fix_Activity.log") {
        Write-Host "Korabbi tiltasok nyomat azonosítottam. Indithatom a drivereket?"
        & "$PSScriptRoot\Fix\Install-Drivers.ps1"
    } else {
        Write-Host "Nem talalhato korabbi javitas nyoma. Audit futtatasa javasolt."
    }
}

# Automatikus Log megnyitas a vegen
notepad.exe "$PSScriptRoot\LOG\Hardware_Audit.log"
