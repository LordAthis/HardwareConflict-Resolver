$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BaseDir = Split-Path $PSScriptRoot -Parent
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$DriverDir = Join-Path $BaseDir "Drivers\$OSArch"

# 1. Telepitesek (Intel + AMD)
Write-Host "Intel es AMD driverek kenyszeritett telepitese..." -ForegroundColor Cyan
# ... (itt a korabbi pnputil es exe indito resz) ...

# 2. Windows Update tiltas
& "$PSScriptRoot\LenovoG500Block-VGA-Updates.ps1"

# 3. VISSZAELLENORZES (JSON-bol olvasva)
$Config = Get-Content "$BaseDir\data\GodDriverConf.json" | ConvertFrom-Json
$IntelSpec = $Config.Drivers | Where-Object { $_.Arch -eq $OSArch -and $_.Name -like "*Intel*" }

$FinalCheck = & "$BaseDir\Scripts\Check-DriverStatus.ps1" -TargetVersion $IntelSpec.TargetVersion -HardwareID $IntelSpec.HWID

if ($FinalCheck) {
    Write-Host "MINDEN KESZ! Rendszer stabil." -ForegroundColor Green
    Set-ItemProperty -Path "HKLM:\SOFTWARE\HardwareConflictResolver" -Name "FinalInstall" -Value "Done"
    
    # Automatikus visszateres Normal modba
    Write-Host "Normal mod visszaallitasa..." -ForegroundColor Yellow
    & "$BaseDir\Scripts\Set-NormalBoot.ps1"
} else {
    Write-Warning "Valami nem stimmel a telepites utan!"
}
