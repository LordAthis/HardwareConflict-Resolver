# Admin jog ellenorzese es kerese
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

$SessionLog = Join-Path $PSScriptRoot "LOG\Session_Full.log"
Start-Transcript -Path $SessionLog -Append

Write-Host "--- HardwareConflict-Resolver ---" -ForegroundColor Cyan
& "$PSScriptRoot\Tests\Hardware-Audit.ps1"
& "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"

Stop-Transcript

Write-Host "`nSIKER: A folyamat vegigfutott." -ForegroundColor Green
Write-Host "Most mar ujraindithatod a gepet NORMAL modban." -ForegroundColor Cyan
Write-Host "A LOG fajl automatikusan megnyilik..."

# Log megnyitasa a vegen
notepad.exe (Join-Path $PSScriptRoot "LOG\Fix_Activity.log")

# Varjon egy gombnyomasra mielott bezarul
Write-Host "Nyomj meg egy gombot a kilepeshez..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
