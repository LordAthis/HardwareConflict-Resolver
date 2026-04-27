$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BaseDir = Split-Path $PSScriptRoot -Parent
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$DriverDir = Join-Path $BaseDir "Drivers\$OSArch"

Write-Host "Driverek kenyszeritett telepitese..." -ForegroundColor Cyan

# Intel telepítés
$IntelExe = Join-Path $DriverDir "Intel_HD4000.exe"
if (Test-Path $IntelExe) {
    $ExtractPath = "C:\Temp\IntelExtract"
    Start-Process $IntelExe -ArgumentList "-s -a -p $ExtractPath" -Wait
    $InfFile = Get-ChildItem -Path $ExtractPath -Recurse -Filter "*.inf" | Select-Object -First 1
    if ($InfFile) { pnputil /add-driver $InfFile.FullName /install }
}

# AMD telepítés
$AMDExe = Join-Path $DriverDir "AMD_Radeon.exe"
if (Test-Path $AMDExe) { Start-Process $AMDExe -ArgumentList "/s /v/qn" -Wait }

# Frissítés tiltás
& "$PSScriptRoot\LenovoG500Block-VGA-Updates.ps1"

# VÉGSŐ ELLENŐRZÉS
$Config = Get-Content "$BaseDir\data\GodDriverConf.json" | ConvertFrom-Json
$TargetDrivers = $Config.Drivers | Where-Object { $_.Arch -eq $OSArch }

$FinalSuccess = $true
foreach ($D in $TargetDrivers) {
    $Status = & "$BaseDir\Scripts\Check-DriverStatus.ps1" -TargetVersion $D.TargetVersion -HardwareID $D.HWID
    if (!$Status) { $FinalSuccess = $false }
}

if ($FinalSuccess) {
    New-ItemProperty -Path "HKLM:\SOFTWARE\HardwareConflictResolver" -Name "FinalInstall" -Value "Done" -PropertyType String -Force | Out-Null
    Write-Host "MINDEN KESZ ÉS ELLENŐRIZVE!" -ForegroundColor Green
    & "$BaseDir\Scripts\Set-NormalBoot.ps1"
} else {
    Write-Error "A telepites lefutott, de az ellenorzes hibat jelzett!"
}
