if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "--- Csokkentett mod beallitasa halozattal ---" -ForegroundColor Cyan

bcdedit /set {current} safeboot network

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] A Windows legkozelebb Csokkentett modban (Halozattal) indul." -ForegroundColor Green
    Write-Host "Igy lesz interneted a driverek letoltesehez."
} else {
    Write-Warning "[!] Hiba tortent a bcdedit futtatasa kozben!"
}

$choice = Read-Host "Szeretned most ujrainditani a gepet? (I/N)"
if ($choice -eq "I" -or $choice -eq "i") {
    shutdown /r /t 5 /c "Ujrainditas Csokkentett modba 5 masodpercen belul..."
}
