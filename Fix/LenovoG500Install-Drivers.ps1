$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DriverDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Drivers"

# 1. Intel HD 4000 Kényszerített telepítése
Write-Host "Intel kényszerítése..." -ForegroundColor Cyan
$IntelExe = Join-Path $DriverDir "Intel_HD4000.exe"

# Kicsomagolás (Silent módban ideiglenes helyre)
$ExtractPath = "C:\Temp\IntelExtract"
Start-Process $IntelExe -ArgumentList "-s -a -p $ExtractPath" -Wait

# INF alapú kényszerített telepítés (Ez a "Have Disk" parancssori megfelelője)
$InfFile = Get-ChildItem -Path $ExtractPath -Recurse -Filter "*.inf" | Select-Object -First 1
if ($InfFile) {
    pnputil /add-driver $InfFile.FullName /install /reboot
}

# 2. AMD aktválása és telepítése
Write-Host "AMD telepítése..." -ForegroundColor Cyan
$AMDExe = Join-Path $DriverDir "AMD_Radeon.exe"
Start-Process $AMDExe -ArgumentList "/s /v/qn" -Wait

# 3. Frissítések tiltása, hogy a Windows ne rontsa el
& ".\LenovoG500Block-VGA-Updates.ps1"

Write-Host "MINDEN KÉSZ!" -ForegroundColor Green
