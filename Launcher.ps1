# 1. Admin jogok es munkakonyvtar beallitasa
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

# 2. Log utvonalak definialasa
$LocalLogDir = Join-Path $PSScriptRoot "LOG"
$GlobalLogDir = "C:\Temp\HardwareConflict\LOG"
$LogFiles = @(
    (Join-Path $LocalLogDir "Fix_Activity.log"),
    (Join-Path $GlobalLogDir "Fix_Activity.log")
)

# Mappak letrehozasa
foreach ($dir in @($LocalLogDir, $GlobalLogDir)) { if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force } }

# 3. Allapotfelmeres
$isSafeMode = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"
$HasPreviousLog = $false
foreach ($log in $LogFiles) { if (Test-Path $log) { $HasPreviousLog = $true } }

Write-Host "--- HardwareConflict-Resolver Robust Launcher ---" -ForegroundColor Cyan

if ($isSafeMode) {
    Write-Host "[!] Csokkentett mod: Javitas inditasa..." -ForegroundColor Yellow
    & "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"
    # Masolas a globalis helyre mentovarnak
    Copy-Item (Join-Path $LocalLogDir "Fix_Activity.log") (Join-Path $GlobalLogDir "Fix_Activity.log") -Force
} else {
    Write-Host "[+] Normal mod: Ellenorzes..." -ForegroundColor Green
    
    # DONTESHOZATAL
    if ($HasPreviousLog) {
        Write-Host "[OK] Korabbi javitas nyomat megtalaltam a logokban."
        & "$PSScriptRoot\Fix\Install-Drivers.ps1"
    } else {
        Write-Host "[?] Nincs log. Uj elo-audit es elo-szures inditasa..." -ForegroundColor Magenta
        & "$PSScriptRoot\Tests\Hardware-Audit.ps1"
        
        # Ha talalunk letiltott eszkozt, akkor is inditjuk a javito-telepitot
        $DisabledCount = (Get-PnpDevice | Where-Object { $_.Status -eq "Disabled" }).Count
        if ($DisabledCount -gt 0) {
            Write-Host "[!] Letiltott hardvereket detektaltam ($DisabledCount db), log hianya ellenere folytatom..."
            & "$PSScriptRoot\Fix\Install-Drivers.ps1"
        } else {
            Write-Host "[DONE] A rendszer tiszta, nincs teendo." -ForegroundColor Green
        }
    }
}

# 4. Globalis log frissitese a vegén
if (Test-Path (Join-Path $LocalLogDir "Fix_Activity.log")) {
    Copy-Item (Join-Path $LocalLogDir "Fix_Activity.log") (Join-Path $GlobalLogDir "Fix_Activity.log") -Force
}

Write-Host "`nFolyamat kesz. Logok mentve: $GlobalLogDir"
notepad.exe (Join-Path $GlobalLogDir "Fix_Activity.log")
