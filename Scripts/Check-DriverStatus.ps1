param([string]$TargetVersion, [string]$HardwareID)

# Driver verzio lekerdezese a PnP eszkozok kozul
$CurrentDriver = Get-PnpDeviceProperty -InstanceId (Get-PnpDevice -FriendlyName "*$HardwareID*").InstanceId -KeyName "DEVPKEY_Device_DriverVersion" -ErrorAction SilentlyContinue

if ($CurrentDriver.Data -eq $TargetVersion) {
    return $true
} else {
    return $false
}
