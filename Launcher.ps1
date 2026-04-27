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

# --- 0. LÉPÉS: AUTOMATIKUS RIPORT ÉS VISSZAÁLLÍTÁSI PONT ---
if ((Get-StepState "InitialBackup") -ne "Done") {
    Write-Log "Rendszerallapot mentese es riport keszitese..."
    # Riport
    Get-PnpDevice | Select-Object FriendlyName, InstanceId, Status | Export-Csv -Path "C:\Temp\Hardware_Report.csv" -NoTypeInformation
    
    # Visszaállítási pont (Ha engedélyezve van a rendszervédelmen)
    Checkpoint-Computer -Description "HardwareConflictResolver_BeforeFix" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
    
    Set-StepState "InitialBackup" "Done"
}

# --- 1. ESZKÖZÖK FELSZABADÍTÁSA ---
Write-Log "Input/Halozati eszkozok kenyszeritett engedelyezese..."
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Network*" -or $_.FriendlyName -like "*Wireless*" -or $_.FriendlyName -like "*Mouse*" } | Enable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

# --- 2. DRIVER KEZELÉS (JSON ALAPJÁN) ---
$ConfigPath = "$PSScriptRoot\Adat\GodDriverConf.json"
if (Test-Path $ConfigPath) {
    $OSArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    $Config = Get-Content $ConfigPath | ConvertFrom-Json
    $DriverDir = New-Item -ItemType Directory -Path "$PSScriptRoot\Drivers" -Force

    foreach ($Driver in $Config.Drivers | Where-Object { $_.Arch -eq $OSArch }) {
        $Dest = Join-Path $DriverDir $Driver.FileName
        if (!(Test-Path $Dest)) {
            Write-Log "Letoltes: $($Driver.FileName)"
            try {
                Invoke-WebRequest -Uri $Driver.Url -OutFile $Dest -TimeoutSec 300
                Unblock-File $Dest
            } catch {
                Write-Log "HIBA: Nem sikerult letolteni a $($Driver.FileName) fajlt!"
            }
        }
    }
}

# --- 3. MÓD SZERINTI FUTTATÁS ÉS ELLENŐRZÉS ---
$isSafe = [bool](Get-WmiObject Win32_ComputerSystem).BootupState -match "Fail-safe"

if ($isSafe) {
    Write-Log "Csokkentett mod eszlelve. Fix futtatasa..."
    & "$PSScriptRoot\Fix\LenovoG500-GraphicsConflict.ps1"
    
    # Visszaellenőrzés (Példa: Registry vagy eszköz állapot)
    # Itt ellenőrizheted, hogy a cél-driver állapota megváltozott-e
    Set-StepState "SafeModeFix" "Done"
    Write-Host "Kesz! Inditsd ujra normal modban!" -ForegroundColor Green
} else {
    if ((Get-StepState "SafeModeFix") -eq "Done") {
        Write-Log "Visszateres normal modba, driverek telepitese..."
        & "$PSScriptRoot\Fix\LenovoG500Install-Drivers.ps1"
        Set-StepState "FinalInstall" "Done"
    } else {
        Write-Log "Inditas csokkentett modba..."
        & "$PSScriptRoot\Scripts\Set-SafeBoot-Networking.ps1"
        Restart-Computer
    }
}
