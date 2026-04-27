$LogFile = "C:\Temp\HardwareConflict_Install.log"
Write-Host "--- VGA Frissitesek Tiltasa (HWID alapjan) ---" -ForegroundColor Cyan

$VgaIds = Get-PnpDevice -Class Display | Select-Object -ExpandProperty HardwareID

if ($VgaIds) {
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\DenyDeviceIDs"
    if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force }

    $PolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
    Set-ItemProperty -Path $PolicyPath -Name "DenyDeviceIDs" -Value 1 -Type DWord
    Set-ItemProperty -Path $PolicyPath -Name "DenyDeviceIDsRetroactive" -Value 0 -Type DWord

    $i = 1
    foreach ($id in $VgaIds) {
        Set-ItemProperty -Path $RegPath -Name "$i" -Value $id
        $i++
    }

    "$(Get-Date) - VGA Frissitesek tiltva." | Out-File $LogFile -Append
    Write-Host "[OK] Windows Update tiltas aktivalva a VGA-ra." -ForegroundColor Green
}
