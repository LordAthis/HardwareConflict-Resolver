$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogFile = ".\LOG\Install.log"
$DriverDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Drivers"

function Write-AutoLog($msg) {
    $txt = "$(Get-Date -Format 'HH:mm:ss') - $msg"
    Write-Host $txt -ForegroundColor Cyan
    $txt | Out-File $LogFile -Append
}

Write-AutoLog "--- AUTOMATA TELEPITES INDITVA ---"

# 1. Intel HD 4000 Telepitese (Csendes modban)
$IntelExe = Join-Path $DriverDir "Intel_HD4000.exe"
if (Test-Path $IntelExe) {
    Write-AutoLog "Intel Driver telepitese folyamatban..."
    Start-Process -FilePath $IntelExe -ArgumentList "-s", "-norestart" -Wait
    Write-AutoLog "Intel Driver KESZ."
}

# 2. Intel VGA aktivalasa
Get-PnpDevice -FriendlyName "*Intel(R) HD Graphics 4000*" | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

# 3. AMD Radeon Telepitese (Csendes modban)
# A Lenovo AMD drivere altalaban a -s vagy /s kapcsoloval fut csendben
$AMDExe = Join-Path $DriverDir "AMD_Radeon.exe"
if (Test-Path $AMDExe) {
    Write-AutoLog "AMD Driver telepitese folyamatban..."
    Start-Process -FilePath $AMDExe -ArgumentList "/s", "/v/qn" -Wait
    Write-AutoLog "AMD Driver KESZ."
}

# 4. AMD aktivalasa
Get-PnpDevice -FriendlyName "*AMD*", "*Radeon*" | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

# 5. MINDEN maradek letiltott eszkoz visszakapcsolasa (Hang, Wifi, stb.)
Write-AutoLog "Osszes maradek hardver visszakapcsolasa..."
Get-PnpDevice | Where-Object { $_.Status -eq "Disabled" } | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

Write-AutoLog "--- AUTOMATA FOLYAMAT VEGE ---"
