$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BaseDir = Split-Path $PSScriptRoot -Parent
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$DriverDir = Join-Path $BaseDir "Drivers\$OSArch"

Write-Host "Driverek kenyszeritett telepitese..." -ForegroundColor Cyan

# 1. INTEL TELEPITES (Kicsomagolt mappabol)
$IntelPath = Join-Path $DriverDir "Intel_HD4000"
if (Test-Path $IntelPath) {
    Write-Host "Intel INF alapu telepites inditasa..." -ForegroundColor Yellow
    # Megkeressuk az elso ervenyes INF fajlt a mappaban
    $InfFile = Get-ChildItem -Path $IntelPath -Recurse -Filter "*.inf" | Select-Object -First 1
    if ($InfFile) {
        pnputil /add-driver $InfFile.FullName /install /reboot
    }
} else {
    Write-Warning "Intel mappa nem talalhato: $IntelPath"
}

# 2. AMD TELEPITES (EXE-bol)
$AMDExe = Join-Path $DriverDir "AMD_Radeon.exe"
if (Test-Path $AMDExe) {
    Write-Host "AMD EXE telepites inditasa..." -ForegroundColor Yellow
    Start-Process $AMDExe -ArgumentList "/s /v/qn" -Wait
}

# 3. FRISSITES TILTAS
& "$PSScriptRoot\LenovoG500Block-VGA-Updates.ps1"

# 4. VESGO ELLENORZES (JSON ALAPJAN)
$Config = Get-Content "$BaseDir\data\GodDriverConf.json" | ConvertFrom-Json
$TargetDrivers = $Config.Drivers | Where-Object { $_.Arch -eq $OSArch }

$FinalSuccess = $true
foreach ($D in $TargetDrivers) {
    $Status = & "$BaseDir\Scripts\Check-DriverStatus.ps1" -TargetVersion $D.TargetVersion -HardwareID $D.HWID
    if (!$Status) { $FinalSuccess = $false }
}

if ($FinalSuccess) {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\HardwareConflictResolver" -Name "FinalInstall" -Value "Done" -PropertyType String -Force | Out-Null
    Write-Host "MINDEN KESZ ES ELLENORIZVE!" -ForegroundColor Green
    & "$BaseDir\Scripts\Set-NormalBoot.ps1"
} else {
    Write-Error "Az ellenorzes hibat jelzett a telepites vegen!"
}
