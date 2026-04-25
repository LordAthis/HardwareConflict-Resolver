$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FixLog = Join-Path $PSScriptRoot "..\LOG\Fix_Activity.log"

# 1. Hibas eszkozok azonnali tiltasa
$ErrorDevices = Get-PnpDevice | Where-Object { $_.Status -eq "Error" -or $_.Problem -ne "NoError" }
foreach ($dev in $ErrorDevices) {
    $msg = "CRITICAL: Hibas eszkoz tiltasa: $($dev.FriendlyName)"
    $msg | Out-File -FilePath $FixLog -Append
    Write-Host "Tiltas: $($dev.FriendlyName)" -ForegroundColor Red
    Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
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
