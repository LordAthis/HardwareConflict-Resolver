$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogFile = "C:\Temp\HardwareConflict_Fix_Activity.log"

function Write-Log($msg) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    "[$timestamp] $msg" | Out-File $LogFile -Append
    Write-Host $msg -ForegroundColor Cyan
}

Write-Log "--- JAVITAS INDITVA ---"

$WhiteList = @("*Keyboard*", "*Mouse*", "*HID*", "*Network*", "*Wireless*", "*Wi-Fi*", "*Ethernet*", "*Touchpad*")
$Targets = @("*AMD*", "*Radeon*", "*Conexant*", "*Intel(R) Display Audio*")

foreach ($t in $Targets) {
    Get-PnpDevice -FriendlyName $t -ErrorAction SilentlyContinue | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
    Write-Log "Tiltva: $t"
}

Get-PnpDevice | Where-Object { $_.Problem -ne "NoError" -or $_.Status -eq "Error" } | ForEach-Object {
    $name = $_.FriendlyName
    $safe = $false
    foreach ($w in $WhiteList) { if ($name -like $w) { $safe = $true } }
    if (!$safe) {
        Disable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Write-Log "Hiba miatti tiltas: $name"
    }
}

Write-Log "--- JAVITAS KESZ ---"
