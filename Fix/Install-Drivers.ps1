$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogDir = Join-Path (Split-Path $PSScriptRoot -Parent) "LOG"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir }

Write-Host "--- Hardver-alapu telepites es aktivalas ---" -ForegroundColor Cyan

# 1. Lekerdezzuk a jelenleg letiltott eszkozoket
$DisabledDevices = Get-PnpDevice | Where-Object { $_.Status -eq "Disabled" -or $_.ConfigManagerErrorCode -eq 22 }

if ($DisabledDevices.Count -eq 0) {
    Write-Host "Nincs letiltott eszkoz. A rendszer elvileg kesz." -ForegroundColor Green
    return
}

# 2. Intel VGA kezelese (Elsobbseg)
$Intel = $DisabledDevices | Where-Object { $_.FriendlyName -like "*Intel(R) HD Graphics 4000*" }
if ($Intel) {
    Write-Host "Intel VGA detektalva. Aktivalas..."
    Enable-PnpDevice -InstanceId $Intel.InstanceId -Confirm:$false
    # Ide johet az Intel driver exe futtatasa, ha van a Drivers mappaban
}

# 3. Maradek eszkozok visszakapcsolasa (Kiveve AMD, ha meg nincs driver)
Write-Host "Egyeb eszkozok (Billentyuzet, Hang, stb.) visszakapcsolasa..."
foreach ($dev in $DisabledDevices) {
    if ($dev.FriendlyName -notlike "*AMD*" -and $dev.FriendlyName -notlike "*Radeon*") {
        Write-Host "Aktivalas: $($dev.FriendlyName)"
        Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
    }
}

# 4. AMD utolso lepese
$AMD = $DisabledDevices | Where-Object { $_.FriendlyName -like "*AMD*" -or $_.FriendlyName -like "*Radeon*" }
if ($AMD) {
    Write-Host "AMD kartya detektalva. Aktivalas es driver inditasa..."
    Enable-PnpDevice -InstanceId $AMD.InstanceId -Confirm:$false
    # Ide johet az AMD installer inditasa
}

Write-Host "A hardver-alapu helyreallitas befejezodott." -ForegroundColor Green
