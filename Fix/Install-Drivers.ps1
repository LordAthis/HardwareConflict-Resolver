# Ekezetmentesitett kiirasok
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Log = Join-Path $PSScriptRoot "..\LOG\Install.log"

Write-Host "--- Driver Telepites es Visszakapcsolas ---" -ForegroundColor Cyan

# 1. Intel HD 4000 Engedelyezese (Ha le lenne tiltva)
$Intel = Get-PnpDevice -FriendlyName "*Intel(R) HD Graphics 4000*" -ErrorAction SilentlyContinue
if ($Intel) { 
    Enable-PnpDevice -InstanceId $Intel.InstanceId -Confirm:$false
    Write-Host "Intel HD 4000 engedelyezve."
}

# 2. Intel Driver telepites (A file-nak ott kell lennie a mappaban!)
# Itt megadhatod a letoltott driver exe-jet
$IntelInstaller = Join-Path $PSScriptRoot "..\Drivers\Intel_HD4000.exe"
if (Test-Path $IntelInstaller) {
    Write-Host "Intel Driver telepitese folyamatban... Kerlek varj."
    Start-Process -FilePath $IntelInstaller -ArgumentList "/S" -Wait
    Write-Host "Intel Driver kesz." -ForegroundColor Green
}

# 3. AMD Radeon Engedelyezese es Telepites
$AMD = Get-PnpDevice -FriendlyName "*AMD*" -ErrorAction SilentlyContinue
if ($AMD) {
    Enable-PnpDevice -InstanceId $AMD.InstanceId -Confirm:$false
    Write-Host "AMD Kartya engedelyezve. Most indulhat az AMD telepito."
}

# 4. Minden egyeb (Hang, Wifi, stb.) visszakapcsolasa
Write-Host "Maradek eszkozok visszakapcsolasa..."
Get-PnpDevice | Where-Object { $_.Status -eq "Disabled" } | Enable-PnpDevice -Confirm:$false

Write-Host "Keszen vagyunk! Erdemes egy utolso ujraiditast vegezni." -ForegroundColor Green
