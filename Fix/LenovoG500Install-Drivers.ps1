$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BaseDir = Split-Path $PSScriptRoot -Parent
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$DriverDir = Join-Path $BaseDir "Drivers\$OSArch"

Write-Host "--- Driver telepites es kibontas ---" -ForegroundColor Cyan

# 1. INTEL KEZELES (.cab kibontas vagy mappa hasznalata)
$IntelCab = Join-Path $DriverDir "Intel_HD4000.cab"
$IntelPath = Join-Path $DriverDir "Intel_HD4000"

if (Test-Path $IntelCab) {
    Write-Host "Intel .cab fajl detektalva. Kibontas..." -ForegroundColor Yellow
    if (!(Test-Path $IntelPath)) { New-Item -ItemType Directory -Path $IntelPath -Force | Out-Null }
    # Windows beepitett expand parancsa
    expand $IntelCab -F:* $IntelPath | Out-Null
}

if (Test-Path $IntelPath) {
    Write-Host "Intel telepites inditasa INF alapjan..." -ForegroundColor Yellow
    $InfFile = Get-ChildItem -Path $IntelPath -Recurse -Filter "*.inf" | Select-Object -First 1
    if ($InfFile) {
        pnputil /add-driver $InfFile.FullName /install
    }
}

# 2. AMD TELEPITES
$AMDExe = Join-Path $DriverDir "AMD_Radeon.exe"
if (Test-Path $AMDExe) {
    Write-Host "AMD EXE telepites inditasa..." -ForegroundColor Yellow
    Start-Process $AMDExe -ArgumentList "/s /v/qn" -Wait
}

# 3. UPDATE TILTAS
& "$PSScriptRoot\LenovoG500Block-VGA-Updates.ps1"

# 4. VESGO ELLENORZES
$Config = Get-Content "$BaseDir\data\GodDriverConf.json" | ConvertFrom-Json
$TargetDrivers = $Config.Drivers | Where-Object { $_.Arch -eq $OSArch }

$FinalSuccess = $true
foreach ($D in $TargetDrivers) {
    # Check-DriverStatus meghivasa dinamikusan
    $Status = & "$BaseDir\Scripts\Check-DriverStatus.ps1" -TargetVersion $D.TargetVersion -HardwareID $D.HWID
    if (!$Status) { $FinalSuccess = $false }
}

if ($FinalSuccess) {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\HardwareConflictResolver" -Name "FinalInstall" -Value "Done" -PropertyType String -Force | Out-Null
    Write-Host "MINDEN SIKERESEN TELEPITVE!" -ForegroundColor Green
    & "$BaseDir\Scripts\Set-NormalBoot.ps1"
} else {
    Write-Error "A folyamat vegen az ellenorzes hibat jelzett!"
}
