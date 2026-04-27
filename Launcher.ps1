# Kornyezet beallitasa
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $PSScriptRoot

# Admin jog kerese
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- KONFIGURACIO ES ALLAPOTKOVETES ---
$RegPath = "HKLM:\SOFTWARE\HardwareConflictResolver"
if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force }

function Get-StepState { param($StepName) return (Get-ItemProperty -Path $RegPath -Name $StepName -ErrorAction SilentlyContinue).$StepName }
function Set-StepState { param($StepName, $Value) New-ItemProperty -Path $RegPath -Name $StepName -Value $Value -PropertyType String -Force }

$LogPath = "C:\Temp\HardwareConflict_LOG.txt"
function Write-Log { param($Msg) $t = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; "[$t] $Msg" | Tee-Object -FilePath $LogPath -Append }

# JSON Adatok betoltese
$Config = Get-Content "$PSScriptRoot\data\GodDriverConf.json" | ConvertFrom-Json
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$TargetDrivers = $Config.Drivers | Where-Object { $_.Arch -eq $OSArch }

# --- 0. LEPES: Kotezo Visszaallitasi Pont ---
if ((Get-StepState "InitialBackup") -ne "Done") {
    & "$PSScriptRoot\Scripts\Enable-RestorePoint.ps1"
    Set-StepState "InitialBackup" "Done"
}

# --- 1. DRIVER LETOLTES (Dinamikus) ---
foreach ($Driver in $TargetDrivers) {
    $DriverPath = "$PSScriptRoot\Drivers\$OSArch\$($Driver.FileName)"
    if (!(Test-Path $DriverPath)) {
        New-Item -ItemType Directory -Path (Split-Path $DriverPath) -Force | Out-Null
        Write-Log "Letoltes: $($Driver.FileName)..."
        Invoke-WebRequest -Uri $Driver.Url -OutFile $DriverPath
        Unblock-File $DriverPath
    }
}

# --- 2. MOD SZERINTI FUTTATAS ---
$isSafe = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"

if ($isSafe) {
    Write-Log "Csokkentett mod: Fix futtatasa..."
    & "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"
    
    # Ellenorzes a JSON adatok alapjan (Intel-re fokuszalva a G500-nal)
    $IntelSpec = $TargetDrivers | Where-Object { $_.Name -like "*Intel*" }
    $IsOk = & "$PSScriptRoot\Scripts\Check-DriverStatus.ps1" -TargetVersion $IntelSpec.TargetVersion -HardwareID $IntelSpec.HWID
    
    if ($IsOk) { 
        Set-StepState "SafeModeFix" "Done" 
        Write-Log "Sikeres ellenorzes. Indulhat a normal mod."
    }
} else {
    if ((Get-StepState "SafeModeFix") -eq "Done" -and (Get-StepState "FinalInstall") -ne "Done") {
        Write-Log "Normal mod: Telepites inditasa..."
        & "$PSScriptRoot\Fix\LenovoG500Install-Drivers.ps1"
    } elseif ((Get-StepState "FinalInstall") -eq "Done") {
        Write-Host "A rendszer mar javitva van!" -ForegroundColor Green
    } else {
        Write-Log "Inditas Csokkentett modba..."
        & "$PSScriptRoot\Scripts\Set-SafeBoot-Networking.ps1"
    }
}
