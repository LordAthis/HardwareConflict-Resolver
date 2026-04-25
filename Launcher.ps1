$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

# Admin jog kerese
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Mappak kenyszeritese
if (!(Test-Path "LOG")) { New-Item -ItemType Directory -Path "LOG" -Force }

Write-Host "--- G500 GYORS JAVITAS ---" -ForegroundColor Cyan

# 1. Audit es Fix futtatasa sorban
& ".\Tests\Hardware-Audit.ps1"
& ".\Fix\LenovoG500-GraphicsConflict.ps1"

# 2. LOG megnyitasa (Hogy lassuk mi tortent)
$FixLog = ".\LOG\Fix_Activity.log"
if (Test-Path $FixLog) {
    notepad.exe $FixLog
} else {
    Write-Host "A LOG meg nem jott letre, futtatom az Install-t is..."
    & ".\Fix\Install-Drivers.ps1"
    if (Test-Path ".\LOG\Install.log") { notepad.exe ".\LOG\Install.log" }
}

Write-Host "KESZ. Ha csokkentett modban vagy, inditsd ujra a gepet!" -ForegroundColor Green
