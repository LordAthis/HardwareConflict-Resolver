if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Safeboot torlese
bcdedit /deletevalue {current} safeboot 2>$null

# Takaritas: Ha maradt volna ResetSafeBoot feladat, toroljuk
Unregister-ScheduledTask -TaskName "ResetSafeBoot" -Confirm:$false -ErrorAction SilentlyContinue

Write-Host "A gep legkozelebb NORMAL modban indul." -ForegroundColor Green
