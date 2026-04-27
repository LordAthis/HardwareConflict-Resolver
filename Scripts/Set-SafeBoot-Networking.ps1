if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
bcdedit /set {current} safeboot network
Write-Host "[OK] Kovetkezo inditas: Csokkentett mod (Halozattal)." -ForegroundColor Green
$choice = Read-Host "Ujrainditod most? (I/N)"
if ($choice -eq "I" -or $choice -eq "i") { shutdown /r /t 5 }
