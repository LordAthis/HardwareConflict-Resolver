# Admin jog kerese
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "--- One-Shot Csokkentett mod beallitasa ---" -ForegroundColor Cyan

# 1. Beallitjuk a csokkentett modot halozattal
bcdedit /set {current} safeboot network

# 2. Beutemezunk egy parancsot, ami az INDITAS pillanataban torli ezt a flaget
# Igy a legkozelebbi restart mar normal mod lesz, nem ragadsz bent!
$Command = "bcdedit /deletevalue {current} safeboot"
$Trigger = New-JobTrigger -AtLogOn
Register-ScheduledTask -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command $Command") -Trigger $Trigger -TaskName "ResetSafeBoot" -User "NT AUTHORITY\SYSTEM" -RunLevel Highest -Force

Write-Host "[OK] A gep most ujraindul Csokkentett modba (halozattal)." -ForegroundColor Green
Write-Host "[!] A ranyitott 'ResetSafeBoot' feladat miatt a kovetkezo restart mar NORMAL lesz."

# 3. Azonnali ujrainditas
shutdown /r /t 2 /c "Irany a Csokkentett mod!"
