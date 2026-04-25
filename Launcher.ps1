# 1. Admin jogok kerese
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Utvonalak es Mappak
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot
$GlobalLogDir = "C:\Temp\HardwareConflict\LOG"
if (!(Test-Path $GlobalLogDir)) { New-Item -ItemType Directory -Path $GlobalLogDir -Force }

# 3. Allapotfelmeres
$isSafeMode = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"
$HasLog = Test-Path (Join-Path $GlobalLogDir "Fix_Activity.log")
$DisabledCount = (Get-PnpDevice | Where-Object { $_.Status -eq "Disabled" }).Count

Write-Host "--- HardwareConflict-Resolver (G500 Service Edition) ---" -ForegroundColor Cyan

if ($isSafeMode) {
    Write-Host "[!] CSOKKENTETT MOD: Eszkozok tiltasa fagyas ellen..." -ForegroundColor Yellow
    & "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"
} else {
    Write-Host "[+] NORMAL MOD: Ellenorzes..." -ForegroundColor Green
    
    if ($DisabledCount -gt 0) {
        Write-Host "Talaltam letiltott hardvert ($DisabledCount db). Inditom a biztonsagos visszakapcsolast."
        & "$PSScriptRoot\Fix\Install-Drivers.ps1"
    } else {
        Write-Host "[DONE] Nincs letiltott eszkoz, a rendszer stabilnak tunik." -ForegroundColor Green
    }
}

# 4. Log megnyitasa
Write-Host "Log megnyitasa..."
notepad.exe (Join-Path $GlobalLogDir "Install.log")
