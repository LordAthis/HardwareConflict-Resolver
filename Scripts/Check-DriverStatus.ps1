param(
    [string]$TargetVersion, 
    [string]$HardwareID,
    [string]$DriverFileName # Pl. "igdkmd64.sys" az Intelhez
)

Write-Host "Ellenorzes: $HardwareID ($TargetVersion)..." -ForegroundColor Cyan

# 1. PnP eszkoz alapu ellenorzes
$Device = Get-PnpDevice -FriendlyName "*$HardwareID*" -ErrorAction SilentlyContinue
if (!$Device) { return $false }

$CurrentVersion = (Get-PnpDeviceProperty -InstanceId $Device.InstanceId -KeyName "DEVPKEY_Device_DriverVersion").Data

# 2. Fajl alapu mely ellenorzes (ha megadtunk fajlnevet)
$FileMatch = $true
if ($DriverFileName) {
    $DriverPath = Join-Path $env:SystemRoot "System32\drivers\$DriverFileName"
    if (Test-Path $DriverPath) {
        $FileVersion = (Get-Item $DriverPath).VersionInfo.FileVersion
        if ($FileVersion -notlike "*$TargetVersion*") { $FileMatch = $false }
    }
}

if ($CurrentVersion -eq $TargetVersion -and $FileMatch) {
    Write-Host "[OK] Verzio egyezik: $CurrentVersion" -ForegroundColor Green
    return $true
} else {
    Write-Host "[!] Verzio elteres! (Talalt: $CurrentVersion)" -ForegroundColor Red
    return $false
}
