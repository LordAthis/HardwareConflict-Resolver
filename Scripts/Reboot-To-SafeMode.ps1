if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "--- Csokkentett mod beallitasa (One-Shot) ---" -ForegroundColor Cyan

bcdedit /set {current} safeboot network

if ($LASTEXITCODE -eq 0) {
    # Reset feladat letrehozasa
    $Command = "bcdedit /deletevalue {current} safeboot"
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command $Command"
    $Trigger = New-JobTrigger -AtLogOn
    Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "ResetSafeBoot" -User "NT AUTHORITY\SYSTEM" -RunLevel Highest -Force

    Write-Host "[OK] A kovetkezo inditas Csokkentett mod lesz." -ForegroundColor Green
    
    $choice = Read-Host "Ujrainditod a gepet most? (I/N)"
    if ($choice -eq "I") { shutdown /r /t 5 }
}
