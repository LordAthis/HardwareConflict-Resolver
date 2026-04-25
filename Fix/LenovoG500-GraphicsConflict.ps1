$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FixLog = Join-Path $PSScriptRoot "..\LOG\Fix_Activity.log"

# Kivetelek (Whitelist) - Ezeket SOHA ne tiltsuk le
$WhiteList = @("*Keyboard*", "*HID-compliant*", "*Mouse*", "*Touchpad*", "*Root*", "*PnP Bus*")

# 1. Hibas eszkozok tiltasa (Kiveve a Whitelist)
$ErrorDevices = Get-PnpDevice | Where-Object { ($_.Status -eq "Error" -or $_.Problem -ne "NoError") -and $_.Status -ne "Unknown" }

foreach ($dev in $ErrorDevices) {
    $isProtected = $false
    foreach ($safe in $WhiteList) { if ($dev.FriendlyName -like $safe) { $isProtected = $true } }
    
    if (-not $isProtected) {
        $msg = "CRITICAL: Hibas eszkoz tiltasa: $($dev.FriendlyName)"
        $msg | Out-File -FilePath $FixLog -Append
        Write-Host "Tiltas: $($dev.FriendlyName)" -ForegroundColor Red
        Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    }
}

# 2. Specifikus G500 celpontok
$Targets = @("*AMD*", "*Radeon*", "*Conexant*", "*Intel(R) Display Audio*")
foreach ($t in $Targets) {
    $dev = Get-PnpDevice -FriendlyName $t -ErrorAction SilentlyContinue | Where-Object Status -ne "Disabled"
    if ($dev) {
        "FIX: Celzott tiltas: $($dev.FriendlyName)" | Out-File -FilePath $FixLog -Append
        Write-Host "Tiltas (Celzott): $($dev.FriendlyName)" -ForegroundColor Yellow
        Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    }
}
