$LogFile = ".\LOG\Fix_Activity.log"
"--- JAVITAS INDITVA: $(Get-Date) ---" | Out-File $LogFile -Append

# 1. Kritikus eszkozok tiltasa (AMD es Audio)
$Targets = @("*AMD*", "*Radeon*", "*Conexant*", "*Intel(R) Display Audio*")

foreach ($t in $Targets) {
    $devices = Get-PnpDevice -FriendlyName $t -ErrorAction SilentlyContinue
    foreach ($dev in $devices) {
        $msg = "TILTS: $($dev.FriendlyName) [$($dev.InstanceId)]"
        Write-Host $msg -ForegroundColor Yellow
        $msg | Out-File $LogFile -Append
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
