# 1. Admin jog es munkakonyvtar beallitasa
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

$DriverDir = Join-Path $PSScriptRoot "Drivers"
$LogDir = Join-Path $PSScriptRoot "LOG"
$FixLog = Join-Path $LogDir "Fix_Activity.log"

# Mappak kenyszeritese
foreach ($dir in @($DriverDir, $LogDir)) { if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force } }

Write-Host "--- G500 SZERVIZ AUTOMATA ---" -ForegroundColor Cyan

# 2. Driverek letoltese es FELOLDASA (Unblock)
$Drivers = @{
    "Intel_HD4000.exe" = "https://intel.com"
    "AMD_Radeon.exe"   = "https://lenovo.com"
}

foreach ($file in $Drivers.Keys) {
    $path = Join-Path $DriverDir $file
    if (Test-Path $path) {
        Write-Host "[OK] $file mar ott van a mappaban. Feloldas..." -ForegroundColor Green
        Unblock-File -Path $path  # EZ OLDJA FEL A TILTOTT ALLAPOTOT
    } else {
        Write-Host "[!] $file hianyzik. Letoltes..." -ForegroundColor Yellow
        try { 
            Invoke-WebRequest -Uri $Drivers[$file] -OutFile $path -ErrorAction Stop 
            Unblock-File -Path $path
        } catch { 
            Write-Host "HIBA: A letoltes nem sikerult (Webhely elutasitva?). Masold be manualisan a Drivers mappaba!" -ForegroundColor Red
        }
    }
}

# 3. Donteshozatal a LOG alapjan
if (Test-Path $FixLog) {
    $LogContent = Get-Content $FixLog
    if ($LogContent -contains "--- JAVITAS KESZ ---") {
        Write-Host "[+] Javitva volt, inditom a telepito modult..." -ForegroundColor Green
        & ".\Fix\LenovoG500Install-Drivers.ps1"
    } else {
        & ".\Fix\LenovoG500-GraphicsConflict.ps1"
    }
} else {
    & ".\Fix\LenovoG500-GraphicsConflict.ps1"
}

# 4. Log megnyitasa
if (Test-Path $FixLog) { notepad.exe $FixLog }
