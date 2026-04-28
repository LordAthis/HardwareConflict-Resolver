$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BaseDir = Split-Path $PSScriptRoot -Parent
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$DriverDir = Join-Path $BaseDir "Drivers\$OSArch"
$TempExtract = "C:\Temp\Intel_HD4000_Temp"

Write-Host "--- Driver telepites (EXE / CAB / MAPPA) ---" -ForegroundColor Cyan

# --- 1. INTEL KEZELES (Prioritas: Mappa > CAB > EXE) ---
$IntelMappa = Join-Path $DriverDir "Intel_HD4000"
$IntelCab = Join-Path $DriverDir "Intel_HD4000.cab"
$IntelExe = Join-Path $DriverDir "Intel_HD4000.exe"

if (Test-Path $IntelMappa) {
    Write-Log "Intel: Mappa detektalva, telepites..."
    $Inf = Get-ChildItem -Path $IntelMappa -Recurse -Filter "*.inf" | Select-Object -First 1
    if ($Inf) { pnputil /add-driver $Inf.FullName /install }
}
elseif (Test-Path $IntelCab) {
    Write-Log "Intel: .CAB detektalva, kibontas es telepites..."
    if (!(Test-Path $TempExtract)) { New-Item -ItemType Directory -Path $TempExtract -Force | Out-Null }
    expand $IntelCab -F:* $TempExtract | Out-Null
    $Inf = Get-ChildItem -Path $TempExtract -Recurse -Filter "*.inf" | Select-Object -First 1
    if ($Inf) { pnputil /add-driver $Inf.FullName /install }
    Remove-Item -Path $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
}
elseif (Test-Path $IntelExe) {
    Write-Log "Intel: .EXE detektalva, futtatas..."
    Start-Process $IntelExe -ArgumentList "-s -a" -Wait
}

# --- 2. AMD KEZELES ---
$AmdExe = Join-Path $DriverDir "AMD_Radeon.exe"
if (Test-Path $AmdExe) {
    Write-Log "AMD: Telepites inditasa..."
    Start-Process $AmdExe -ArgumentList "/s /v/qn" -Wait
}

# --- 3. RENDRAKAS ES ELLENORZES ---
& "$PSScriptRoot\LenovoG500Block-VGA-Updates.ps1"

$Config = Get-Content "$BaseDir\data\GodDriverConf.json" | ConvertFrom-Json
$TargetDrivers = $Config.Drivers | Where-Object { $_.Arch -eq $OSArch }

$FinalSuccess = $true
foreach ($D in $TargetDrivers) {
    $Status = & "$BaseDir\Scripts\Check-DriverStatus.ps1" -TargetVersion $D.TargetVersion -HardwareID $D.HWID
    if (!$Status) { $FinalSuccess = $false }
}

if ($FinalSuccess) {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\HardwareConflictResolver" -Name "FinalInstall" -Value "Done" -PropertyType String -Force | Out-Null
    Write-Host "MINDEN SIKERES!" -ForegroundColor Green
    & "$BaseDir\Scripts\Set-NormalBoot.ps1"
} else {
    Write-Error "Az ellenorzes nem felelt meg az eloirasoknak!"
}
