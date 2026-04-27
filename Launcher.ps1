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

# --- 0. LEPES: Kotezo Visszaallitasi Pont es Riport ---
if ((Get-StepState "InitialBackup") -ne "Done") {
    & "$PSScriptRoot\Scripts\Enable-RestorePoint.ps1"
    Write-Log "Hardver riport mentese..."
    Get-PnpDevice | Select-Object FriendlyName, InstanceId, Status | Export-Csv -Path "C:\Temp\Hardware_Report.csv" -NoTypeInformation
    Set-StepState "InitialBackup" "Done"
}

# --- 1. ESZKOZOK FELSZABADITASA ---
Write-Log "Input/Halozati eszkozok kenyszeritett engedelyezese..."
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Network*" -or $_.FriendlyName -like "*Wireless*" -or $_.FriendlyName -like "*Mouse*" } | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

# --- 2. DRIVER LETOLTES (JSON ALAPJAN) ---
$Config = Get-Content "$PSScriptRoot\data\GodDriverConf.json" | ConvertFrom-Json
$OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

foreach ($Driver in $Config.Drivers | Where-Object { $_.Arch -eq $OSArch }) {
    $DriverPath = "$PSScriptRoot\Drivers\$OSArch\$($Driver.FileName)"
    if (!(Test-Path $DriverPath)) {
        New-Item -ItemType Directory -Path (Split-Path $DriverPath) -Force | Out-Null
        Write-Log "Letoltes: $($Driver.FileName)..."
        try {
            Invoke-WebRequest -Uri $Driver.Url -OutFile $DriverPath -TimeoutSec 300
            Unblock-File $DriverPath
        } catch {
            Write-Log "HIBA: Letoltes megszakadt: $($Driver.FileName)"
        }
    }
}

# --- 3. MOD SZERINTI FUTTATAS ---
$isSafe = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"

if ($isSafe) {
    Write-Log "Csokkentett mod: Fix inditasa..."
    & "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"
    
    # Mely ellenorzes a Fix utan
    $Check = & "$PSScriptRoot\Scripts\Check-DriverStatus.ps1" `
        -TargetVersion "9.17.10.2932" `
        -HardwareID "Intel(R) HD Graphics 4000" `
        -DriverFileName "igdkmd64.sys"

    if ($Check) { 
        Set-StepState "SafeModeFix" "Done" 
        Write-Log "SafeModeFix sikeresen ellenorizve."
    } else {
        Write-Log "HIBA: A Fix lefutott, de a driver verzio nem megfelelo!"
    }
} else {
    # Normal mod: Telepites ha a SafeModeFix mar kesz
    if ((Get-StepState "SafeModeFix") -eq "Done" -and (Get-StepState "FinalInstall") -ne "Done") {
        Write-Log "Normal mod: Driverek telepitese..."
        & "$PSScriptRoot\Fix\LenovoG500Install-Drivers.ps1"
        
        # Telepites utani visszaellenorzes
        $FinalCheck = & "$PSScriptRoot\Scripts\Check-DriverStatus.ps1" -TargetVersion "9.17.10.2932" -HardwareID "Intel(R) HD Graphics 4000"
        if ($FinalCheck) {
            Set-StepState "FinalInstall" "Done"
            Write-Log "Minden driver a helyen, rendszer stabil."
        }
    } elseif ((Get-StepState "FinalInstall") -eq "Done") {
        Write-Host "A javitas mar korabban sikeresen befejezodott!" -ForegroundColor Green
    } else {
        Write-Log "Inditas Csokkentett modba..."
        & "$PSScriptRoot\Scripts\Set-SafeBoot-Networking.ps1"
    }
}
