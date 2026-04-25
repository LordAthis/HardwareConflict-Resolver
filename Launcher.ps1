# Launcher.ps1 kiegészítése
$isSafeMode = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"
if ($isSafeMode) {
    Write-Host "[!] Csökkentett mód észlelve. A tiltások végrehajtása prioritást élvez." -ForegroundColor Magenta
}


# Mappaszerkezet ellenőrzése
$Folders = @("LOG", "Fix", "Tests")
foreach ($f in $Folders) { if (!(Test-Path $f)) { New-Item -ItemType Directory -Name $f } }

Start-Transcript -Path ".\LOG\Session_Full.log"

Write-Host "--- HardwareConflict-Resolver Indítása ---" -ForegroundColor Cyan

# 1. Tesztelés: Mi a helyzet most?
Write-Host "Tesztek futtatása..."
& ".\Tests\Hardware-Audit.ps1" 

# 2. Fix futtatása
Write-Host "Javítási folyamat indítása..." -ForegroundColor Yellow
& ".\Fix\LenovoG500-GraphicsConflict.ps1"

Write-Host "Folyamat kész. Ellenőrizd a LOG mappát!" -ForegroundColor Green
Stop-Transcript
