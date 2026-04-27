# Környezet beállítása
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

# Admin jog kérése
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- KONFIGURÁCIÓ ÉS ÁLLAPOTKÖVETÉS ---
$RegPath = "HKLM:\SOFTWARE\HardwareConflictResolver"
if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force }

function Get-StepState { param($StepName) return (Get-ItemProperty -Path $RegPath -Name $StepName -ErrorAction SilentlyContinue).$StepName }
function Set-StepState { param($StepName, $Value) New-ItemProperty -Path $RegPath -Name $StepName -Value $Value -PropertyType String -Force }

$LogPath = "C:\Temp\HardwareConflict_LOG.txt"
function Write-Log { param($Msg) $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; "[$t] $Msg" | Tee-Object -FilePath $LogPath -Append }

# --- 0. LEPES: Kotezo Visszaallitasi Pont ---
if ((Get-StepState "InitialBackup") -ne "Done") {
    & "$PSScriptRoot\Scripts\Enable-RestorePoint.ps1"
    
    # Riport mentese C:\Temp-be
    Write-Host "Hardver riport mentese..."
    Get-PnpDevice | Select-Object FriendlyName, InstanceId, Status | Export-Csv -Path "C:\Temp\Hardware_Report.csv" -NoTypeInformation
    
    Set-StepState "InitialBackup" "Done"
}

# --- 1. ESZKÖZÖK FELSZABADÍTÁSA ---
Write-Log "Input/Halozati eszkozok kenyszeritett engedelyezese..."
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Network*" -or $_.FriendlyName -like "*Wireless*" -or $_.FriendlyName -like "*Mouse*" } | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

# --- 2. DRIVER KEZELES ---
$Config = Get-Content "$PSScriptRoot\data\GodDriverConf.json" | ConvertFrom-Json
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

foreach ($Driver in $Config.Drivers | Where-Object { $_.Arch -eq $OSArch }) {
    $DriverPath = "$PSScriptRoot\Drivers\$OSArch\$($Driver.FileName)"
    if (!(Test-Path $DriverPath)) {
        New-Item -ItemType Directory -Path (Split-Path $DriverPath) -Force | Out-Null
        Write-Host "Letoltes: $($Driver.FileName)..."
        Invoke-WebRequest -Uri $Driver.Url -OutFile $DriverPath
        Unblock-File $DriverPath
    }
}

# --- 3. MOD SZERINTI FUTTATAS ---
if ($isSafe) {
    Write-Host "Fix futtatasa Csokkentett modban..." -ForegroundColor Cyan
    & "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"
    
    # Ellenorzes a kulso scripttel
    $IsOk = & "$PSScriptRoot\Scripts\Check-DriverStatus.ps1" -TargetVersion "9.17.10.2932" -HardwareID "Intel(R) HD Graphics 4000"
    if ($IsOk) { 
        Set-StepState "SafeModeFix" "Done" 
        Write-Host "Sikeres ellenorzes!" -ForegroundColor Green
    }
}
