param([string]$TargetVersion, [string]$HardwareID, [string]$DriverFileName)

Write-Host "Ellenorzes: $HardwareID..." -ForegroundColor Cyan

# Kereses HWID vagy FriendlyName alapjan
$Device = Get-PnpDevice | Where-Object { $_.InstanceId -like "*$HardwareID*" -or $_.FriendlyName -like "*$HardwareID*" } | Select-Object -First 1

if (!$Device) { 
    Write-Host "[!] Eszkoz nem talalhato!" -ForegroundColor Red
    return $false 
}

$CurrentVersion = (Get-PnpDeviceProperty -InstanceId $Device.InstanceId -KeyName "DEVPKEY_Device_DriverVersion").Data

$FileMatch = $true
if ($DriverFileName) {
    $DriverPath = Join-Path $env:SystemRoot "System32\drivers\$DriverFileName"
    if (Test-Path $DriverPath) {
        $FileVersion = (Get-Item $DriverPath).VersionInfo.FileVersion
        if ($FileVersion -notlike "*$TargetVersion*") { $FileMatch = $false }
    }
}

if ($CurrentVersion -eq $TargetVersion -and $FileMatch) {
    return $true
} else {
    return $false
}
