# Munkakonyvtar beallitasa a script helyere
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

# Mappak letrehozasa ha hianyoznak
$Folders = @("LOG", "Fix", "Tests")
foreach ($f in $Folders) { if (!(Test-Path $f)) { New-Item -ItemType Directory -Name $f } }

# Log inditasa
$SessionLog = Join-Path $PSScriptRoot "LOG\Session_Full.log"
Start-Transcript -Path $SessionLog -Append

Write-Host "--- HardwareConflict-Resolver Inditasa ---" -ForegroundColor Cyan
Write-Host "Munkakonyvtar: $PSScriptRoot"

# 1. Teszt futtatasa
Write-Host "Tesztek futtatasa (Hardware Audit)..."
& "$PSScriptRoot\Tests\Hardware-Audit.ps1"

# 2. Fix futtatasa
Write-Host "Javitas inditasa (Fix)..." -ForegroundColor Yellow
& "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"

Write-Host "Folyamat kesz. Ellenorizd a LOG mappat!" -ForegroundColor Green
Stop-Transcript
