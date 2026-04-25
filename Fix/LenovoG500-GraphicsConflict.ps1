$LogFile = ".\LOG\Fix_Activity.log"
"--- JAVITAS INDITVA: $(Get-Date) ---" | Out-File $LogFile -Append

# 1. Kritikus eszkozok tiltasa (AMD es Audio)
# Minden eszkoz, aminek problemaja van (Problem -ne 0)
$AllBadDevices = Get-PnpDevice | Where-Object { $_.Problem -ne "NoError" -or $_.Status -eq "Error" }

foreach ($dev in $AllBadDevices) {
    # Kivétel a beviteli eszközöknek, hogy ne vágjuk el a billentyűzetet
    if ($dev.FriendlyName -notlike "*Keyboard*" -and $dev.FriendlyName -notlike "*Mouse*") {
        Write-Log "TILTS (Hibas eszkoz): $($dev.FriendlyName)"
        Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    }
}

# 2. Felkialtojelek takaritasa
$Errors = Get-PnpDevice | Where-Object { $_.Status -ne "OK" -and $_.FriendlyName -notlike "*Keyboard*" }
foreach ($err in $Errors) {
    $msg = "HIBA TILTASA: $($err.FriendlyName)"
    Write-Host $msg -ForegroundColor Red
    $msg | Out-File $LogFile -Append
    Disable-PnpDevice -InstanceId $err.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
}

"--- JAVITAS KESZ ---" | Out-File $LogFile -Append

