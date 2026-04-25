# Első feladat: A hibás (felkiáltójeles) hardverek azonnali tiltása a fagyás elkerülésére
$ErrorDevices = Get-PnpDevice | Where-Object { $_.Status -eq "Error" -or $_.Problem -ne "NoError" }

foreach ($dev in $ErrorDevices) {
    $logMsg = "CRITICAL: Hibás eszköz észleelve, tiltás azonnal: $($dev.FriendlyName)"
    $logMsg | Out-File -FilePath "..\LOG\Fix_Activity.log" -Append
    Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
}

# Ezután jöhet a specifikus G500 logika (AMD, Audio, stb. tiltása)
$SpecificTargets = @("*AMD*", "*Radeon*", "*Conexant*", "*Intel(R) Display Audio*")
foreach ($target in $SpecificTargets) {
    $dev = Get-PnpDevice -FriendlyName $target -ErrorAction SilentlyContinue
    if ($dev) {
        "FIX: Specifikus eszköz tiltása: $($dev.FriendlyName)" | Out-File -FilePath "..\LOG\Fix_Activity.log" -Append
        Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    }
}
