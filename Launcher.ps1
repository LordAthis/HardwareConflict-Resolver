$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

# Admin jog kérése
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 1. Hálózat és beviteli eszközök kényszerített feloldása (Hogy ne legyen szívás)
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Network*" -or $_.FriendlyName -like "*Wireless*" -or $_.FriendlyName -like "*Mouse*" } | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

# 2. Driverek letöltése (Ha hiányoznak)
$Drivers = @{
    "Intel_HD4000.exe" = "https://intel.com"
    "AMD_Radeon.exe"   = "https://lenovo.com"
}
$DriverDir = New-Item -ItemType Directory -Path ".\Drivers" -Force
foreach ($f in $Drivers.Keys) {
    $p = Join-Path $DriverDir $f
    if (!(Test-Path $p)) { Invoke-WebRequest -Uri $Drivers[$f] -OutFile $p }
    Unblock-File $p # A letöltött driver feloldása!
}

# 3. Mód szerinti futtatás
$isSafe = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"
if ($isSafe) {
    & ".\Fix\LenovoG500-GraphicsConflict.ps1"
    Write-Host "Kész! Indítsd újra normál módban!" -ForegroundColor Green
} else {
    & ".\Fix\LenovoG500Install-Drivers.ps1"
}
