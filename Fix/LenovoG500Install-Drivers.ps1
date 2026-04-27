$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BaseDir = Split-Path $PSScriptRoot -Parent
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$DriverDir = Join-Path $BaseDir "Drivers\$OSArch"

# 1. Intel HD 4000
Write-Host "Intel driver kenyszeritese..." -ForegroundColor Cyan
$IntelExe = Join-Path $DriverDir "Intel_HD4000.exe"
$ExtractPath = "C:\Temp\IntelExtract"

if (Test-Path $IntelExe) {
    Start-Process $IntelExe -ArgumentList "-s -a -p $ExtractPath" -Wait
    $InfFile = Get-ChildItem -Path $ExtractPath -Recurse -Filter "*.inf" | Select-Object -First 1
    if ($InfFile) {
        pnputil /add-driver $InfFile.FullName /install /reboot
    }
}

# 2. AMD
Write-Host "AMD driver telepitese..." -ForegroundColor Cyan
$AMDExe = Join-Path $DriverDir "AMD_Radeon.exe"
if (Test-Path $AMDExe) {
    Start-Process $AMDExe -ArgumentList "/s /v/qn" -Wait
}

# 3. Tiltas futtatasa
& "$PSScriptRoot\LenovoG500Block-VGA-Updates.ps1"

Write-Host "TELEPITES BEFEJEZVE!" -ForegroundColor Green
