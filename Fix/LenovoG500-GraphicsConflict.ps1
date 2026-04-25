$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogFile = ".\LOG\Fix_Activity.log"

# A fuggveny neve legyen konzisztens
function Write-Log($msg) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    "$timestamp - $msg" | Out-File $LogFile -Append
    Write-Host $msg -ForegroundColor Cyan
}


Write-Log "--- JAVITAS INDITVA ---"

# 1. WHITELIST - Ezeket az eszkozoket SOHA nem tiltjuk le (Bevitel + Halozat)
$WhiteList = @("*Keyboard*", "*HID-compliant*", "*Mouse*", "*Touchpad*", "*Network*", "*Wireless*", "*Wi-Fi*", "*Ethernet*")

# 2. KRITIKUS VGA ES AUDIO TILTASA (Wildcard alapjan)
$Targets = @("*AMD*", "*Radeon*", "*Conexant*", "*Intel(R) Display Audio*")

foreach ($t in $Targets) {
    $devices = Get-PnpDevice -FriendlyName $t -ErrorAction SilentlyContinue
    foreach ($dev in $devices) {
        Write-Log "CELZOTT TILTAS: $($dev.FriendlyName)"
        Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    }
}

# 3. HIBAS ESZKOZOK TILTASA (Kiveve ami a Whitelist-en van)
$AllBadDevices = Get-PnpDevice | Where-Object { $_.Problem -ne "NoError" -or $_.Status -eq "Error" }

foreach ($dev in $AllBadDevices) {
    # Ellenorizzuk, hogy a hibas eszkoz rajta van-e a vedett listan
    $isProtected = $false
    foreach ($safe in $WhiteList) { 
        if ($dev.FriendlyName -like $safe) { $isProtected = $true } 
    }
    
    if (-not $isProtected) {
        Write-Log "HIBA TILTASA: $($dev.FriendlyName)"
        Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    } else {
        Write-Log "VEDETT ESZKOZ (Kihagyva): $($dev.FriendlyName)"
    }
}

Write-Log "--- JAVITAS KESZ ---"
