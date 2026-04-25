$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogFile = ".\LOG\Install.log"

Write-Host "--- VGA Frissitesek Tiltasa (Group Policy utanzo) ---" -ForegroundColor Cyan

# 1. VGA eszkozok Hardware ID-janak lekerdezese
$VgaIds = Get-PnpDevice -Class Display | Select-Object -ExpandProperty HardwareID

if ($VgaIds) {
    # Registry kulcs a tiltashoz
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\DenyDeviceIDs"
    if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force }

    # Tiltas bekapcsolasa (Policy aktivalas)
    $PolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
    Set-ItemProperty -Path $PolicyPath -Name "DenyDeviceIDs" -Value 1 -Type DWord
    Set-ItemProperty -Path $PolicyPath -Name "DenyDeviceIDsRetroactive" -Value 0 -Type DWord

    # Hardware ID-k beirasa a tiltolista Registrybe
    $i = 1
    foreach ($id in $VgaIds) {
        Set-ItemProperty -Path $RegPath -Name "$i" -Value $id
        $i++
    }

    "$(Get-Date) - VGA Frissitesek tiltva (HWID alapjan)." | Out-File $LogFile -Append
    Write-Host "[OK] A Windows Update tobbe nem fogja felulirni a VGA drivereket!" -ForegroundColor Green
}
