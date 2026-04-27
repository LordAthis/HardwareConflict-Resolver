param([string]$TargetVersion, [string]$HardwareID)

$Device = Get-PnpDevice | Where-Object { $_.InstanceId -like "*$HardwareID*" -or $_.FriendlyName -like "*$HardwareID*" } | Select-Object -First 1
if (!$Device) { return $false }

$CurrentVersion = (Get-PnpDeviceProperty -InstanceId $Device.InstanceId -KeyName "DEVPKEY_Device_DriverVersion").Data

if ($CurrentVersion -eq $TargetVersion) {
    Write-Host "[OK] $HardwareID verzió: $CurrentVersion" -ForegroundColor Green
    return $true
} else {
    Write-Host "[!] $HardwareID hiba: Vart: $TargetVersion / Talalt: $CurrentVersion" -ForegroundColor Red
    return $false
}
