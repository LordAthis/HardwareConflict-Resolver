# Admin jogok kerese
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "--- Csokkentett mod beallitasa halozattal ---" -ForegroundColor Cyan

# 1. Beallitjuk a legkozelebbi inditast Csokkentett modra (Halozattal)
# A 'network' parameter biztositja az internetet es az alap grafikus feluletet
bcdedit /set {current} safeboot network

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] A Windows legkozelebb Csokkentett modban (Halozattal) indul." -ForegroundColor Green
    Write-Host "Igy lesz interneted a driverek letoltesehez."
} else {
    Write-Warning "[!] Hiba tortent a bcdedit futtatasa kozben!"
}

# 2. Opcionális: Automatikus újraindítás felajánlása
$choice = Read-Host "Szeretned most ujrainditani a gepet? (I/N)"
if ($choice -eq "I" -or $choice -eq "i") {
    shutdown /r /t 5 /c "Ujrainditas Csokkentett modba 5 masodpercen belul..."
}

# --- MEGJEGYZES A VISSZAALLITASHOZ ---
# Ha vegeztel, a normal modba valo visszatereshez ezt kell futtatni:
# bcdedit /deletevalue {current} safeboot
